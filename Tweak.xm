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
#define OFFSET_LUA_PUSHCCLOSUREK  0x448f9fc
#define OFFSET_SPAWN              0x19a56ec
#define OFFSET_LUA_GETTOP         0x448e048
#define OFFSET_LUA_SETTOP         0x448e05c
#define OFFSET_LUA_PUSHVALUE      0x448e428

// --- New Offset for Modern Roblox ScriptContext ---
#define OFFSET_SCRIPT_CONTEXT_LUA_STATE_ARRAY 0x2B8

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
typedef void (*lua_pushcclosurek_t)(void* L, void* fn, const char* debugname, int nup, void* cont);
typedef void (*spawn_t)(void* L);
typedef int (*lua_gettop_t)(void* L);
typedef void (*lua_settop_t)(void* L, int idx);
typedef void (*lua_pushvalue_t)(void* L, int idx);

bool g_is_injected = false;
int g_execution_method = 1; // 1, 2, 3, or 4
static NSMutableArray<NSString *> *g_scriptQueue = nil;
static const char* g_current_script_source = NULL;
static size_t g_current_script_size = 0;

static void* orig_job_step = NULL;
static int g_find_fail_count = 0; 

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

// --- NEW: Robust Lua State Retrieval for Modern Roblox ---
void* GetLuaStateFromScriptContext(void* script_context) {
    if (!script_context) return NULL;
    uintptr_t ctx_addr = STRIP_PAC(script_context);

    // The encrypted array is located at ScriptContext + 0x2B8
    uintptr_t encrypted_array_addr = ctx_addr + OFFSET_SCRIPT_CONTEXT_LUA_STATE_ARRAY;

    uint32_t encrypted[2] = {0, 0};
    if (!safe_read((void*)encrypted_array_addr, &encrypted, sizeof(encrypted))) {
        return NULL;
    }

    // Decryption Algorithm: (High << 32) | Low
    // Low  = (uint32_t)Address - Encrypted[0]
    // High = (uint32_t)Address - Encrypted[1]
    uint32_t low  = (uint32_t)encrypted_array_addr - encrypted[0];
    uint32_t high = (uint32_t)encrypted_array_addr - encrypted[1];

    uintptr_t lua_state_ptr = ((uint64_t)high << 32) | low;

    // Sanity check: ensure the pointer is in a valid memory range
    if (lua_state_ptr < 0x100000000 || lua_state_ptr > 0x400000000) {
        return NULL;
    }

    return (void*)lua_state_ptr;
}

// The C function for Method 3
int my_script_runner(void* L) {
    uintptr_t base = get_robloxlib_base();
    luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
    lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);

    SporkLog(@"[M3] Running script on engine thread...");
    int status = luau_load(L, "SporkScript", g_current_script_source, g_current_script_size, 0);
    if (status == 0) {
        lua_pcall(L, 0, 0, 0);
        SporkLog(@"[M3] Success: Script executed!");
    } else {
        SporkLog(@"[M3] Error: Compile/Load Failed with status %d", status);
    }
    return 0;
}

