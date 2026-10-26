#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <signal.h>
#import <setjmp.h>
#import <libkern/OSCacheControl.h>
#import "SporkUI.h"

// --- Offsets for Roblox 2.744.0.1077 (Relative to RobloxLib) ---
#define OFFSET_TASKSCHEDULER      0x6a6d7c0
#define OFFSET_TS_JOBS_START      0xd0
#define OFFSET_TS_JOBS_END        0xd8
#define OFFSET_JOB_SCRIPT_CTX     0x1b0
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUAU_LOAD          0x44bc110

// --- Pass-Through Window ---
@interface PassThroughWindow : UIWindow
@property (nonatomic, weak) UIView *interactableView1;
@property (nonatomic, weak) UIView *interactableView2;
@end

@implementation PassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (self.interactableView1 && !self.interactableView1.hidden) {
        CGPoint point1 = [self.interactableView1 convertPoint:point fromView:self];
        if ([self.interactableView1 pointInside:point1 withEvent:event]) return hitView;
    }
    if (self.interactableView2 && !self.interactableView2.hidden) {
        CGPoint point2 = [self.interactableView2 convertPoint:point fromView:self];
        if ([self.interactableView2 pointInside:point2 withEvent:event]) return hitView;
    }
    return nil; 
}
@end

static PassThroughWindow *overlayWindow = nil;

// --- Executor Logic ---
typedef int (*lua_pcall_t)(void* L, int nargs, int nresults, int errfunc);
typedef int (*luau_load_t)(void* L, const char* chunkname, const char* data, size_t size, int env);

static void* g_L = NULL;
bool g_is_injected = false;
static NSMutableArray<NSString *> *g_scriptQueue = nil;

// Hook Trampoline
static void* orig_lua_pcall = NULL;
static uint8_t original_bytes[16];

// --- Crash-Proof Signal Handler ---
static sigjmp_buf jump_buffer;
static volatile sig_atomic_t in_lua_exec = 0;

void signal_handler(int sig) {
    if (in_lua_exec) {
        siglongjmp(jump_buffer, sig);
    }
}

// --- Logging System ---
NSMutableArray<NSString *> *g_logs = nil;

void SporkLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (!g_logs) g_logs = [NSMutableArray array];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@", timeStr, msg];
    [g_logs addObject:logLine];
    NSLog(@"[Spork] %@", msg);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SporkLogUpdated" object:nil];
    });
}

#define STRIP_PAC(ptr) ((uintptr_t)(ptr) & 0x0000000FFFFFFFFF)

bool safe_read(void* address, void* buffer, size_t size) {
    uintptr_t addr = STRIP_PAC(address);
    if (addr < 0x100000000 || addr > 0x7FFFFFFFFFFF) return false;
    
    vm_size_t out_size;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr, (vm_size_t)size, (vm_address_t)buffer, &out_size);
    return (kr == KERN_SUCCESS && out_size == size);
}

