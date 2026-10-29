// config.hpp
#pragma once

#include <cstdint>

namespace Offsets {
    namespace Luau {
        constexpr uintptr_t luau_load     = 0x410f3b0;
        constexpr uintptr_t lua_pcall     = 0x40e4cc0;
        constexpr uintptr_t lua_newthread = 0x40e1e50;
        constexpr uintptr_t lua_tolstring = 0x40e2b44;
        constexpr uintptr_t gc_step       = 0x40f30fc;
    }
    namespace LuaState {
        constexpr uintptr_t ExtraSpace = 0x28;
        constexpr uintptr_t CallInfo   = 0x40;
        constexpr uintptr_t StackTop   = 0x58;
        constexpr uintptr_t Identity   = 0x90; 
    }
}
