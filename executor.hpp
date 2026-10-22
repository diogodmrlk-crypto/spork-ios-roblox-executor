// Executor.hpp
#pragma once
#include <cstdint>
#include <string>

// Bring in the structures
#include "structs.h"

// Define the function pointers
typedef int (*luau_load_t)(structures::lua_State* L, const char* chunkname, const char* data, size_t size, int env);
typedef int (*lua_pcall_t)(structures::lua_State* L, int nargs, int nresults, int errfunc);
typedef structures::lua_State* (*lua_newthread_t)(structures::lua_State* L);
typedef const char* (*lua_tolstring_t)(structures::lua_State* L, int idx, size_t* len);

class SporkExecutor {
public:
    static void Initialize();
    static bool ExecuteScript(const std::string& source);
};
