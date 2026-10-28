#include "config.hpp"
#include <mach-o/dyld.h>
#include <string.h>
#include <mach/mach.h>
#include <mach/vm_map.h>

bool safe_read(void* address, void* buffer, size_t size) {
    uintptr_t addr = STRIP_PAC(address);
    if (addr < 0x100000000) return false; 
    
    vm_size_t out_size;
    kern_return_t kr = vm_read_overwrite(mach_task_self(), (vm_address_t)addr, (vm_size_t)size, (vm_address_t)buffer, &out_size);
    return (kr == KERN_SUCCESS && out_size == size);
}

uintptr_t get_robloxlib_base(void) {
    uint32_t count = _dyld_image_count();
    for (uint32_t i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        if (name && strstr(name, "RobloxLib")) {
            // Soma o slide do ASLR para garantir que os offsets funcionem
            uintptr_t slide = _dyld_get_image_vmaddr_slide(i);
            return (uintptr_t)_dyld_get_image_header(i) + slide;
        }
    }
    return 0;
}
