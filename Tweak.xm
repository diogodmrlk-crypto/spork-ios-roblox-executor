#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import "SporkUI.h"
#import "fishhook.h"

// --- Offsets for Roblox 2.744.0.1077 ---
#define OFFSET_LUA_GETTOP 0x448e048
#define OFFSET_LUAU_LOAD  0x44bc110
#define OFFSET_LUA_PCALL  0x4490fec

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
typedef int (*lua_gettop_t)(void* L);

static void* g_L = NULL;
static lua_gettop_t orig_lua_gettop = NULL;
bool g_is_injected = false;

// Hook to silently steal the active Lua State from Roblox
int my_lua_gettop(void* L) {
    if (!g_L) g_L = L; 
    if (orig_lua_gettop) return orig_lua_gettop(L);
    return 0;
}

bool InjectExecutor(void) {
    g_is_injected = true;
    NSLog(@"[Spork] Executor Injection Enabled.");
    return true;
}

void ExecuteLuauBytecode(const char* bytecode, size_t size) {
    if (!g_is_injected) {
        NSLog(@"[Spork] Error: You must Inject first!");
        return;
    }
    if (!g_L) {
        NSLog(@"[Spork] Error: Lua State not found. Wait until you are in a game.");
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
    // Hook lua_gettop via fishhook (Safe, no substrate required)
    struct rebinding rebind_lua_gettop;
    rebind_lua_gettop.name = "lua_gettop";
    rebind_lua_gettop.replacement = (void *)my_lua_gettop;
    rebind_lua_gettop.replaced = (void **)&orig_lua_gettop;
    
    struct rebinding rebindings[] = { rebind_lua_gettop };
    rebind_symbols(rebindings, 1);

    // Setup UI Window
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
