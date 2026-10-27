#pragma once
#include <stdint.h>
#include <stdbool.h>

bool safe_read(void* address, void* buffer, size_t size);
uintptr_t get_robloxlib_base(void);
