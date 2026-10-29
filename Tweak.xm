// Tweak.xm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "hooks.hpp"

// ============================================================
// Entry point do tweak
// ============================================================
%ctor {
    // SetupExploit: acha a base do RobloxLib, hooka luau_load
    // pra capturar o lua_State na primeira chamada do jogo.
    SetupExploit();

    // SetupExecution: hooka o gc_step pra drenar a fila de scripts.
    // Passamos nullptr porque o state real é capturado no hook do luau_load.
    SetupExecution(nullptr);
}
