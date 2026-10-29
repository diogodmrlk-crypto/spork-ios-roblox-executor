// memory.hpp
#pragma once
#include <cstdint>

namespace memory {
    uintptr_t GetRobloxLibBase();
    uintptr_t GetModuleBase(const char* name);
}