uintptr_t get_robloxlib_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "RobloxLib")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// --- The Raw Inline Hook ---
void install_hook(void* target, void* hook) {
    // Create a trampoline to run the original instructions
    void* trampoline = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    memcpy(trampoline, target, 16);
    
    // Add jump back to target+16
    uint32_t* tramp_code = (uint32_t*)((uintptr_t)trampoline + 16);
    tramp_code[0] = 0x58000050; // ldr x16, #8
    tramp_code[1] = 0xD61F0200; // br x16
    *(uint64_t*)((uintptr_t)trampoline + 24) = (uintptr_t)target + 16;
    orig_lua_pcall = trampoline;
    
    // Write the jump to our hook at the start of the target function
    uintptr_t page = (uintptr_t)target & ~0xFFF;
    mach_vm_protect(mach_task_self(), page, 0x1000, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    
    uint32_t* target_code = (uint32_t*)target;
    target_code[0] = 0x58000050; // ldr x16, #8
    target_code[1] = 0xD61F0200; // br x16
    *(uint64_t*)((uintptr_t)target + 8) = (uintptr_t)hook;
    
    sys_icache_invalidate(target, 16);
    mach_vm_protect(mach_task_self(), page, 0x1000, false, VM_PROT_READ | VM_PROT_EXECUTE);
}

// --- Hook Function ---
int my_lua_pcall(void* L, int nargs, int nresults, int errfunc) {
    if (g_scriptQueue && g_scriptQueue.count > 0) {
        NSString *script = g_scriptQueue.firstObject;
        [g_scriptQueue removeObjectAtIndex:0];
        
        uintptr_t base = get_robloxlib_base();
        luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
        
        SporkLog(@"Hook triggered! Executing script...");
        const char *source = [script UTF8String];
        
        int status = luau_load(L, "SporkScript", source, strlen(source), 0);
        if (status == 0) {
            orig_lua_pcall(L, 0, 0, 0);
            SporkLog(@"Success: Script executed!");
        } else {
            SporkLog(@"Error: Compile/Load Failed with status %d", status);
        }
    }
    
    // Continue original execution
    return orig_lua_pcall(L, nargs, nresults, errfunc);
}

// Strict validation to prevent false positives
void* FindLuaState(void* base_ptr) {
    if (!base_ptr) return NULL;
    uintptr_t base = STRIP_PAC(base_ptr);
    
    for (int i = 0; i < 0x200000; i += 8) {
        void* ptr = NULL;
        if (!safe_read((void*)(base + i), &ptr, 8)) continue;
        
        uintptr_t stripped_ptr = STRIP_PAC(ptr);
        if (stripped_ptr > 0x100000000 && stripped_ptr < 0x7FFFFFFFFFFF) {
            uint8_t tt = 0;
            if (!safe_read((void*)(stripped_ptr + 0x2), &tt, 1) || tt != 9) continue;
            
            void* global_ptr = NULL;
            if (!safe_read((void*)(stripped_ptr + 0x78), &global_ptr, 8)) continue;
            
            uintptr_t stripped_global = STRIP_PAC(global_ptr);
            if (stripped_global < 0x100000000 || stripped_global > 0x7FFFFFFFFFFF) continue;
            
            void* mainthread = NULL;
            if (!safe_read((void*)(stripped_global + 0x1a0), &mainthread, 8)) continue;
            
            if (STRIP_PAC(mainthread) == stripped_ptr) {
                void* base_ci = NULL;
                if (!safe_read((void*)(stripped_ptr + 0x18), &base_ci, 8)) continue;
                if (STRIP_PAC(base_ci) < 0x100000000) continue;
                
                return mainthread;
            }
        }
    }
    return NULL;
}

bool InjectExecutor(void) {
    if (g_logs) [g_logs removeAllObjects];
    SporkLog(@"Starting Injection...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) {
        SporkLog(@"Error: Failed to find RobloxLib base.");
        return false;
    }
    
    void* task_scheduler = NULL;
    if (!safe_read((void*)(base + OFFSET_TASKSCHEDULER), &task_scheduler, 8) || !task_scheduler) {
        SporkLog(@"Error: Failed to find TaskScheduler.");
        return false;
    }
    task_scheduler = (void*)STRIP_PAC(task_scheduler);
    
    uintptr_t start = 0, end = 0;
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_START, &start, 8);
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_END, &end, 8);
    start = STRIP_PAC(start);
    end = STRIP_PAC(end);

    int jobCount = 0;
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        
        uintptr_t stripped_j = STRIP_PAC(j);
        jobCount++;
        
        void* script_context = NULL;
        if (safe_read((char*)stripped_j + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            script_context = (void*)STRIP_PAC(script_context);
            
            g_L = FindLuaState(script_context);
            if (g_L) {
                SporkLog(@"Success: Found mainthread in ScriptContext: %p", g_L);
                break;
            }
            
            g_L = FindLuaState((void*)stripped_j);
            if (g_L) {
                SporkLog(@"Success: Found mainthread in Job: %p", g_L);
                break;
            }
        }
    }
    
    if (!g_L) {
        SporkLog(@"Error: Could not find a valid lua_State.");
        return false;
    }

    // Install the inline hook for lua_pcall
    void* target_pcall = (void*)(base + OFFSET_LUA_PCALL);
    install_hook(target_pcall, (void*)my_lua_pcall);
    
    SporkLog(@"Success: Hooked lua_pcall!");
    g_is_injected = true;
    return true;
}

void ExecuteLuauSource(const char* source, size_t size) {
    if (!g_is_injected) return;
    if (!g_scriptQueue) g_scriptQueue = [NSMutableArray new];
    
    NSString *script = [NSString stringWithUTF8String:source];
    [g_scriptQueue addObject:script];
    SporkLog(@"Script queued for execution.");
}

__attribute__((constructor))
static void init() {
    signal(SIGSEGV, signal_handler);
    signal(SIGBUS, signal_handler);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (overlayWindow) return; 

        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        if (activeScene) {
            overlayWindow = [[PassThroughWindow alloc] initWithWindowScene:activeScene];
        } else {
            overlayWindow = [[PassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        overlayWindow.frame = [UIScreen mainScreen].bounds;
        overlayWindow.windowLevel = UIWindowLevelAlert + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        
        SporkViewController *vc = [[SporkViewController alloc] init];
        overlayWindow.rootViewController = vc;
        overlayWindow.hidden = NO;
        [overlayWindow makeKeyAndVisible];
        
        overlayWindow.interactableView1 = vc.mainContainer;
        overlayWindow.interactableView2 = vc.floatingButton;
        
        g_scriptQueue = [NSMutableArray new];
    });
}