// --- VTable Hook for Job::step ---
void my_job_step(void* job) {
    if (g_scriptQueue && g_scriptQueue.count > 0) {
        
        uintptr_t base = get_robloxlib_base();
        void* script_context = NULL;
        
        if (safe_read((char*)job + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            script_context = (void*)STRIP_PAC(script_context);
            
            // Use the new decryption function
            void* live_L = GetLuaStateFromScriptContext(script_context);
            
            if (live_L) {
                g_find_fail_count = 0;
                NSString *script = g_scriptQueue.firstObject;
                [g_scriptQueue removeObjectAtIndex:0];
                
                g_current_script_source = [script UTF8String];
                g_current_script_size = strlen(g_current_script_source);
                
                luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
                lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);
                lua_gettop_t lua_gettop = (lua_gettop_t)(base + OFFSET_LUA_GETTOP);
                lua_settop_t lua_settop = (lua_settop_t)(base + OFFSET_LUA_SETTOP);
                lua_pushvalue_t lua_pushvalue = (lua_pushvalue_t)(base + OFFSET_LUA_PUSHVALUE);
                lua_newthread_t lua_newthread = (lua_newthread_t)(base + OFFSET_LUA_NEWTHREAD);
                luaL_sandboxthread_t luaL_sandboxthread = (luaL_sandboxthread_t)(base + OFFSET_LUAL_SANDBOXTHREAD);
                lua_pushcclosurek_t lua_pushcclosurek = (lua_pushcclosurek_t)(base + OFFSET_LUA_PUSHCCLOSUREK);
                spawn_t spawn = (spawn_t)(base + OFFSET_SPAWN);
                
                SporkLog(@"Hook fired! live_L: %p | Method: %d", live_L, g_execution_method);
                
                in_hook_exec = 1;
                int sig = sigsetjmp(hook_jump_buffer, 1);
                
                if (sig == 0) {
                    
                    if (g_execution_method == 1) {
                        // Method 1: Direct with Env
                        int top = lua_gettop(live_L);
                        lua_pushvalue(live_L, -10002);
                        int env = lua_gettop(live_L);
                        int status = luau_load(live_L, "SporkScript", g_current_script_source, g_current_script_size, env);
                        if (status == 0) lua_pcall(live_L, 0, 0, 0);
                        else SporkLog(@"[M1] luau_load status %d", status);
                        lua_settop(live_L, top);
                        
                    } else if (g_execution_method == 2) {
                        // Method 2: New Thread + Sandbox
                        void* new_L = lua_newthread(live_L);
                        if (new_L) {
                            luaL_sandboxthread(new_L);
                            int status = luau_load(new_L, "SporkScript", g_current_script_source, g_current_script_size, 0);
                            if (status == 0) lua_pcall(new_L, 0, 0, 0);
                            else SporkLog(@"[M2] luau_load status %d", status);
                        }
                        
                    } else if (g_execution_method == 3) {
                        // Method 3: Spawn
                        lua_pushcclosurek(live_L, (void*)my_script_runner, "SporkRunner", 0, NULL);
                        spawn(live_L);
                        
                    } else if (g_execution_method == 4) {
                        // Method 4: Raw Pcall (no env)
                        int status = luau_load(live_L, "SporkScript", g_current_script_source, g_current_script_size, 0);
                        if (status == 0) lua_pcall(live_L, 0, 0, 0);
                        else SporkLog(@"[M4] luau_load status %d", status);
                    }
                    
                    SporkLog(@"Method %d finished without VM crash!", g_execution_method);
                    in_hook_exec = 0;
                } else {
                    in_hook_exec = 0;
                    SporkLog(@"HOOK CRASH CAUGHT: Signal %d on Method %d", sig, g_execution_method);
                }
            } else {
                g_find_fail_count++;
                if (g_find_fail_count == 1 || g_find_fail_count % 60 == 0) {
                    SporkLog(@"GetLuaStateFromScriptContext returned NULL (attempt %d) — retrying", g_find_fail_count);
                }
            }
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
    kern_return_t kr = vm_protect(mach_task_self(), job_page, 0x4000, false, VM_PROT_READ | VM_PROT_WRITE);
    if (kr != KERN_SUCCESS) {
        kr = vm_protect(mach_task_self(), job_page, 0x4000, true, VM_PROT_READ | VM_PROT_WRITE);
    }
    
    if (kr != KERN_SUCCESS) {
        SporkLog(@"Error: vm_protect failed (%d). Signing / entitlement issue?", kr);
        free(new_vtable);
        return false;
    }
    
    *(void***)target_job = new_vtable;
    
    SporkLog(@"Success: Hooked Job::step via VTable!");
    g_is_injected = true;
    return true;
}

// Renamed from ExecuteLuauSource to match extern declaration in SporkUI.mm
void ExecuteLuauBytecode(const char* source, size_t size) {
    if (!g_is_injected) return;
    if (!g_scriptQueue) g_scriptQueue = [NSMutableArray new];
    
    NSString *script = [NSString stringWithUTF8String:source];
    if (!script) return;
    [g_scriptQueue addObject:script];
    SporkLog(@"Script queued for execution using Method %d", g_execution_method);
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
