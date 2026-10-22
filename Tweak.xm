#import <UIKit/UIKit.h>
#import "SporkUI.h"

__attribute__((constructor))
static void init() {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Find the active scene (Required for iOS 13+)
        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]] && scene.activationState == UISceneActivationStateForegroundActive) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        UIWindow *overlayWindow;
        if (activeScene) {
            overlayWindow = [[UIWindow alloc] initWithWindowScene:activeScene];
        } else {
            overlayWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        }

        overlayWindow.windowLevel = UIWindowLevelAlert + 100;
        overlayWindow.backgroundColor = [UIColor clearColor];
        overlayWindow.rootViewController = [[SporkViewController alloc] init];
        overlayWindow.hidden = NO;
        // We don't use makeKeyAndVisible so it doesn't mess up Roblox's inputs
    });
}
