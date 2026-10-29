// hooks.hpp
#pragma once

// L é void* (lua_State*), não usamos o tipo direto pra não depender de lua.h
void SetupExecution(void* L);
