#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <stdlib.h>
#import <signal.h>
#import <setjmp.h>
#import "SporkUI.h"

// --- Exact Offsets from your 2.744.0.1077 dump ---
#define OFFSET_TASKSCHEDULER      0x6a6d7c0
#define OFFSET_TS_JOBS_START      0xd0
#define OFFSET_TS_JOBS_END        0xd8
#define OFFSET_JOB_SCRIPT_CTX     0x1b0

// The function from your dump to get global_State from ScriptContext
#define OFFSET_GET_GLOBAL_STATE   0x19ce768
#define OFFSET_MAINTHREAD         0x1a0

// Lua functions
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
typedef void* (*get_global_state_t)(void* sc);

bool g_is_injected = false;
int g_execution_method = 1; 

static NSMutableArray<NSString *> *g_scriptQueue = nil;
static const char* g_current_script_source = NULL;
static size_t g_current_script_size = 0;

static void* g_live_L = NULL; // Our saved lua_State pointer
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
    if (addr < 0x100000000) return false; 
    
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

// --- VTable Hook for Job::step ---
void my_job_step(void* job) {
    if (g_scriptQueue && g_scriptQueue.count > 0 && g_live_L) {
        
        uintptr_t base = get_robloxlib_base();
        
        NSString *script = g_scriptQueue.firstObject;
        [g_scriptQueue removeObjectAtIndex:0];
        
        g_current_script_source = [script UTF8String];
        g_current_script_size = strlen(g_current_script_source);
        
        luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
        lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);
        lua_newthread_t lua_newthread = (lua_newthread_t)(base + OFFSET_LUA_NEWTHREAD);
        luaL_sandboxthread_t luaL_sandboxthread = (luaL_sandboxthread_t)(base + OFFSET_LUAL_SANDBOXTHREAD);
        
        SporkLog(@"Hook fired! Using saved live_L: %p", g_live_L);
        
        in_hook_exec = 1;
        int sig = sigsetjmp(hook_jump_buffer, 1);
        
        if (sig == 0) {
            void* new_L = lua_newthread(g_live_L);
            if (new_L) {
                luaL_sandboxthread(new_L);
                int status = luau_load(new_L, "SporkScript", g_current_script_source, g_current_script_size, 0);
                if (status == 0) {
                    lua_pcall(new_L, 0, 0, 0);
                    SporkLog(@"Executed successfully!");
                } else {
                    SporkLog(@"luau_load failed. Status: %d", status);
                }
            } else {
                SporkLog(@"lua_newthread returned NULL.");
            }
            in_hook_exec = 0;
        } else {
            in_hook_exec = 0;
            SporkLog(@"HOOK CRASH CAUGHT: Signal %d", sig);
        }
    }
    
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
    void* script_context = NULL;

    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        
        uintptr_t stripped_j = STRIP_PAC(j);
        
        void* job_sc = NULL;
        if (safe_read((char*)stripped_j + OFFSET_JOB_SCRIPT_CTX, &job_sc, 8) && job_sc) {
            target_job = j;
            script_context = job_sc;
            SporkLog(@"Success: Found Job with ScriptContext: %p", j);
            break;
        }
    }
    
    if (!target_job || !script_context) {
        SporkLog(@"Error: Could not find a valid Job.");
        return false;
    }

    // --- Get lua_State directly using your dumped offset ---
    // We do this HERE, outside of Job::step, to avoid deadlocking the engine!
    get_global_state_t get_global_state = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    void* global_state = get_global_state(script_context);
    
    if (global_state) {
        safe_read((char*)global_state + OFFSET_MAINTHREAD, &g_live_L, 8);
        if (g_live_L) {
            SporkLog(@"Got live_L from global_State: %p", g_live_L);
        } else {
            SporkLog(@"Error: mainthread was NULL.");
            return false;
        }
    } else {
        SporkLog(@"Error: get_global_state returned NULL.");
        return false;
    }

    // --- VTable Hook ---
    void** original_vtable = *(void***)target_job;
    orig_job_step = original_vtable[0]; 
    
    void** new_vtable = (void**)malloc(0x1000);
    memcpy(new_vtable, original_vtable, 0x1000);
    new_vtable[0] = (void*)my_job_step;
    
    uintptr_t job_page = (uintptr_t)target_job & ~0xFFF;
    kern_return_t kr = vm_protect(mach_task_self(), job_page, 0x4000, false, VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        kr = vm_protect(mach_task_self(), job_page, 0x4000, true, VM_PROT_READ | VM_PROT_WRITE);
    }
    
    if (kr != KERN_SUCCESS) {
        SporkLog(@"Error: vm_protect failed (%d). Signing issue?", kr);
        free(new_vtable);
        return false;
    }
    
    *(void***)target_job = new_vtable;
    SporkLog(@"Success: Hooked Job::step via VTable!");
    g_is_injected = true;
    return true;
}

void ExecuteLuauBytecode(const char* source, size_t size) {
    if (!g_is_injected) return;
    if (!g_scriptQueue) g_scriptQueue = [NSMutableArray new];
    
    NSString *script = [NSString stringWithUTF8String:source];
    if (!script) return;
    [g_scriptQueue addObject:script];
    SporkLog(@"Script queued for execution");
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
