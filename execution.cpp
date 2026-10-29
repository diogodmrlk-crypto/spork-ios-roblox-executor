// execution.cpp
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"
#include <cstdlib>
#include <cstdio>

// luau_compile vem do Luau upstream (linkado no tweak)
extern "C" {
#include "luacode.h"
}

// ExploitThread é void* no exploit.hpp
extern "C" void* ExploitThread;

int ExecuteScript(void* L, const std::string& Source) {
    if (!L) return -5;

    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) return -4;

    // ---- 1. Compila com o Luau upstream ----
    // O compilador do Roblox não está exposto; loadstring só deserializa
    // bytecode em cache. O upstream emite versão 9, dentro da janela
    // [3..14] que o luau_load do Roblox aceita.
    size_t bcSize = 0;
    char* bc = luau_compile(Source.c_str(), Source.size(), nullptr, &bcSize);
    if (!bc) {
        NSLog(@"[Spork] luau_compile failed");
        return -1;
    }

    // ---- 2. Resolve as funções do RobloxLib por RVA ----
    typedef int (*luau_load_t)(void*, const char*, const char*, size_t, int);
    typedef int (*lua_pcall_t)(void*, int, int, int);
    typedef const char* (*lua_tolstring_t)(void*, int, size_t*);

    auto luau_load    = (luau_load_t)(base + Offsets::Luau::luau_load);
    auto lua_pcall    = (lua_pcall_t)(base + Offsets::Luau::lua_pcall);
    auto lua_tolstring = (lua_tolstring_t)(base + Offsets::Luau::lua_tolstring);

    // ---- 3. Carrega o bytecode na thread ----
    if (luau_load(L, "=Spork", bc, bcSize, 0) != 0) {
        free(bc);
        // O erro está na stack; tenta ler
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) NSLog(@"[Spork] luau_load error: %s", err);
        return -2;
    }
    free(bc);

    // ---- 4. Executa ----
    int result = lua_pcall(L, 0, 0, 0);
    if (result != 0) {
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) NSLog(@"[Spork] luau runtime error: %s", err);
    }
    return result;
}
