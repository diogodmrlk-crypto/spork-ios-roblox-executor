#pragma once
#include <stdint.h>

// ==========================================
// OFFSETS (Roblox 2.744.0.1077)
// ==========================================
// ATENÇÃO: Verifique se esses offsets estão atualizados para a versão atual do Roblox.
// Se o Roblox atualizar, os offsets podem mudar. Use um dumper para atualizá-los.

// ------------------------------------------
// TASK SCHEDULER (Jobs)
// ------------------------------------------
// Offset para o TaskScheduler no RobloxLib
#define OFFSET_TASKSCHEDULER      0x6a6d7c0
// Offset para o início da lista de jobs no TaskScheduler
#define OFFSET_TS_JOBS_START      0xd0
// Offset para o fim da lista de jobs no TaskScheduler
#define OFFSET_TS_JOBS_END        0xd8
// Offset para o contexto do script no job
#define OFFSET_JOB_SCRIPT_CTX     0x1b0

// ------------------------------------------
// GLOBAL STATE
// ------------------------------------------
// Offset para a função GetGlobalState
#define OFFSET_GET_GLOBAL_STATE   0x19ce768

// ------------------------------------------
// LUA FUNCTIONS
// ------------------------------------------
// Offset para a função lua_gettop (usada para capturar o lua_State)
#define OFFSET_LUA_GETTOP         0x448e048
// Offset para a função luau_load (compilação de script Lua -> Luau Bytecode)
#define OFFSET_LUAU_LOAD          0x44bc110
// Offset para a função lua_pcall (execução protegida de scripts)
#define OFFSET_LUA_PCALL          0x4490fec
// Offset para a função lua_newthread (criação de uma thread Lua separada)
#define OFFSET_LUA_NEWTHREAD      0x448df3c
// Offset para a função luaL_sandboxthread (aplicação de sandbox na thread Lua)
#define OFFSET_LUAL_SANDBOXTHREAD 0x1a12ad4

// ------------------------------------------
// STRUCTURES (lua_State)
// ------------------------------------------
// Offset para o ponteiro de parent na struct lua_State
#define OFFSET_PARENT             0x60
// Offset para a thread principal na struct lua_State
#define OFFSET_MAINTHREAD         0x1a0
// Offset para o estado global na struct lua_State
#define OFFSET_LUA_STATE_GLOBAL   0x78
// Offset para o tipo de thread na struct lua_State
#define OFFSET_LUA_STATE_TT       0x2
// Offset para o topo da stack na struct lua_State (necessário para my_lua_gettop)
#define OFFSET_LUA_STATE_TOP      0x70
// Offset para a base da stack na struct lua_State (necessário para my_lua_gettop)
#define OFFSET_LUA_STATE_BASE     0x58

// ------------------------------------------
// MACROS
// ------------------------------------------
// Remove Pointer Authentication (PAC) de um ponteiro no iOS
// PAC adiciona bits de autenticação aos ponteiros, que precisam ser removidos para operações de memória
#define STRIP_PAC(ptr) ((uintptr_t)(ptr) & 0x0000000FFFFFFFFF)
