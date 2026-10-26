#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <ptrauth.h>
#import "SporkUI.h"
#include "dobby.h"

// --- Offsets for Roblox 2.744.0.1077 (Relative to RobloxLib) ---
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUAU_LOAD          0x44bc110
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

static lua_pcall_t orig_lua_pcall = NULL;

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

// --- Hook Function ---
int my_lua_pcall(void* L, int nargs, int nresults, int errfunc) {
    if (g_scriptQueue && g_scriptQueue.count > 0) {
        NSString *script = g_scriptQueue.firstObject;
        [g_scriptQueue removeObjectAtIndex:0];
        
        uintptr_t base = get_robloxlib_base();
        luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
        lua_newthread_t lua_newthread = (lua_newthread_t)(base + OFFSET_LUA_NEWTHREAD);
        luaL_sandboxthread_t luaL_sandboxthread = (luaL_sandboxthread_t)(base + OFFSET_LUAL_SANDBOXTHREAD);
        
        SporkLog(@"Hook triggered! Creating safe coroutine...");
        
        // Create a new thread INSIDE the hook (this is now safe because we are on the engine thread)
        void* new_L = lua_newthread(L);
        if (new_L) {
            luaL_sandboxthread(new_L); // Give it the game environment
            
            const char *source = [script UTF8String];
            int status = luau_load(new_L, "SporkScript", source, strlen(source), 0);
            if (status == 0) {
                orig_lua_pcall(new_L, 0, 0, 0); // Execute our script
                SporkLog(@"Success: LocalScript executed!");
            } else {
                SporkLog(@"Error: Compile/Load Failed with status %d", status);
            }
        }
    }
    
    // Continue the game's original execution safely
    return orig_lua_pcall(L, nargs, nresults, errfunc);
}

bool InjectExecutor(void) {
    if (g_logs) [g_logs removeAllObjects];
    SporkLog(@"Starting Injection...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) {
        SporkLog(@"Error: Failed to find RobloxLib base.");
        return false;
    }

    // Strip PAC from function pointers (essential for arm64e)
    void* target_pcall = (void*)(base + OFFSET_LUA_PCALL);
    void* stripped_target = __builtin_ptrauth_strip(target_pcall, ptrauth_key_asia);
    void* stripped_hook = __builtin_ptrauth_strip((void*)my_lua_pcall, ptrauth_key_asia);
    
    // Install the hook using Dobby
    int ret = DobbyHook(stripped_target, stripped_hook, (void**)&orig_lua_pcall);
    
    if (ret == 0) {
        // Re-sign the original function pointer so it can be called normally
        orig_lua_pcall = (lua_pcall_t)ptrauth_sign_unauthenticated((void*)orig_lua_pcall, ptrauth_key_asia, 0);
        
        SporkLog(@"Success: Hooked lua_pcall!");
        g_is_injected = true;
        return true;
    } else {
        SporkLog(@"Error: DobbyHook failed with code %d", ret);
        return false;
    }
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
