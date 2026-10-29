// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"
#import "SporkUI.h"

%ctor {
    // 1. Chama a UI depois de 7 segundos (tempo pro Roblox abrir a tela de login)
    ShowSporkUI();

    // 2. Só hooka o Luau depois de 20 segundos, quando o jogo já carregou o RobloxLib
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        SetupExploit();
        SetupExecution(nullptr);
    });
}
