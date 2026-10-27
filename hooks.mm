#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <CydiaSubstrate.h>
#import <Foundation/Foundation.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

typedef int (*lua_gettop_t)(void* L);
static lua_gettop_t orig_lua_gettop = NULL;

// We intercept every lua_gettop call to steal the lua_State
int my_lua_gettop(void* L) {
    if (!g_live_L && L) {
        // Verify it's a real lua_State by checking its global pointer
        uintptr_t global_ptr = 0;
        if (safe_read((char*)L + OFFSET_LUA_STATE_GLOBAL, &global_ptr, 8) && global_ptr > 0x100000000) {
            g_live_L = L;
            SporkLog(@"STOLE lua_State via lua_gettop: %p", L);
        }
    }
    return orig_lua_gettop(L);
}

void SetupHooks(void) {
    SporkLog(@"SetupHooks started...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) { SporkLog(@"Base null"); return; }

    // Hook lua_gettop
    void* target_gettop = (void*)(base + OFFSET_LUA_GETTOP);
    MSHookFunction(target_gettop, (void*)my_lua_gettop, (void**)&orig_lua_gettop);
    
    SporkLog(@"Hooked lua_gettop at %p. Waiting for game to call it...", target_gettop);
}
