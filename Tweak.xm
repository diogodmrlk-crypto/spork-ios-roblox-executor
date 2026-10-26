#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import "SporkUI.h"

// --- Offsets for Roblox 2.744.0.1077 ---
#define OFFSET_GET_GLOBAL_STATE 0x19ce768
#define OFFSET_GS_MAINTHREAD    0x1a0
#define OFFSET_LUAU_LOAD        0x44bc110
#define OFFSET_LUA_PCALL        0x4490fec

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
typedef void* (*get_global_state_t)(void);

static void* g_L = NULL;
bool g_is_injected = false;

bool InjectExecutor(void) {
    g_is_injected = true;
    
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    
    // Call get_global_state from your offsets
    get_global_state_t get_gs = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    void* global_state = get_gs();
    
    if (global_state) {
        // Read mainthread offset (0x1a0) to get lua_State
        g_L = *(void**)((char*)global_state + OFFSET_GS_MAINTHREAD);
        NSLog(@"[Spork] Successfully Injected! lua_State: %p", g_L);
        return true;
    } else {
        NSLog(@"[Spork] Inject failed: global_State is NULL.");
        return false;
    }
}

void ExecuteLuauBytecode(const char* bytecode, size_t size) {
    if (!g_is_injected) return;
    
    if (!g_L) {
        NSLog(@"[Spork] Error: Lua State is NULL. Wait until you fully load into a game, then click Inject.");
        return;
    }

    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
    lua_pcall_t lua_pcall = (lua_pcall_t)(base + OFFSET_LUA_PCALL);

    int status = luau_load(g_L, "SporkScript", bytecode, size, 0);
    if (status == 0) {
        lua_pcall(g_L, 0, 0, 0);
        NSLog(@"[Spork] Bytecode Executed Successfully");
    } else {
        NSLog(@"[Spork] Bytecode Load Failed: %d", status);
    }
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
    });
}
