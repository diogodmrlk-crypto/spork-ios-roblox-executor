#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <stdlib.h>
#import <signal.h>
#import <setjmp.h>
#import "SporkUI.h"

// --- Offsets for Roblox 2.744.0.1077 (Relative to RobloxLib) ---
#define OFFSET_TASKSCHEDULER      0x6a6d7c0
#define OFFSET_TS_JOBS_START      0xd0
#define OFFSET_TS_JOBS_END        0xd8
#define OFFSET_JOB_SCRIPT_CTX     0x1b0
#define OFFSET_LUAU_LOAD          0x44bc110
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUA_NEWTHREAD      0x448df3c
#define OFFSET_LUAL_SANDBOXTHREAD 0x1a12ad4

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
typedef void* (*lua_newthread_t)(void* L);
typedef void (*luaL_sandboxthread_t)(void* L);

bool g_is_injected = false;
static NSMutableArray<NSString *> *g_scriptQueue = nil;

static void* orig_job_step = NULL;

// --- Local Crash Handler for the Hook ---
static sigjmp_buf hook_jump_buffer;
static volatile sig_atomic_t in_hook_exec = 0;

void hook_signal_handler(int sig) {
    if (in_hook_exec) {
        siglongjmp(hook_jump_buffer, sig);
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
    if (addr < 0x100000000 || addr > 0x400000000) return false;
    
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

// Reverted scanner with base_ci check to filter out strings like 0x174736e49
void* FindLuaState(void* base_ptr) {
    if (!base_ptr) return NULL;
    uintptr_t base = STRIP_PAC(base_ptr);
    
    for (int i = 0; i < 0x200000; i += 8) {
        void* ptr = NULL;
        if (!safe_read((void*)(base + i), &ptr, 8)) continue;
        
        uintptr_t stripped_ptr = STRIP_PAC(ptr);
        if (stripped_ptr > 0x100000000 && stripped_ptr < 0x400000000) {
            uint8_t tt = 0;
            if (!safe_read((void*)(stripped_ptr + 0x2), &tt, 1) || tt != 9) continue;
            
            void* global_ptr = NULL;
            if (!safe_read((void*)(stripped_ptr + 0x78), &global_ptr, 8)) continue;
            
            uintptr_t stripped_global = STRIP_PAC(global_ptr);
            if (stripped_global < 0x100000000 || stripped_global > 0x400000000) continue;
            
            void* base_ci = NULL;
            if (!safe_read((void*)(stripped_ptr + 0x18), &base_ci, 8)) continue;
            if (STRIP_PAC(base_ci) < 0x100000000) continue;
            
            void* mainthread = NULL;
            if (safe_read((void*)(stripped_global + 0x1a0), &mainthread, 8)) {
                uintptr_t stripped_mt = STRIP_PAC(mainthread);
                if (stripped_mt > 0x100000000 && stripped_mt < 0x400000000) {
                    return (void*)stripped_mt;
                }
            }
        }
    }
    return NULL;
}

// --- VTable Hook for Job::step ---
void my_job_step(void* job) {
    if (g_scriptQueue && g_scriptQueue.count > 0) {
        
        uintptr_t base = get_robloxlib_base();
        void* script_context = NULL;
        
        if (safe_read((char*)job + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            script_context = (void*)STRIP_PAC(script_context);
            
            void* live_L = FindLuaState(script_context);
            
            if (live_L) {
                NSString *script = g_scriptQueue.firstObject;
                [g_scriptQueue removeObjectAtIndex:0];
                
                luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
                lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);
                lua_newthread_t lua_newthread = (lua_newthread_t)(base + OFFSET_LUA_NEWTHREAD);
                luaL_sandboxthread_t luaL_sandboxthread = (luaL_sandboxthread_t)(base + OFFSET_LUAL_SANDBOXTHREAD);
                
                SporkLog(@"Found live L: %p. Creating coroutine...", live_L);
                
                in_hook_exec = 1;
                int sig = sigsetjmp(hook_jump_buffer, 1);
                
                if (sig == 0) {
                    void* new_L = lua_newthread(live_L);
                    if (new_L) {
                        luaL_sandboxthread(new_L);

                        const char *source = [script UTF8String];
                        int status = luau_load(new_L, "SporkScript", source, strlen(source), 0);
                        if (status == 0) {
                            lua_pcall(new_L, 0, 0, 0);
                            SporkLog(@"Success: LocalScript executed!");
                        } else {
                            SporkLog(@"Error: Compile/Load Failed with status %d", status);
                        }
                    } else {
                        SporkLog(@"Error: Failed to create new thread.");
                    }
                    in_hook_exec = 0;
                } else {
                    in_hook_exec = 0;
                    SporkLog(@"HOOK CRASH CAUGHT: Signal %d. The app is safe.", sig);
                }
            } else {
                SporkLog(@"Error: Could not find a live thread.");
                [g_scriptQueue removeAllObjects];
            }
        }
    }
    
    // Call the original step function
    if (orig_job_step) {
        ((void(*)(void*))orig_job_step)(job);
    }
}

bool InjectExecutor(void) {
    if (g_logs) [g_logs removeAllObjects];
    SporkLog(@"Starting Injection...");
    
    signal(SIGSEGV, hook_signal_handler);
    signal(SIGBUS, hook_signal_handler);
    
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

    if (!start || !end || end <= start) {
        SporkLog(@"Error: Invalid job list pointers.");
        return false;
    }

    void* target_job = NULL;

    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        
        uintptr_t stripped_j = STRIP_PAC(j);
        
        void* script_context = NULL;
        if (safe_read((char*)stripped_j + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            target_job = j;
            SporkLog(@"Success: Found Job with ScriptContext: %p", j);
            break;
        }
    }
    
    if (!target_job) {
        SporkLog(@"Error: Could not find a valid Job.");
        return false;
    }

    // --- VTable Hook ---
    void** original_vtable = *(void***)target_job;
    orig_job_step = original_vtable[0]; 
    
    void** new_vtable = (void**)malloc(0x1000);
    memcpy(new_vtable, original_vtable, 0x1000);
    
    new_vtable[0] = (void*)my_job_step;
    
    uintptr_t job_page = (uintptr_t)target_job & ~0xFFF;
    vm_protect(mach_task_self(), job_page, 0x4000, false, VM_PROT_READ | VM_PROT_WRITE);
    *(void***)target_job = new_vtable;
    
    SporkLog(@"Success: Hooked Job::step via VTable!");
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
