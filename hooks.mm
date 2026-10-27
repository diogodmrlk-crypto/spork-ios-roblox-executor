#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

typedef void* (*get_scriptcontext_t)();

// Helper to verify if a pointer is a global_State
bool is_global_state(uintptr_t ptr) {
    if (ptr < 0x100000000 || ptr > 0x7FFFFFFFFFFF) return false;
    uintptr_t mt = 0;
    if (!safe_read((void*)(ptr + OFFSET_MAINTHREAD), &mt, 8)) return false;
    if (mt < 0x100000000 || mt > 0x7FFFFFFFFFFF) return false;
    uintptr_t gs_back = 0;
    if (!safe_read((void*)(mt + OFFSET_LUA_STATE_GLOBAL), &gs_back, 8)) return false;
    return gs_back == ptr;
}

void* find_global_state(void* script_context) {
    uintptr_t base = (uintptr_t)script_context;
    // Scan ScriptContext
    for (int i = 0; i < 0x2000; i += 8) {
        uintptr_t ptr = 0;
        if (safe_read((void*)(base + i), &ptr, 8)) {
            if (is_global_state(ptr)) return (void*)ptr;
        }
    }
    // Scan DataModel (parent of ScriptContext)
    void* data_model = NULL;
    if (safe_read((char*)script_context + OFFSET_PARENT, &data_model, 8) && data_model) {
        uintptr_t dm_base = (uintptr_t)data_model;
        for (int i = 0; i < 0x2000; i += 8) {
            uintptr_t ptr = 0;
            if (safe_read((void*)(dm_base + i), &ptr, 8)) {
                if (is_global_state(ptr)) return (void*)ptr;
            }
        }
    }
    return NULL;
}

void SetupHooks(void) {
    uintptr_t base = get_robloxlib_base();
    if (!base) {
        SporkLog(@"Error: RobloxLib not found.");
        return;
    }

    // Get ScriptContext using the safe, reliable offset
    get_scriptcontext_t get_sc = (get_scriptcontext_t)(base + OFFSET_GET_SCRIPTCONTEXT);
    void* script_context = get_sc();
    
    if (!script_context) {
        SporkLog(@"Error: get_scriptcontext returned NULL.");
        return;
    }
    SporkLog(@"Got ScriptContext: %p", script_context);

    // Scan for global_State
    void* global_state = find_global_state(script_context);
    if (global_state) {
        safe_read((char*)global_state + OFFSET_MAINTHREAD, &g_live_L, 8);
        if (g_live_L) {
            SporkLog(@"Success! Found lua_State: %p", g_live_L);
        } else {
            SporkLog(@"Error: mainthread was NULL.");
        }
    } else {
        SporkLog(@"Error: Could not find global_State in ScriptContext or DataModel.");
    }
}
