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
    SporkExecutor::CaptureLuaState(L);
    SporkExecutor::ProcessQueue();
    return orig_luau_load(L, chunkname, data, size, env);
}

extern "C" void injectHook() {
    NSLog(@"[Spork] Manual inject requested...");
    uintptr_t base = 0;
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxLib")) {
            base = (uintptr_t)_dyld_get_image_header(i);
            break;
        }
    }
    
    if (base) {
        uintptr_t loadAddr = base + offsets::luau::luau_load;
        NSLog(@"[Spork] Trying to hook luau_load at %p (Base: %p + Offset: %p)", (void*)loadAddr, (void*)base, (void*)offsets::luau::luau_load);
        MSHookFunction((void*)loadAddr, (void*)hooked_luau_load, (void**)&orig_luau_load);
        NSLog(@"[Spork] Hook applied successfully!");
    } else {
        NSLog(@"[Spork] RobloxLib not found.");
    }
}

__attribute__((constructor))
static void init() {
    NSLog(@"[Spork] Constructor started! (This proves dyld loaded the tweak)");
    
    // Setup UI Window after a delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSLog(@"[Spork] Initializing Executor and UI...");
        
        SporkExecutor::Initialize();

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
        NSLog(@"[Spork] UI Setup Complete!");
    });
}
