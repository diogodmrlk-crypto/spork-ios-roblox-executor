// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"

%ctor {
    // 1. Mostra a UI depois de 5 segundos (pro Roblox abrir)
    ShowSporkUI();

    // 2. Cria um timer que verifica a cada 1 segundo se o RobloxLib já carregou
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        // Se a base já existe, significa que o jogo carregou o framework.
        // Aí a gente hooka e para o timer.
        if (memory::GetRobloxLibBase() != 0) {
            [timer invalidate];
            SetupExploit();
            SetupExecution(nullptr);
            NSLog(@"[Spork] RobloxLib carregada. Hooks aplicados com sucesso!");
        }
    }];
}
