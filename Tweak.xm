// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"
#include "memory.hpp"

%ctor {
    // 1. Cria a UI depois de 8 segundos (tempo pro Roblox renderizar a tela)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        ShowSporkUI();
    });

    // 2. Só aplica os hooks depois de 20 segundos, garantindo que o RobloxLib está na memória
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupExploit();
        SetupExecution(nullptr);
        NSLog(@"[Spork] Hooks de execução aplicados.");
    });
}
