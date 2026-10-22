#import <UIKit/UIKit.h>
#import "SporkUI.h"

static UIWindow *overlayWindow = nil;

__attribute__((constructor))
static void init() {
    // Wait 3 seconds to ensure Roblox UI is fully loaded
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (overlayWindow) return; 

        // 1. Find the active scene (Required for iOS 13+)
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        // 2. Create the window
        if (activeScene) {
            overlayWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        } else {
            overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        // 3. CRITICAL FIX: Force the window to fill the screen bounds
        overlayWindow.frame = [UIScreen mainScreen].bounds;
        overlayWindow.windowLevel = UIWindowLevelAlert + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        
        // 4. Set the root view controller and make it visible
        overlayWindow.rootViewController = [[SporkViewController alloc] init];
        overlayWindow.hidden = NO;
        [overlayWindow makeKeyAndVisible];
    });
}
