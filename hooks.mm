#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

// Based on your IDA dump, the function takes 3 arguments and returns lua_State*
typedef void* (*get_global_state_t)(void* sc, int* identity, void** script);

void SetupHooks(void) {
    SporkLog(@"SetupHooks started...");
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

    // Call get_global_state using the exact IDA instructions
    get_global_state_t get_global_state = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    
    // Dummy variables for the function to fill out
    int identity = 0;
    void* script = NULL;
    
    SporkLog(@"Calling get_global_state(SC, &identity, &script)...");
    
    // Call with 3 arguments!
    void* live_L = get_global_state(script_context, &identity, &script);
    
    if (live_L) {
        g_live_L = live_L;
        SporkLog(@"SUCCESS! lua_State: %p", g_live_L);
    } else {
        SporkLog(@"get_global_state returned NULL");
    }
}
