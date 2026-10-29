// hooks.mm
#import <Foundation/Foundation.h>
#include "hooks.hpp"
#include "exploit.hpp"
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"

typedef uint64_t (*gc_step_t)(void*, int);
static gc_step_t g_orig_gc_step = nullptr;

static uint64_t HookedGcStep(void* L, int idx) {
    // Se por algum motivo o HookedLuauLoad não pegou, pegamos no gc_step
    if (!ExploitThread && L) {
        typedef void* (*lua_newthread_t)(void*);
        auto lua_newthread = (lua_newthread_t)(memory::GetRobloxLibBase() + Offsets::Luau::lua_newthread);
        ExploitThread = lua_newthread(L);
        NSLog(@"[Spork] captured lua_State via gc_step: %p", ExploitThread);
    }

    if (ExploitThread && !ExecutionRequests.empty()) {
        std::string script = ExecutionRequests.front();
        ExecutionRequests.erase(ExecutionRequests.begin());
        ExecuteScript(ExploitThread, script);
    }
    return g_orig_gc_step(L, idx);
}

void SetupExecution(void* L) {
    (void)L;
    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) return;

    uintptr_t gcStepAddr = base + Offsets::Luau::gc_step;
    
    extern void* DobbyHook(void* address, void* replace, void** origin);
    void* orig = nullptr;
    DobbyHook((void*)gcStepAddr, (void*)HookedGcStep, &orig);
    g_orig_gc_step = (gc_step_t)orig;

    if (g_orig_gc_step) NSLog(@"[Spork] gc_step hooked");
}
