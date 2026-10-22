// Executor.mm
#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include "Executor.hpp"
#include "offsets.h"

static luau_load_t luau_load = nullptr;
static lua_pcall_t lua_pcall = nullptr;
static lua_newthread_t lua_newthread = nullptr;
static lua_tolstring_t lua_tolstring = nullptr;
static structures::lua_State* g_luaState = nullptr;

// Helper to get the base address of RobloxLib
uintptr_t getRobloxLibBase() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxLib")) {
            return _dyld_get_image_vmaddr_slide(i);
        }
    }
    return 0;
}

void SporkExecutor::Initialize() {
    uintptr_t base = getRobloxLibBase();
    if (!base) return;
    
    // Resolve functions using the exact offsets from your dump
    luau_load = (luau_load_t)(base + offsets::luau::luau_load);
    lua_pcall = (lua_pcall_t)(base + offsets::luau::lua_pcall);
    lua_newthread = (lua_newthread_t)(base + offsets::luau::lua_newthread);
    lua_tolstring = (lua_tolstring_t)(base + offsets::luau::lua_tolstring);
    
    NSLog(@"[Spork] Luau VM Resolved. load: %p, pcall: %p", luau_load, lua_pcall);
}

// You will need to call this from your GC Step Hook or when the game loads a chunk
void CaptureLuaState(structures::lua_State* L) {
    if (!g_luaState) {
        g_luaState = L;
        NSLog(@"[Spork] Captured lua_State: %p", L);
    }
}

bool SporkExecutor::ExecuteScript(const std::string& source) {
    // NOTE: You MUST implement the Luau compiler here!
    // luau_load ONLY accepts compiled bytecode, not source code.
    // std::string bytecode = compileLuau(source); 
    
    // For testing purposes, if you just want to test the UI connection without compiling:
    if (!g_luaState) return false;
    if (!luau_load || !lua_pcall) return false;

    NSLog(@"[Spork] Attempting execution...");
    
    // Create a clean thread to prevent corrupting the game's stack
    structures::lua_State* T = lua_newthread(g_luaState);
    
    // WARNING: This will fail with "bytecode version mismatch" if you pass raw source
    // You must pass actual bytecode here!
    // int loadStatus = luau_load(T, "@Spork", bytecode.c_str(), bytecode.size(), 0);
    
    // Simulating a load for UI testing:
    // int loadStatus = luau_load(T, "@Spork", source.c_str(), source.size(), 0);
    
    // if (loadStatus == 0) {
    //     int pcallStatus = lua_pcall(T, 0, 0, 0);
    //     if (pcallStatus != 0) {
    //         size_t len;
    //         const char* err = lua_tolstring(T, -1, &len);
    //         NSLog(@"[Spork] Error: %s", err);
    //     }
    // }
    
    return true;
}
