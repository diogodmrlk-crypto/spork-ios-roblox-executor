#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <string.h>
#import <stdlib.h>
#import <dlfcn.h>
#import <substrate.h>
#import "SporkUI.h"

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

#pragma mark - Executor Logic & Pattern Scanning

typedef int (*lua_pcall_t)(void* L, int nargs, int nresults, int errfunc);
typedef int (*luau_load_t)(void* L, const char* chunkname, const char* data, size_t size, int env);
typedef int (*lua_gettop_t)(void* L);

static void* g_L = NULL;
static lua_gettop_t orig_lua_gettop = NULL;

// A dummy hook to capture the lua_State
int new_lua_gettop(void* L) {
    if (!g_L) g_L = L; 
    if (orig_lua_gettop) return orig_lua_gettop(L);
    return 0;
}

// ARM64 Pattern Scanner
uintptr_t find_pattern(const uint8_t* pattern, const char* mask, size_t pattern_len) {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    size_t search_size = 0x20000000; 
    
    for (uintptr_t i = base; i < base + search_size - pattern_len; i++) {
        BOOL found = YES;
        for (size_t j = 0; j < pattern_len; j++) {
            if (mask[j] == 'x' && *(uint8_t*)(i + j) != pattern[j]) {
                found = NO;
                break;
            }
        }
        if (found) return i;
    }
    return 0;
}

void ExecuteLuauBytecode(const char* bytecode, size_t size) {
    if (!g_L) {
        NSLog(@"[Spork] Error: Lua State not found yet.");
        return;
    }

    // TODO: Replace with real ARM64 signatures when you find them
    static const uint8_t load_sig[]  = { 0x00, 0x00, 0x00, 0x00 }; 
    static const uint8_t pcall_sig[] = { 0x00, 0x00, 0x00, 0x00 };
    
    uintptr_t load_addr = find_pattern(load_sig, "xxxx", sizeof(load_sig));
    uintptr_t pcall_addr = find_pattern(pcall_sig, "xxxx", sizeof(pcall_sig));

    if (!load_addr || !pcall_addr) {
        NSLog(@"[Spork] Signatures not set. Cannot execute bytecode.");
        return;
    }

    luau_load_t luau_load = (luau_load_t)load_addr;
    lua_pcall_t lua_pcall = (lua_pcall_t)pcall_addr;

    int status = luau_load(g_L, "SporkScript", bytecode, size, 0);
    if (status == 0) {
        lua_pcall(g_L, 0, 0, 0);
        NSLog(@"[Spork] Bytecode Executed Successfully");
    } else {
        NSLog(@"[Spork] Load Failed: %d", status);
    }
}

__attribute__((constructor))
static void init() {
    // SAFELY check for substrate before trying to hook to prevent launch crash
    if (dlsym(RTLD_DEFAULT, "MSHookFunction") != NULL) {
        void* lua_gettop_ptr = dlsym(RTLD_DEFAULT, "lua_gettop");
        if (lua_gettop_ptr) {
            MSHookFunction(lua_gettop_ptr, (void*)&new_lua_gettop, (void**)&orig_lua_gettop);
        }
    } else {
        NSLog(@"[Spork] CydiaSubstrate/ElleKit not found! Cannot hook lua_gettop.");
    }

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
