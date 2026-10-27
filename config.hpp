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

// Safe function to get ScriptContext (Not a fallback)
#define OFFSET_GET_SCRIPTCONTEXT  0x19cc48c

// Structures
#define OFFSET_PARENT             0x60
#define OFFSET_MAINTHREAD         0x1a0
#define OFFSET_LUA_STATE_GLOBAL   0x78
#define OFFSET_LUA_STATE_TT       0x2

// Macros
#define STRIP_PAC(ptr) ((uintptr_t)(ptr) & 0x0000000FFFFFFFFF)
