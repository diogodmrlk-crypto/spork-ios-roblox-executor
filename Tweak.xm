#import <UIKit/UIKit.h>
#import <substrate.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <stdlib.h>
#import <signal.h>
#import <setjmp.h>
#import "SporkUI.h"

// ==========================================
// 1. CONFIG (config.hpp equivalent)
// ==========================================
#define OFFSET_LUA_GETTOP         0x448e048
#define OFFSET_LUAU_LOAD          0x44bc110
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUA_NEWTHREAD      0x448df3c
#define OFFSET_LUAL_SANDBOXTHREAD 0x1a12ad4

#define OFFSET_LUA_STATE_GLOBAL   0x78
#define OFFSET_LUA_STATE_TT       0x2

// ==========================================
// 2. LIBRARIES & TYPEDEFS
// ==========================================
typedef int (*lua_pcall_t)(void* L, int nargs, int nresults, int errfunc);
typedef int (*luau_load_t)(void* L, const char* chunkname, const char* data, size_t size, int env);
typedef void* (*lua_newthread_t)(void* L);
typedef void (*luaL_sandboxthread_t)(void* L);
typedef int (*lua_gettop_t)(void* L);

bool g_is_injected = false;
int g_execution_method = 1; 

static NSMutableArray<NSString *> *g_scriptQueue = nil;
static void* g_live_L = NULL; // The stolen lua_State!

// ==========================================
// 3. MEMORY (memory equivalent)
// ==========================================
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

// ==========================================
// 4. LOGGING
// ==========================================
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

// ==========================================
// 5. HOOKS (hooks equivalent)
// ==========================================
static lua_gettop_t orig_lua_gettop = NULL;

// We intercept every lua_gettop call to steal the lua_State
int my_lua_gettop(void* L) {
    if (!g_live_L && L) {
        // Verify this is a real lua_State by checking its global pointer (offset 0x78)
        uintptr_t global_ptr = 0;
        if (safe_read((char*)L + OFFSET_LUA_STATE_GLOBAL, &global_ptr, 8) && global_ptr > 0x100000000) {
            g_live_L = L;
            SporkLog(@"STOLE lua_State via lua_gettop: %p", L);
        }
    }
    return orig_lua_gettop(L);
}

// ==========================================
// 6. EXPLOIT / ENVIRONMENT (exploit equivalent)
// ==========================================
static sigjmp_buf hook_jump_buffer;
static volatile sig_atomic_t in_hook_exec = 0;

void hook_signal_handler(int sig) {
    if (in_hook_exec) {
        siglongjmp(hook_jump_buffer, sig);
    }
}

void ExecuteLuauBytecode(const char* source, size_t size) {
    if (!g_is_injected || !g_live_L) {
        SporkLog(@"Cannot execute: Not injected or L is NULL.");
        return;
    }
    
    uintptr_t base = get_robloxlib_base();
    luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
    lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);
    lua_newthread_t lua_newthread = (lua_newthread_t)(base + OFFSET_LUA_NEWTHREAD);
    luaL_sandboxthread_t luaL_sandboxthread = (luaL_sandboxthread_t)(base + OFFSET_LUAL_SANDBOXTHREAD);
    
    SporkLog(@"Executing script on L: %p", g_live_L);
    
    in_hook_exec = 1;
    int sig = sigsetjmp(hook_jump_buffer, 1);
    
    if (sig == 0) {
        // Create a new thread to prevent corrupting the main UI thread
        void* new_L = lua_newthread(g_live_L);
        if (new_L) {
            luaL_sandboxthread(new_L);
            int status = luau_load(new_L, "SporkScript", source, size, 0);
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
    
    // Hook lua_gettop
    void* target_gettop = (void*)(base + OFFSET_LUA_GETTOP);
    MSHookFunction(target_gettop, (void*)my_lua_gettop, (void**)&orig_lua_gettop);
    
    SporkLog(@"Hooked lua_gettop at %p. Waiting for game to call it...", target_gettop);
    g_is_injected = true;
    return true;
}

// ==========================================
// 7. UI ENTRY (main.cpp equivalent)
// ==========================================
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
