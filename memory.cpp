// memory.cpp
#include "config.hpp"
#include <mach-o/dyld.h>
#include <string.h>
#include <mach/mach.h>
#include <mach/vm_map.h>
#include <ptrauth.h>

#ifndef STRIP_PAC
#define STRIP_PAC(p) ((void*)ptrauth_strip((void*)(p), ptrauth_key_asia))
#endif

bool safe_read(void* address, void* buffer, size_t size) {
    if (!address || !buffer || size == 0) return false;
    uintptr_t addr = (uintptr_t)STRIP_PAC(address);
    if (addr < 0x100000000ULL) return false;

    vm_size_t out_size = 0;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr, (vm_size_t)size, (vm_address_t)buffer, &out_size);
    return (kr == KERN_SUCCESS && out_size == size);
}

uintptr_t get_robloxlib_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char* name = _dyld_get_image_name(i);
        if (!name) continue;
        if (strstr(name, "RobloxLib")) {
            return (uintptr_t)_dyld_get_image_header(i);
        }
    }
    return 0;
}
