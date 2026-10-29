// execution.hpp
#pragma once

#include <string>
#include <cstddef>

// Luau headers — certifique-se de que estes estão no include path do projeto.
// Se o teu projeto usa um vendor específico, ajusta os caminhos.
extern "C" {
#include "lua.h"
#include "luacode.h"
}

// Executa um script Luau no state dado.
// Retorna:
//   0  -> sucesso
//  -1  -> falha na compilação (luau_compile retornou nullptr)
//  -2  -> falha no load (luau_load retornou != 0)
//  >0  -> erro de runtime retornado por lua_pcall (índice na stack)
int ExecuteScript(lua_State* L, const std::string& Source);
