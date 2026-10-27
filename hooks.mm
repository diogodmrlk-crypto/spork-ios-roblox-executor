#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>
#include <mach/vm_map.h>
#include <string.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

// We write our own C version of lua_gettop. 
// This avoids needing a complex assembly trampoline to jump back to the original function.
int my_lua_gettop(void* L) {
    if (!g_live_L && L) {
        g_live_L = L;
        SporkLog(@"STOLE lua_State via lua_gettop: %p", L);
    }
    
    // Manually implement lua_gettop logic using your dumped offsets
    uintptr_t top = 0, base = 0;
    safe_read((char*)L + 0x70, &top, 8);  // OFFSET_LUA_STATE_TOP
    safe_read((char*)L + 0x58, &base, 8); // OFFSET_LUA_STATE_BASE
    
    // TValue stride is 0x10
    return (int)((top - base) / 16);
}

void SetupHooks(void) {
    SporkLog(@"SetupHooks started...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) { SporkLog(@"Base null"); return; }

    void* target = (void*)(base + OFFSET_LUA_GETTOP);
    if (!target) return;

    // Construct the ARM64 jump instruction:
    // ldr x16, #8  (0x58000050)
    // br x16       (0xD61F0200)
    // <8 bytes address of my_lua_gettop>
    uint64_t my_func_addr = (uint64_t)my_lua_gettop;
    uint32_t patch[4];
    patch[0] = 0x58000050; 
    patch[1] = 0xD61F0200; 
    patch[2] = (uint32_t)(my_func_addr & 0xFFFFFFFF);
    patch[3] = (uint32_t)(my_func_addr >> 32);
    
    // Make the memory page writable and executable
    uintptr_t page = (uintptr_t)target & ~0xFFF;
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)page, 0x4000, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    
    if (kr != KERN_SUCCESS) {
        SporkLog(@"vm_protect failed: %d. (Are entitlements missing?)", kr);
        return;
    }
    
    // Overwrite the first 16 bytes with our jump
    memcpy(target, patch, 16);
    
    // Restore execution protection (remove write access)
    vm_protect(mach_task_self(), (vm_address_t)page, 0x4000, false, VM_PROT_READ | VM_PROT_EXECUTE);
    
    SporkLog(@"Successfully patched lua_gettop at %p", target);
}
