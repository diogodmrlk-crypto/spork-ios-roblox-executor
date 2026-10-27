#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

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
    for (int i = 0; i < 0x4000; i += 8) {
        uintptr_t ptr = 0;
        if (safe_read((void*)(base + i), &ptr, 8)) {
            if (is_global_state(ptr)) {
                SporkLog(@"Found global_state in SC at +0x%X", i);
                return (void*)ptr;
            }
        }
    }
    
    void* parent = NULL;
    if (safe_read((char*)script_context + OFFSET_PARENT, &parent, 8) && parent) {
        SporkLog(@"Scanning parent DataModel: %p", parent);
        uintptr_t dm_base = (uintptr_t)parent;
        for (int i = 0; i < 0x4000; i += 8) {
            uintptr_t ptr = 0;
            if (safe_read((void*)(dm_base + i), &ptr, 8)) {
                if (is_global_state(ptr)) {
                    SporkLog(@"Found global_state in DM at +0x%X", i);
                    return (void*)ptr;
                }
            }
        }
    }
    return NULL;
}

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

    void* global_state = find_global_state(script_context);
    if (global_state) {
        safe_read((char*)global_state + OFFSET_MAINTHREAD, &g_live_L, 8);
        if (g_live_L) {
            SporkLog(@"SUCCESS! lua_State: %p", g_live_L);
        } else {
            SporkLog(@"Mainthread null");
        }
    } else {
        SporkLog(@"Could not find global_state.");
    }
}
