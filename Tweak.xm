#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <mach/mach.h>
#import <string.h>
#import <stdlib.h>
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

#pragma mark - Executor Logic & Pattern Scanning

typedef void* (*lua_State_t)(void);
typedef int (*luau_load_t)(void* L, const char* chunkname, const char* data, size_t size, int env);
typedef int (*lua_pcall_t)(void* L, int nargs, int nresults, int errfunc);

// Store the active Lua State globally
static void* g_L = NULL;

// Hook lua_gettop to silently steal the Lua State when the game calls it
int (*orig_lua_gettop)(void* L);
int new_lua_gettop(void* L) {
    if (!g_L) g_L = L; // Save the state
    return orig_lua_gettop(L);
}

// ARM64 Pattern Scanner
uintptr_t find_pattern(const char* pattern, const char* mask, size_t pattern_len) {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    uintptr_t slide = _dyld_get_image_vmaddr_slide(0);
    
    // Get the __TEXT segment size (approx first 0x2000000 bytes for Roblox)
    // In a real production environment, you'd parse the Mach-O headers to get the exact size
    size_t search_size = 0x20000000; 
    
    for (uintptr_t i = base; i < base + search_size - pattern_len; i++) {
        BOOL found = YES;
        for (size_t j = 0; j < pattern_len; j++) {
            if (mask[j] == 'x' && *(char*)(i + j) != pattern[j]) {
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
        NSLog(@"[Spork] Error: Lua State not found yet. Wait a few seconds after joining a game.");
        return;
    }

    // --- IMPORTANT: You must find the correct signatures for the current Roblox version ---
    // The example signatures below are placeholders. You can find these by reverse engineering 
    // the current Roblox binary in IDA/Ghidra.
    
    // 1. Find luau_load
    // Look for the assembly instructions that setup the stack frame for luau_load
    const char* load_sig = "\x??\x??\x??\x??"; // Replace with real signature
    uintptr_t load_addr = find_pattern(load_sig, "xxxx", 4);
    
    // 2. Find lua_pcall
    const char* pcall_sig = "\x??\x??\x??\x??"; // Replace with real signature
    uintptr_t pcall_addr = find_pattern(pcall_sig, "xxxx", 4);

    if (load_addr && pcall_addr) {
        luau_load_t luau_load = (luau_load_t)load_addr;
        lua_pcall_t lua_pcall = (lua_pcall_t)pcall_addr;

        // Load the bytecode
        int status = luau_load(g_L, "SporkScript", bytecode, size, 0);
        
        if (status == 0) {
            // Execute the loaded chunk
            lua_pcall(g_L, 0, 0, 0);
            NSLog(@"[Spork] Script Executed Successfully");
        } else {
            NSLog(@"[Spork] Bytecode Load Failed with status: %d", status);
        }
    } else {
        NSLog(@"[Spork] Failed to find luau_load or lua_pcall signatures.");
    }
}

// Hook to capture state (Ensure you hook a function that Roblox calls constantly)
%hookf(int, lua_gettop, void* L) {
    if (!g_L) g_L = L;
    return orig_lua_gettop(L);
}
