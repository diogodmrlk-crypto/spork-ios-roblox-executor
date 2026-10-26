#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import "SporkUI.h"

// --- Offsets for Roblox 2.744.0.1077 ---
#define OFFSET_TASKSCHEDULER    0x6a6d7c0
#define OFFSET_TS_JOBS_START    0xd0
#define OFFSET_TS_JOBS_END      0xd8
#define OFFSET_JOB_NAME         0x18
#define OFFSET_JOB_SCRIPT_CTX   0x1b0
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

static void* g_L = NULL;
bool g_is_injected = false;

// Memory scanner to find lua_State inside ScriptContext safely
void* FindLuaState(void* script_context) {
    if (!script_context) return NULL;
    
    // Scan the first 0x2000 bytes of ScriptContext for a lua_State pointer
    for (int i = 0; i < 0x2000; i += 8) {
        void* ptr = *(void**)((char*)script_context + i);
        
        // Valid user-space pointer check (Cast to uintptr_t to fix compile error)
        if ((uintptr_t)ptr > 0x100000000 && (uintptr_t)ptr < 0x8000000000) {
            uint8_t tt = *(uint8_t*)((char*)ptr + 0x2); // lua_State::tt is at 0x2
            void* global = *(void**)((char*)ptr + 0x78); // lua_State::global is at 0x78
            
            // LUA_TTHREAD is 8. If this matches, we found the lua_State!
            if (tt == 8 && (uintptr_t)global > 0x100000000) {
                return ptr;
            }
        }
    }
    return NULL;
}

bool InjectExecutor(void) {
    g_is_injected = true;
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    
    // 1. Find TaskScheduler
    void* task_scheduler = *(void**)(base + OFFSET_TASKSCHEDULER);
    if (!task_scheduler) {
        NSLog(@"[Spork] Failed to find TaskScheduler.");
        return false;
    }
    
    // 2. Iterate through jobs to find WaitingHybridScriptsJob
    uintptr_t start = *(uintptr_t*)((char*)task_scheduler + OFFSET_TS_JOBS_START);
    uintptr_t end = *(uintptr_t*)((char*)task_scheduler + OFFSET_TS_JOBS_END);
    void* script_context = NULL;
    
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* job = *(void**)(ptr);
        if (!job) continue;
        
        uintptr_t str_ptr = *(uintptr_t*)((char*)job + OFFSET_JOB_NAME);
        if (str_ptr > 0x100000000) {
            const char* name = (const char*)str_ptr;
            if (strcmp(name, "WaitingHybridScriptsJob") == 0) {
                script_context = *(void**)((char*)job + OFFSET_JOB_SCRIPT_CTX);
                break;
            }
        }
    }
    
    if (!script_context) {
        NSLog(@"[Spork] Failed to find WaitingHybridScriptsJob.");
        return false;
    }
    
    // 3. Safely scan for lua_State
    g_L = FindLuaState(script_context);
    
    if (g_L) {
        NSLog(@"[Spork] Successfully Injected! lua_State: %p", g_L);
        return true;
    }
    
    NSLog(@"[Spork] Injection failed: Could not find lua_State.");
    return false;
}

void ExecuteLuauBytecode(const char* bytecode, size_t size) {
    if (!g_is_injected || !g_L) return;

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
