// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"
#include "memory.hpp"

%ctor {
    // 1. Mostra a UI depois de 5 segundos (dá tempo do Roblox renderizar a tela de login)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ShowSporkUI();
    });

    // 2. Cria um timer que verifica a cada 1 segundo se o RobloxLib já carregou na memória
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        // Se a base for diferente de 0, o jogo carregou o framework. Hora de hookar!
        if (memory::GetRobloxLibBase() != 0) {
            [timer invalidate]; // Para o timer
            
            SetupExploit();     // Hooka o luau_load
            SetupExecution(nullptr); // Hooka o gc_step
            
            NSLog(@"[Spork] RobloxLib carregada. Hooks de execução aplicados com sucesso!");
        }
    }];
}
