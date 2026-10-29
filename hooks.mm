#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>
#include <mach/vm_map.h>
#include <string.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

int my_lua_gettop(void* L) {
    if (!g_live_L && L) {
        if ((uintptr_t)L > 0x100000000) {
            g_live_L = L;
            SporkLog(@"[HOOK] STOLE lua_State via lua_gettop: %p", g_live_L);
        }
    }
    
    if (!L) return 0;

    uintptr_t top = 0, base = 0;
    if (!safe_read((char*)L + OFFSET_LUA_STATE_TOP, &top, 8)) return 0;
    if (!safe_read((char*)L + OFFSET_LUA_STATE_BASE, &base, 8)) return 0;
    
    if (top < base) return 0;
    
    return (int)((top - base) / 16);
}

void SetupHooks(void) {
    SporkLog(@"[HOOK] SetupHooks iniciado...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) { 
        SporkLog(@"[HOOK] ERRO: Base do RobloxLib é NULL.");
        return; 
    }
    SporkLog(@"[HOOK] Base do RobloxLib: 0x%lx", base);

    void* target = (void*)(base + OFFSET_LUA_GETTOP);
    if (!target) {
        SporkLog(@"[HOOK] ERRO: Endereço alvo é NULL.");
        return;
    }
    SporkLog(@"[HOOK] Endereço alvo do hook: 0x%lx", target);

    // VERIFICAÇÃO DE VALIDADE DA MEMÓRIA
    // Verifica se o endereço está em uma região mapeada e legível
    vm_size_t page_size;
    kern_return_t kr_check = mach_vm_page_size(mach_task_self(), &page_size);
    if (kr_check != KERN_SUCCESS) {
        SporkLog(@"[HOOK] ERRO: Não foi possível obter o tamanho da página.");
        return;
    }
    
    uintptr_t page_start = (uintptr_t)target & ~(page_size - 1);
    vm_address_t address = page_start;
    vm_size_t size = page_size;
    vm_size_t out_size;
    kr_check = mach_vm_read(mach_task_self(), address, size, (vm_address_t)&out_size);
    
    if (kr_check != KERN_SUCCESS) {
        SporkLog(@"[HOOK] ERRO: Endereço alvo não é válido/memória não mapeada. (kr=%d)", kr_check);
        SporkLog(@"[HOOK] Dica: Verifique se o OFFSET_LUA_GETTOP está correto para a versão atual do Roblox.");
        return;
    }
    SporkLog(@"[HOOK] Memória alvo é válida.");

    // Construção da Instrução de Salto ARM64
    uint64_t my_func_addr = (uint64_t)my_lua_gettop;
    uint32_t patch[4];
    patch[0] = 0x58000050; 
    patch[1] = 0xD61F0200; 
    patch[2] = (uint32_t)(my_func_addr & 0xFFFFFFFF);
    patch[3] = (uint32_t)(my_func_addr >> 32);
    
    uintptr_t page = (uintptr_t)target & ~0xFFF;
    kern_return_t kr = vm_protect(mach_task_self(), (vm_address_t)page, 0x1000, false, VM_PROT_READ | VM_PROT_WRITE | VM_PROT_EXECUTE);
    
    if (kr != KERN_SUCCESS) {
        SporkLog(@"[HOOK] ERRO: vm_protect falhou: %d.", kr);
        return;
    }
    
    memcpy(target, patch, 16);
    
    vm_protect(mach_task_self(), (vm_address_t)page, 0x1000, false, VM_PROT_READ | VM_PROT_EXECUTE);
    
    SporkLog(@"[HOOK] Patch aplicado com sucesso em lua_gettop.");
}
