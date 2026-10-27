#pragma once
#include <stdint.h>

// ==========================================
// OFFSETS (Roblox 2.744.0.1077)
// ==========================================
#define OFFSET_LUA_GETTOP         0x448e048
#define OFFSET_LUAU_LOAD          0x44bc110
#define OFFSET_LUA_PCALL          0x4490fec
#define OFFSET_LUA_NEWTHREAD      0x448df3c
#define OFFSET_LUAL_SANDBOXTHREAD 0x1a12ad4

#define OFFSET_TASKSCHEDULER      0x6a6d7c0
#define OFFSET_TS_JOBS_START      0xd0
#define OFFSET_TS_JOBS_END        0xd8
#define OFFSET_JOB_SCRIPT_CTX     0x1b0
#define OFFSET_GET_GLOBAL_STATE   0x19ce768
#define OFFSET_MAINTHREAD         0x1a0

// Structures
#define OFFSET_LUA_STATE_GLOBAL   0x78
#define OFFSET_LUA_STATE_TT       0x2

// Macros
#define STRIP_PAC(ptr) ((uintptr_t)(ptr) & 0x0000000FFFFFFFFF)
