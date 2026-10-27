#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>
#include <signal.h>
#include <setjmp.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

// The function takes 3 arguments based on your IDA notes
typedef void* (*get_global_state_t)(void* sc, int* identity, void** script);

// Crash Handler variables
static sigjmp_buf jump_buffer;
static volatile sig_atomic_t in_get_global_state = 0;

void crash_handler(int sig) {
    if (in_get_global_state) {
        siglongjmp(jump_buffer, sig);
    }
}

// Fallback scanner just in case the offset is bad
void* find_global_state(void* script_context) {
    uintptr_t base = (uintptr_t)script_context;
    for (int i = 0; i < 0x4000; i += 8) {
        uintptr_t ptr = 0;
        if (safe_read((void*)(base + i), &ptr, 8)) {
            if (ptr < 0x100000000 || ptr > 0x7FFFFFFFFFFF) continue;
            uintptr_t mt = 0;
            if (safe_read((void*)(ptr + OFFSET_MAINTHREAD), &mt, 8)) {
                if (mt < 0x100000000 || mt > 0x7FFFFFFFFFFF) continue;
                uintptr_t gs_back = 0;
                if (safe_read((void*)(mt + OFFSET_LUA_STATE_GLOBAL), &gs_back, 8) && gs_back == ptr) {
                    return (void*)mt;
                }
            }
        }
    }
    return NULL;
}

void SetupHooks(void) {
    SporkLog(@"SetupHooks started...");
    
    // Install crash handler
    signal(SIGSEGV, crash_handler);
    signal(SIGBUS, crash_handler);
    
    uintptr_t base = get_robloxlib_base();
    if (!base) { SporkLog(@"Base null"); return; }

    void* task_scheduler = NULL;
    if (!safe_read((void*)(base + OFFSET_TASKSCHEDULER), &task_scheduler, 8)) { SporkLog(@"Read TS failed"); return; }
    task_scheduler = (void*)STRIP_PAC(task_scheduler);

    uintptr_t start = 0, end = 0;
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_START, &start, 8);
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_END, &end, 8);
    start = STRIP_PAC(start);
    end = STRIP_PAC(end);

    SporkLog(@"Scanning Jobs: %p to %p", start, end);
    
    void* script_context = NULL;
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        uintptr_t stripped_j = STRIP_PAC(j);
        if (safe_read((char*)stripped_j + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            break;
        }
    }

    if (!script_context) { SporkLog(@"No SC found"); return; }
    SporkLog(@"Found SC: %p", script_context);

    // --- Attempt 1: Call get_global_state safely ---
    get_global_state_t get_global_state = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    int identity = 0;
    void* script = NULL;
    
    SporkLog(@"Calling get_global_state (Safe Mode)...");
    
    in_get_global_state = 1;
    int sig = sigsetjmp(jump_buffer, 1);
    
    if (sig == 0) {
        void* live_L = get_global_state(script_context, &identity, &script);
        if (live_L) {
            g_live_L = live_L;
            SporkLog(@"SUCCESS! lua_State: %p", g_live_L);
            in_get_global_state = 0;
            return;
        }
    } else {
        SporkLog(@"CAUGHT CRASH: get_global_state offset is wrong (Signal %d)", sig);
    }
    in_get_global_state = 0;

    // --- Attempt 2: Fallback memory scanner ---
    SporkLog(@"Falling back to memory scanner...");
    void* fallback_L = find_global_state(script_context);
    if (fallback_L) {
        g_live_L = fallback_L;
        SporkLog(@"SUCCESS via Scanner! lua_State: %p", g_live_L);
    } else {
        SporkLog(@"Failed to find lua_State using all methods.");
    }
}
