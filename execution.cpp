// execution.cpp
#include "execution.hpp"
#include "config.hpp"
#include "memory.hpp"
#include <cstdlib>
#include <cstdio>

#include "lua.h"
#include "luacode.h" // Pode manter, mas não vamos usar o compile

extern "C" void* ExploitThread;

int ExecuteScript(void* L, const std::string& Source) {
    if (!L) return -5;
    
    // AVISO: A compilação foi desativada temporariamente para o app abrir.
    // O crash era porque a dylib não achava 'luau_compile'.
    fprintf(stderr, "[Spork] Execução requisitada, mas o compilador tá desativado.\n");
    return 0;

    /* CÓDIGO ORIGINAL COMENTADO:
    uintptr_t base = memory::GetRobloxLibBase();
    if (!base) return -4;

    size_t bcSize = 0;
    char* bc = luau_compile(Source.c_str(), Source.size(), nullptr, &bcSize);
    if (!bc) return -1;

    typedef int (*luau_load_t)(void*, const char*, const char*, size_t, int);
    typedef int (*lua_pcall_t)(void*, int, int, int);
    auto luau_load = (luau_load_t)(base + Offsets::Luau::luau_load);
    auto lua_pcall = (lua_pcall_t)(base + Offsets::Luau::lua_pcall);

    if (luau_load(L, "=Spork", bc, bcSize, 0) != 0) {
        free(bc);
        return -2;
    }
    free(bc);
    return lua_pcall(L, 0, 0, 0);
    */
}
