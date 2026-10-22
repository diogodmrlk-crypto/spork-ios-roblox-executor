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

// This function is now called manually from the UI
extern "C" void injectHook() {
    NSLog(@"[Spork] Manual inject requested...");
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxLib")) {
            uintptr_t base = _dyld_get_image_vmaddr_slide(i);
            uintptr_t loadAddr = base + offsets::luau::luau_load;
            
            // If the offset is wrong, the app will crash right here
            MSHookFunction((void*)loadAddr, (void*)hooked_luau_load, (void**)&orig_luau_load);
            NSLog(@"[Spork] Hooked luau_load at %p", (void*)loadAddr);
            return;
        }
    }
    NSLog(@"[Spork] RobloxLib not found.");
}

__attribute__((constructor))
static void init() {
    // Initialize the Executor (resolves function pointers)
    SporkExecutor::Initialize();
    
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
