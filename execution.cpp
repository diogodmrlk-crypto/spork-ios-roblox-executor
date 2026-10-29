// execution.cpp
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"
#include <cstdlib>
#include <cstdio>

#include "lua.h"
#include "luacode.h"

extern "C" void* ExploitThread;

int ExecuteScript(void* L, const std::string& Source) {
    if (!L) return -5;
    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) return -4;

    size_t bcSize = 0;
    char* bc = luau_compile(Source.c_str(), Source.size(), nullptr, &bcSize);
    if (!bc) return -1;

    typedef int (*luau_load_t)(void*, const char*, const char*, size_t, int);
    typedef int (*lua_pcall_t)(void*, int, int, int);
    typedef const char* (*lua_tolstring_t)(void*, int, size_t*);

    auto luau_load     = (luau_load_t)(base + Offsets::Luau::luau_load);
    auto lua_pcall     = (lua_pcall_t)(base + Offsets::Luau::lua_pcall);
    auto lua_tolstring = (lua_tolstring_t)(base + Offsets::Luau::lua_tolstring);

    if (luau_load(L, "=Spork", bc, bcSize, 0) != 0) {
        free(bc);
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) fprintf(stderr, "[Spork] luau_load error: %s\n", err);
        return -2;
    }
    free(bc);

    int result = lua_pcall(L, 0, 0, 0);
    if (result != 0) {
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) fprintf(stderr, "[Spork] luau runtime error: %s\n", err);
    }
    return result;
}
