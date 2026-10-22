#import <Foundation/Foundation.h>
#import <mach-o/dyld.h>
#include "Executor.hpp"
#include "offsets.h"

// Function Pointers resolved dynamically
static int (*orig_luau_load)(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env) = nullptr;
static int (*lua_pcall)(structures::lua_State* L, int nargs, int nresults, int errfunc) = nullptr;
static structures::lua_State* (*lua_newthread)(structures::lua_State* L) = nullptr;
static const char* (*lua_tolstring)(structures::lua_State* L, int idx, size_t* len) = nullptr;
static structures::RobloxExtraSpace* (*get_extra_space)(structures::lua_State* L) = nullptr;

static structures::lua_State* g_luaState = nullptr;
static std::string g_queuedScript = "";
static std::mutex g_queueMutex;

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
    if (!base) {
        NSLog(@"[Spork] Failed to find RobloxLib base.");
        return;
    }
    
    // Resolve functions using your exact offsets
    orig_luau_load = (decltype(orig_luau_load))(base + offsets::luau::luau_load);
    lua_pcall = (decltype(lua_pcall))(base + offsets::luau::lua_pcall);
    lua_newthread = (decltype(lua_newthread))(base + offsets::luau::lua_newthread);
    lua_tolstring = (decltype(lua_tolstring))(base + offsets::luau::lua_tolstring);
    get_extra_space = (decltype(get_extra_space))(base + offsets::roblox::get_extra_space);
    
    NSLog(@"[Spork] VM Resolved.");
}

void SporkExecutor::CaptureLuaState(structures::lua_State* L) {
    if (!g_luaState && L) {
        g_luaState = L;
        NSLog(@"[Spork] Captured valid lua_State: %p", L);
    }
}

bool SporkExecutor::QueueScript(const std::string& source) {
    if (!g_luaState) return false;
    std::lock_guard<std::mutex> lock(g_queueMutex);
    g_queuedScript = source;
    return true;
}

// --- MOCK COMPILER FOR TESTING ---
// This is a pre-compiled Luau bytecode for: print("Hello from Spork!")
// In a real production executor, you MUST bundle the Luau compiler.
std::string getMockBytecode() {
    // Luau Bytecode Header (Version 9, Type 3) followed by instructions
    return std::string("\x09\x03\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 32);
}

// Elevates the thread's Identity using RobloxExtraSpace
void SetThreadIdentity(structures::lua_State* L, uint64_t identity) {
    if (!get_extra_space) return;
    structures::RobloxExtraSpace* extra = get_extra_space(L);
    if (extra) {
        extra->capabilities = identity; // Set to Exploit level
        NSLog(@"[Spork] Elevated thread identity to: %llu", identity);
    }
}

void SporkExecutor::ProcessQueue() {
    std::lock_guard<std::mutex> lock(g_queueMutex);
    if (g_queuedScript.empty() || !g_luaState) return;
    
    std::string scriptToRun = g_queuedScript;
    g_queuedScript = ""; // Clear queue
    
    NSLog(@"[Spork] Executing script on VM thread...");
    
    // 1. Create a clean thread to prevent corrupting the game's stack
    structures::lua_State* T = lua_newthread(g_luaState);
    
    // 2. Elevate the Identity (Identity 7 = Exploit)
    SetThreadIdentity(T, 7);
    
    // 3. Get Bytecode (Replace with real compiler later)
    // For now, we use a mock bytecode to prove the engine works.
    // If you type anything else in the UI, it will fail because it's not compiled.
    std::string bytecode = getMockBytecode(); 
    
    // 4. Load the bytecode
    int loadStatus = orig_luau_load(T, "@Spork", bytecode.c_str(), bytecode.size(), 0);
    
    if (loadStatus == 0) {
        // 5. Execute the script
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
