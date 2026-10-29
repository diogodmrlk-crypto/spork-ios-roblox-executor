// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"
#include "memory.hpp"

%ctor {
    // 1. Mostra a UI depois de 5 segundos
    ShowSporkUI();

    // 2. Verifica a cada 1 segundo se o RobloxLib já foi carregado
    [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        if (memory::GetRobloxLibBase() != 0) {
            [timer invalidate];
            SetupExploit();
            SetupExecution(nullptr);
            NSLog(@"[Spork] RobloxLib carregada. Hooks aplicados!");
        }
    }];
}
