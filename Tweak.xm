#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/mach_vm.h>
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

// Safely read memory without causing EXC_BAD_ACCESS
bool safe_read(void* address, void* buffer, size_t size) {
    vm_size_t out_size;
    kern_return_t kr = mach_vm_read_overwrite(mach_task_self(), (mach_vm_address_t)address, (mach_vm_size_t)size, (mach_vm_address_t)buffer, &out_size);
    return (kr == KERN_SUCCESS && out_size == size);
}

// Crash-proof memory scanner for lua_State
void* FindLuaState(void* base_ptr) {
    if (!base_ptr) return NULL;
    // Scan up to 64KB safely
    for (int i = 0; i < 0x10000; i += 8) {
        void* ptr = NULL;
        if (!safe_read((char*)base_ptr + i, &ptr, 8)) continue;
        
        if ((uintptr_t)ptr > 0x100000000 && (uintptr_t)ptr < 0x8000000000) {
            uint8_t tt = 0;
            if (!safe_read((char*)ptr + 0x2, &tt, 1)) continue;
            
            // LUA_TTHREAD (lua_State) is 9
            if (tt == 9) { 
                void* global_ptr = NULL;
                if (safe_read((char*)ptr + 0x78, &global_ptr, 8)) {
                    if ((uintptr_t)global_ptr > 0x100000000) {
                        return ptr;
                    }
                }
            }
        }
    }
    return NULL;
}

bool InjectExecutor(void) {
    uintptr_t base = (uintptr_t)_dyld_get_image_header(0);
    
    // 1. Find TaskScheduler safely
    void* task_scheduler = NULL;
    if (!safe_read((void*)(base + OFFSET_TASKSCHEDULER), &task_scheduler, 8) || !task_scheduler) {
        NSLog(@"[Spork] Failed to find TaskScheduler.");
        return false;
    }
    
    // 2. Iterate through jobs
    uintptr_t start = 0, end = 0;
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_START, &start, 8);
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_END, &end, 8);
    
    if (!start || !end || end <= start) {
        NSLog(@"[Spork] Invalid job list pointers.");
        return false;
    }

    void* job = NULL;
    void* script_context = NULL;
    
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        
        uintptr_t str_ptr = 0;
        if (!safe_read((char*)j + OFFSET_JOB_NAME, &str_ptr, 8) || str_ptr < 0x100000000) continue;
        
        char name[64] = {0};
        if (safe_read((void*)str_ptr, name, 63)) {
            if (strcmp(name, "WaitingHybridScriptsJob") == 0) {
                job = j;
                safe_read((char*)j + OFFSET_JOB_SCRIPT_CTX, &script_context, 8);
                break;
            }
        }
    }
    
    if (!job) {
        NSLog(@"[Spork] Failed to find WaitingHybridScriptsJob.");
        return false;
    }
    
    // 3. Safely scan for lua_State (No more calling broken offsets!)
    if (script_context) {
        g_L = FindLuaState(script_context);
        if (g_L) {
            NSLog(@"[Spork] Found lua_State in ScriptContext: %p", g_L);
            g_is_injected = true;
            return true;
        }
    }
    
    g_L = FindLuaState(job);
    if (g_L) {
        NSLog(@"[Spork] Found lua_State in Job: %p", g_L);
        g_is_injected = true;
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
