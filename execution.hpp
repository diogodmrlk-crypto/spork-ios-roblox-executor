// execution.hpp
#pragma once

#include <string>
#include "lua.h"
#include "luau.h"

// Executa um script Luau no state dado. Retorna 0 em sucesso, != 0 em erro.
int ExecuteScript(lua_State* L, const std::string& Source);
