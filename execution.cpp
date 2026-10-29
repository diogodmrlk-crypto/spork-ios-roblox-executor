// execution.cpp
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"
#include <cstdlib>
#include <cstdio>

// Os headers do Luau NÃO devem ficar dentro de extern "C" 
// porque eles já têm o próprio extern "C" interno.
#include "lua.h"
#include "luacode.h"

extern "C" void* ExploitThread;

int ExecuteScript(void* L, const std::string& Source) {
    if (!L) {
        fprintf(stderr, "[Spork] ERRO: g_live_L is NULL. Pressione Inject e aguarde.\n");
        return -5;
    }

    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) {
        fprintf(stderr, "[Spork] ERRO: RobloxLib não encontrada na memória.\n");
        return -4;
    }

    // ---- 1. Compila com o Luau upstream ----
    // O compilador do Roblox não está exposto; o upstream emite versão 9, 
    // que está dentro da janela [3..14] que o luau_load aceita.
    size_t bcSize = 0;
    char* bc = luau_compile(Source.c_str(), Source.size(), nullptr, &bcSize);
    if (!bc) {
        fprintf(stderr, "[Spork] ERRO: luau_compile falhou.\n");
        return -1;
    }

    // ---- 2. Resolve as funções do RobloxLib por RVA ----
    typedef int (*luau_load_t)(void*, const char*, const char*, size_t, int);
    typedef int (*lua_pcall_t)(void*, int, int, int);
    typedef const char* (*lua_tolstring_t)(void*, int, size_t*);

    auto luau_load     = (luau_load_t)(base + Offsets::Luau::luau_load);
    auto lua_pcall     = (lua_pcall_t)(base + Offsets::Luau::lua_pcall);
    auto lua_tolstring = (lua_tolstring_t)(base + Offsets::Luau::lua_tolstring);

    // ---- 3. Carrega o bytecode na thread ----
    if (luau_load(L, "=Spork", bc, bcSize, 0) != 0) {
        free(bc);
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) fprintf(stderr, "[Spork] luau_load error: %s\n", err);
        return -2;
    }
    free(bc);

    // ---- 4. Executa ----
    int result = lua_pcall(L, 0, 0, 0);
    if (result != 0) {
        size_t len = 0;
        const char* err = lua_tolstring(L, -1, &len);
        if (err) fprintf(stderr, "[Spork] luau runtime error: %s\n", err);
    }
    
    return result;
}
