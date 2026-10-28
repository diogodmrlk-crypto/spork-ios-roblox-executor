#include "hooks.hpp"
#include "config.hpp"
#include "memory.hpp"
#import <Foundation/Foundation.h>
#include <mach/vm_map.h>
#include <string.h>

extern void SporkLog(NSString *format, ...);

void* g_live_L = NULL;

// Implementação customizada de lua_gettop.
int my_lua_gettop(void* L) {
    // 1. Captura do Ponteiro (One-time Steal)
    if (!g_live_L && L) {
        // Verificação de sanidade: O ponteiro deve estar em um espaço de usuário plausível
        if ((uintptr_t)L > 0x100000000) {
            g_live_L = L;
            SporkLog(@"[HOOK] STOLE lua_State via lua_gettop: %p", g_live_L);
        }
    }
    
    // Se L for nulo, retornamos 0 (stack vazia)
    if (!L) return 0;

    uintptr_t top = 0, base = 0;
    
    // 2. Leitura Segura dos Offsets da Stack
    // Usando os offsets definidos no config.hpp
    if (!safe_read((char*)L + OFFSET_LUA_STATE_TOP, &top, 8)) return 0;
    if (!safe_read((char*)L + OFFSET_LUA_STATE_BASE, &base, 8)) return 0;
    
    // 3. Cálculo do Tamanho da Stack
    // TValue stride é 0x10 (16 bytes)
    if (top < base) return 0;
    
    return (int)((top - base) / 16);
}

void SetupHooks(void) {
    SporkLog(@"[HOOK] SetupHooks iniciado...");
    
    uintptr_t base = get_robloxlib_base();
    if (!base) { 
        SporkLog(@"[HOOK] ERRO: Base do RobloxLib é NULL. Dylib não encontrado.");
        return; 
    }
    SporkLog(@"[HOOK] Base do RobloxLib: 0x%lx", base);

    void* target = (void*)(base + OFFSET_LUA_GETTOP);
    if (!target) {
        SporkLog(@"[HOOK] ERRO: Endereço alvo do hook é NULL. Verifique OFFSET_LUA_GETTOP.");
        return;
    }
    SporkLog(@"[HOOK] Endereço alvo do hook: 0x%lx", target);

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
        SporkLog(@"[HOOK] ERRO: vm_protect falhou: %d. Verifique entitlements.", kr);
        return;
    }
    
    memcpy(target, patch, 16);
    
    vm_protect(mach_task_self(), (vm_address_t)page, 0x1000, false, VM_PROT_READ | VM_PROT_EXECUTE);
    
    SporkLog(@"[HOOK] Patch aplicado com sucesso em lua_gettop.");
}
