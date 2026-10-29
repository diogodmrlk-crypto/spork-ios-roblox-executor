// execution.cpp
#include "execution.hpp"
#include "config.hpp"

extern lua_State* ExploitThread;

int ExecuteScript(lua_State* L, const std::string& Source) {
    // 1. Compilar
    size_t BytecodeSize = 0;
    char* Bytecode = luau_compile(Source.c_str(), Source.size(), nullptr, &BytecodeSize);
    if (!Bytecode) return -1;
    
    // 2. Carregar no VM
    if (luau_load(L, "=Spork", Bytecode, BytecodeSize, 0) != 0) {
        free(Bytecode);
        return -1;
    }
    free(Bytecode);
    
    // 3. Executar com proteção
    int Result = lua_pcall(L, 0, 0, 0);
    
    return Result;
}
