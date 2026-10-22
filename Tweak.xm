#import <UIKit/UIKit.h>
#import <substrate.h>
#include <dlfcn.h>
#include <mach-o/dyld.h>
#import "SporkUI.h"
#import "Executor.hpp"
#include "offsets.h"

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

// Hooked function for luau_load
static int (*orig_luau_load)(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env) = nullptr;
static int hooked_luau_load(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env) {
    // 1. Capture the Lua State
    SporkExecutor::CaptureLuaState(L);
    
    // 2. Process any queued scripts from the UI
    SporkExecutor::ProcessQueue();
    
    // 3. Call the original function
    return orig_luau_load(L, chunkname, data, size, env);
}

__attribute__((constructor))
static void init() {
    SporkExecutor::Initialize();
    
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

// Hook luau_load when RobloxLib loads
static void imageLoaded(const struct mach_header* mh, intptr_t vmaddr_slide) {
    Dl_info info;
    if (dladdr(mh, &info)) {
        if (strstr(info.dli_fname, "RobloxLib")) {
            uintptr_t base = (uintptr_t)mh;
            uintptr_t loadAddr = base + offsets::luau::luau_load;
            MSHookFunction((void*)loadAddr, (void*)hooked_luau_load, (void**)&orig_luau_load);
            NSLog(@"[Spork] Hooked luau_load at %p", (void*)loadAddr);
        }
    }
}
__attribute__((constructor)) static void setupHook() {
    _dyld_register_func_for_add_image(imageLoaded);
}
