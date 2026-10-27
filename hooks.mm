#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

typedef void* (*get_global_state_t)(void* sc);

void SetupHooks(void) {
    uintptr_t base = get_robloxlib_base();
    if (!base) {
        SporkLog(@"Error: RobloxLib not found.");
        return;
    }

    void* task_scheduler = NULL;
    if (!safe_read((void*)(base + OFFSET_TASKSCHEDULER), &task_scheduler, 8) || !task_scheduler) {
        SporkLog(@"Error: TaskScheduler not found.");
        return;
    }
    task_scheduler = (void*)STRIP_PAC(task_scheduler);

    uintptr_t start = 0, end = 0;
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_START, &start, 8);
    safe_read((char*)task_scheduler + OFFSET_TS_JOBS_END, &end, 8);
    start = STRIP_PAC(start);
    end = STRIP_PAC(end);

    if (!start || !end || end <= start) {
        SporkLog(@"Error: Invalid job list.");
        return;
    }

    void* script_context = NULL;
    for (uintptr_t ptr = start; ptr < end; ptr += 0x10) {
        void* j = NULL;
        if (!safe_read((void*)ptr, &j, 8) || !j) continue;
        uintptr_t stripped_j = STRIP_PAC(j);
        if (safe_read((char*)stripped_j + OFFSET_JOB_SCRIPT_CTX, &script_context, 8) && script_context) {
            break;
        }
    }

    if (!script_context) {
        SporkLog(@"Error: ScriptContext not found.");
        return;
    }

    // Call get_global_state using your exact offset
    get_global_state_t get_global_state = (get_global_state_t)(base + OFFSET_GET_GLOBAL_STATE);
    void* global_state = get_global_state(script_context);

    if (global_state) {
        safe_read((char*)global_state + OFFSET_MAINTHREAD, &g_live_L, 8);
        if (g_live_L) {
            SporkLog(@"Success! Found lua_State: %p", g_live_L);
        } else {
            SporkLog(@"Error: mainthread was NULL.");
        }
    } else {
        SporkLog(@"Error: get_global_state returned NULL.");
    }
}
