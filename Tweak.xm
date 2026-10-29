// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"

%ctor {
    // 1. Mostra a UI depois de 8 segundos
    ShowSporkUI();

    // 2. Só hooka as funções 30 segundos depois (tempo mais que suficiente pro jogo abrir)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(30.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupExploit();
        SetupExecution(nullptr);
    });
}
