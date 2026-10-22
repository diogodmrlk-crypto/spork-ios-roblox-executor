#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include "Executor.hpp"
#include "offsets.h"
#include "Luau/Compiler.h"

static int (*orig_luau_load)(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env) = nullptr;
static int (*lua_pcall)(structures::lua_State* L, int nargs, int nresults, int errfunc) = nullptr;
static structures::lua_State* (*lua_newthread)(structures::lua_State* L) = nullptr;
static const char* (*lua_tolstring)(structures::lua_State* L, int idx, size_t* len) = nullptr;
static structures::RobloxExtraSpace* (*get_extra_space)(structures::lua_State* L) = nullptr;

static structures::lua_State* g_luaState = nullptr;
static std::string g_queuedScript = "";
static std::mutex g_queueMutex;

// Corrected to return the Mach-O header base address (not the ASLR slide)
uintptr_t getRobloxLibBase() {
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char* name = _dyld_get_image_name(i);
        if (strstr(name, "RobloxLib")) {
            return (uintptr_t)_dyld_get_image_header(i);
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
    NSLog(@"[Spork] Found RobloxLib base at %p", (void*)base);
    
    orig_luau_load = (decltype(orig_luau_load))(base + offsets::luau::luau_load);
    lua_pcall = (decltype(lua_pcall))(base + offsets::luau::lua_pcall);
    lua_newthread = (decltype(lua_newthread))(base + offsets::luau::lua_newthread);
    lua_tolstring = (decltype(lua_tolstring))(base + offsets::luau::lua_tolstring);
    get_extra_space = (decltype(get_extra_space))(base + offsets::roblox::get_extra_space);
}

void SporkExecutor::CaptureLuaState(structures::lua_State* L) {
    if (!g_luaState && L) {
        g_luaState = L;
        NSLog(@"[Spork] Captured Lua State!");
    }
}

bool SporkExecutor::QueueScript(const std::string& source) {
    if (!g_luaState) return false;
    std::lock_guard<std::mutex> lock(g_queueMutex);
    g_queuedScript = source;
    return true;
}

void SetThreadIdentity(structures::lua_State* L, uint64_t identity) {
    if (!get_extra_space) return;
    structures::RobloxExtraSpace* extra = get_extra_space(L);
    if (extra) {
        extra->capabilities = identity; 
    }
}

void SporkExecutor::ProcessQueue() {
    std::lock_guard<std::mutex> lock(g_queueMutex);
    if (g_queuedScript.empty() || !g_luaState) return;
    
    std::string scriptToRun = g_queuedScript;
    g_queuedScript = ""; 
    
    structures::lua_State* T = lua_newthread(g_luaState);
    SetThreadIdentity(T, 7);
    
    std::string bytecode = Luau::compile(scriptToRun);
    
    if (bytecode.empty()) {
        NSLog(@"[Spork] Compilation failed.");
        return;
    }
    
    int loadStatus = orig_luau_load(T, "@Spork", bytecode.c_str(), bytecode.size(), 0);
    
    if (loadStatus == 0) {
        int pcallStatus = lua_pcall(T, 0, 0, 0);
        if (pcallStatus != 0) {
            size_t len;
            const char* err = lua_tolstring(T, -1, &len);
            NSLog(@"[Spork] Execution Error: %s", err);
        } else {
            NSLog(@"[Spork] Execution Successful!");
        }
    } else {
        NSLog(@"[Spork] Failed to load bytecode (Status: %d).", loadStatus);
    }
}
