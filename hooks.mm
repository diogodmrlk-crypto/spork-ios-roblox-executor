// hooks.mm
#import <Foundation/Foundation.h>
#include "hooks.hpp"
#include "exploit.hpp"
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"

// ============================================================
// Ponteiro original do gc_step (preenchido pelo Dobby)
// Assinatura: uint64_t(lua_State* L, int idx)
// ============================================================
typedef uint64_t (*gc_step_t)(void*, int);
static gc_step_t g_orig_gc_step = nullptr;

// ============================================================
// HookedGcStep: dispara a cada tick do interpretador.
// É o ponto seguro para tocar no lua_State — sempre roda na vm thread.
// ============================================================
static uint64_t HookedGcStep(void* L, int idx) {
    if (ExploitThread && !ExecutionRequests.empty()) {
        std::string script = ExecutionRequests.front();
        ExecutionRequests.erase(ExecutionRequests.begin());

        int r = ExecuteScript(ExploitThread, script);
        NSLog(@"[Spork] executed script, result=%d", r);
    }
    return g_orig_gc_step(L, idx);
}

// ============================================================
// SetupExecution: hooka gc_step
// ============================================================
void SetupExecution(void* L) {
    (void)L; // não usado; usamos ExploitThread (capturado no HookedLuauLoad)

    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) {
        NSLog(@"[Spork] SetupExecution: RobloxLib not found");
        return;
    }

    uintptr_t gcStepAddr = base + Offsets::Luau::gc_step;
    NSLog(@"[Spork] gc_step @ 0x%lx", gcStepAddr);

    extern void* DobbyHook(void* address, void* replace, void** origin);
    void* orig = nullptr;
    DobbyHook((void*)gcStepAddr, (void*)HookedGcStep, &orig);
    g_orig_gc_step = (gc_step_t)orig;

    if (!g_orig_gc_step) {
        NSLog(@"[Spork] DobbyHook failed for gc_step");
        return;
    }
    NSLog(@"[Spork] gc_step hooked");
}
