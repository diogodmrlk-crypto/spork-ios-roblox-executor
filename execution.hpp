// execution.hpp
#pragma once

#include <string>

// Recebe void* (que é lua_State*) pra não forçar o include de lua.h
// em todo arquivo que inclui este header (SporkUI.mm, hooks.mm).
// O cast pra lua_State* é feito dentro do execution.cpp.
//
// Retorna:
//   0  -> sucesso
//  -1  -> falha na compilação (luau_compile retornou nullptr)
//  -2  -> falha no load (luau_load retornou != 0)
//  -4  -> RobloxLib base não encontrada
//  -5  -> L (lua_State) é nulo
//  >0  -> erro de runtime retornado por lua_pcall
int ExecuteScript(void* L, const std::string& Source);
