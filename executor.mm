#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include "Executor.hpp"
#include "offsets.h"

static int (*orig_luau_load)(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env) = nullptr;
static int (*lua_pcall)(structures::lua_State* L, int nargs, int nresults, int errfunc) = nullptr;
static structures::lua_State* (*lua_newthread)(structures::lua_State* L) = nullptr;
static const char* (*lua_tolstring)(structures::lua_State* L, int idx, size_t* len) = nullptr;

static structures::lua_State* g_luaState = nullptr;
static std::string g_queuedScript = "";

// Resolves the base address of RobloxLib dynamically
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
    if (!base) {
        NSLog(@"[Spork] Failed to find RobloxLib base.");
        return;
    }
    
    // Resolve functions using your provided exact offsets
    orig_luau_load = (decltype(orig_luau_load))(base + offsets::luau::luau_load);
    lua_pcall = (decltype(lua_pcall))(base + offsets::luau::lua_pcall);
    lua_newthread = (decltype(lua_newthread))(base + offsets::luau::lua_newthread);
    lua_tolstring = (decltype(lua_tolstring))(base + offsets::luau::lua_tolstring);
    
    NSLog(@"[Spork] VM Resolved. Load: %p, Pcall: %p", orig_luau_load, lua_pcall);
}

void SporkExecutor::CaptureLuaState(structures::lua_State* L) {
    if (!g_luaState && L) {
        g_luaState = L;
        NSLog(@"[Spork] Captured valid lua_State: %p", L);
    }
}

// Placeholder for the Luau Compiler. 
// You MUST link the Luau static library here to convert source to bytecode!
std::string compileLuau(const std::string& source) {
    // To fix this: Clone Luau repo, compile it to .a, link in Makefile, and call luau_compile()
    // For now, we return the raw source which will fail with "bytecode version mismatch"
    return source; 
}

bool SporkExecutor::QueueScript(const std::string& source) {
    if (!g_luaState) {
        NSLog(@"[Spork] Cannot queue script. No lua_State captured yet.");
        return false;
    }
    g_queuedScript = source;
    return true;
}

// This function gets called from the Tweak.xm hook on the game's VM thread
void SporkExecutor::ProcessQueue() {
    if (g_queuedScript.empty() || !g_luaState) return;
    
    std::string scriptToRun = g_queuedScript;
    g_queuedScript = ""; // Clear queue immediately
    
    NSLog(@"[Spork] Executing script on VM thread...");
    
    // Compile the script (Requires Luau Compiler!)
    std::string bytecode = compileLuau(scriptToRun);
    
    // Create a clean thread to prevent corrupting the game's stack
    structures::lua_State* T = lua_newthread(g_luaState);
    
    // Load the bytecode
    int loadStatus = orig_luau_load(T, "@Spork", bytecode.c_str(), bytecode.size(), 0);
    
    if (loadStatus == 0) {
        // Call the script
        int pcallStatus = lua_pcall(T, 0, 0, 0);
        if (pcallStatus != 0) {
            size_t len;
            const char* err = lua_tolstring(T, -1, &len);
            NSLog(@"[Spork] Execution Error: %s", err);
        } else {
            NSLog(@"[Spork] Execution Successful!");
        }
    } else {
        NSLog(@"[Spork] Failed to load bytecode (Status: %d). Did you compile it?", loadStatus);
    }
}
