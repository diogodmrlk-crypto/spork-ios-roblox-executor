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
typedef void* (*get_global_state_t)(void*);

static void* g_L = NULL;
bool g_is_injected = false;

// Memory scanner to find lua_State by looking for tt == 8 (LUA_TTHREAD)
void* FindLuaState(void* base_ptr) {
    if (!base_ptr) return NULL;
    for (int i = 0; i < 0x2000; i += 8) {
        void* ptr = *(void**)((char*)base_ptr + i);
        if ((uintptr_t)ptr > 0x100000000 && (uintptr_t)ptr < 0x8000000000) {
            uint8_t tt = *(uint8_t*)((char*)ptr + 0x2); // lua_State::tt
            void* global = *(void**)((char*)ptr + 0x78); // lua_State::global
            if (tt == 8 && (uintptr_t)global > 0x100000000) {
                return ptr;
            }
        }
    }
    return NULL;
}

bool InjectExecutor(void) {
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
    void* job = NULL;
    void* script_context = NULL;
    
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = *(void**)(ptr);
        if (!j) continue;
        
        uintptr_t str_ptr = *(uintptr_t*)((char*)j + OFFSET_JOB_NAME);
        if (str_ptr > 0x100000000) {
            const char* name = (const char*)str_ptr;
            if (strcmp(name, "WaitingHybridScriptsJob") == 0) {
                job = j;
                script_context = *(void**)((char*)j + OFFSET_JOB_SCRIPT_CTX);
                break;
            }
        }
    }
    
    if (!job) {
        NSLog(@"[Spork] Failed to find WaitingHybridScriptsJob.");
        return false;
    }
    
    // Strategy 1: Scan the Job for lua_State
    g_L = FindLuaState(job);
    if (g_L) {
        NSLog(@"[Spork] Found lua_State via Job scan! %p", g_L);
        g_is_injected = true;
        return true;
    }
    
    // Strategy 2: Scan the ScriptContext for lua_State
    g_L = FindLuaState(script_context);
    if (g_L) {
        NSLog(@"[Spork] Found lua_State via ScriptContext scan! %p", g_L);
        g_is_injected = true;
        return true;
    }
    
    // Strategy 3: Try get_global_state(job)
    get_global_state_t get_gs = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    void* global_state = get_gs(job);
    if (global_state && (uintptr_t)global_state > 0x100000000) {
        void* mainthread = *(void**)((char*)global_state + OFFSET_GS_MAINTHREAD);
        if (mainthread && (uintptr_t)mainthread > 0x100000000) {
            g_L = mainthread;
            NSLog(@"[Spork] Found lua_State via get_global_state(job)! %p", g_L);
            g_is_injected = true;
            return true;
        }
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
