#import <UIKit/UIKit.h>
#import <mach-o/dyld.h>
#import <string.h>
#import <mach/mach.h>
#import <mach/vm_map.h>
#import <signal.h>
#import <setjmp.h>
#import <libkern/OSCacheControl.h>
#import "SporkUI.h"

// --- Offsets for Roblox 2.744.0.1077 (Relative to RobloxLib) ---
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUAU_LOAD          0x44bc110

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

bool g_is_injected = false;
static NSMutableArray<NSString *> *g_scriptQueue = nil;

// Hook Trampoline
static lua_pcall_t orig_lua_pcall = NULL;

// --- Logging System ---
NSMutableArray<NSString *> *g_logs = nil;

void SporkLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (!g_logs) g_logs = [NSMutableArray array];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    NSString *timeStr = [formatter stringFromDate:[NSDate date]];
    NSString *logLine = [NSString stringWithFormat:@"[%@] %@", timeStr, msg];
    [g_logs addObject:logLine];
    NSLog(@"[Spork] %@", msg);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"SporkLogUpdated" object:nil];
    });
}

uintptr_t get_robloxlib_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "RobloxLib")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}

// --- The Safe Mach VM Remap Hook ---
void install_hook(void* target, void* hook) {
    kern_return_t kr;
    mach_vm_address_t page = (mach_vm_address_t)target & ~0xFFF;
    mach_vm_address_t new_page = 0;
    vm_prot_t cur_prot, max_prot;

    // 1. Map a copy of the page
    kr = mach_vm_remap(mach_task_self(), &new_page, 0x1000, 0, VM_FLAGS_ANYWHERE, mach_task_self(), page, false, &cur_prot, &max_prot, VM_INHERIT_NONE);
    if (kr != KERN_SUCCESS) return;

    // 2. Make it writable
    kr = vm_protect(mach_task_self(), new_page, 0x1000, false, VM_PROT_READ | VM_PROT_WRITE);
    
    uintptr_t offset = (uintptr_t)target - page;
    void* new_target = (void*)(new_page + offset);

    // 3. Create trampoline (copy original instructions)
    void* trampoline = mmap(NULL, 4096, PROT_READ | PROT_WRITE | PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    memcpy(trampoline, new_target, 16);
    
    uint32_t* tramp_code = (uint32_t*)((uintptr_t)trampoline + 16);
    tramp_code[0] = 0x58000050; // ldr x16, #8
    tramp_code[1] = 0xD61F0200; // br x16
    *(uint64_t*)((uintptr_t)trampoline + 24) = (uintptr_t)target + 16;

    orig_lua_pcall = (lua_pcall_t)trampoline;

    // 4. Patch the new page with jump to our hook
    uint32_t* target_code = (uint32_t*)new_target;
    target_code[0] = 0x58000050; // ldr x16, #8
    target_code[1] = 0xD61F0200; // br x16
    *(uint64_t*)((uintptr_t)new_target + 8) = (uintptr_t)hook;

    // 5. Change permissions back to RX
    vm_protect(mach_task_self(), new_page, 0x1000, false, VM_PROT_READ | VM_PROT_EXECUTE);
    
    // 6. Remap back over the original location
    mach_vm_address_t dummy = 0;
    mach_vm_remap(mach_task_self(), &dummy, 0x1000, 0, VM_FLAGS_FIXED | VM_FLAGS_OVERWRITE, mach_task_self(), new_page, false, &cur_prot, &max_prot, VM_INHERIT_NONE);
    
    sys_icache_invalidate((void*)page, 0x1000);
}

// --- Hook Function ---
int my_lua_pcall(void* L, int nargs, int nresults, int errfunc) {
    if (g_scriptQueue && g_scriptQueue.count > 0) {
        NSString *script = g_scriptQueue.firstObject;
        [g_scriptQueue removeObjectAtIndex:0];
        
        uintptr_t base = get_robloxlib_base();
        luau_load_t luau_load = (luau_load_t)(base + OFFSET_LUAU_LOAD);
        
        SporkLog(@"Hook triggered! Executing script...");
        const char *source = [script UTF8String];
        
        int status = luau_load(L, "SporkScript", source, strlen(source), 0);
        if (status == 0) {
            orig_lua_pcall(L, 0, 0, 0);
            SporkLog(@"Success: Script executed!");
        } else {
            SporkLog(@"Error: Compile/Load Failed with status %d", status);
        }
    }
    
    // Continue original execution
    return orig_lua_pcall(L, nargs, nresults, errfunc);
}

bool InjectExecutor(void) {
    if (g_logs) [g_logs removeAllObjects];
    SporkLog(@"Starting Injection...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) {
        SporkLog(@"Error: Failed to find RobloxLib base.");
        return false;
    }

    // Install the safe inline hook for lua_pcall
    void* target_pcall = (void*)(base + OFFSET_LUA_PCALL);
    install_hook(target_pcall, (void*)my_lua_pcall);
    
    SporkLog(@"Success: Hooked lua_pcall! Waiting for engine tick...");
    g_is_injected = true;
    return true;
}

void ExecuteLuauSource(const char* source, size_t size) {
    if (!g_is_injected) return;
    if (!g_scriptQueue) g_scriptQueue = [NSMutableArray new];
    
    NSString *script = [NSString stringWithUTF8String:source];
    [g_scriptQueue addObject:script];
    SporkLog(@"Script queued for execution.");
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
        
        g_scriptQueue = [NSMutableArray new];
    });
}
