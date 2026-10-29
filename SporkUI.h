// SporkUI.h
#import <UIKit/UIKit.h>

extern NSMutableArray<NSString *> *g_logs;
void SporkLog(NSString *format, ...);

@interface SporkViewController : UIViewController
// Precisam ser readwrite pra overlay conseguir interagir com elas
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIButton *floatingButton;
@property (nonatomic, strong) UITextView *scriptEditor;
@property (nonatomic, strong) UIButton *executeButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

// Função que o Tweak.xm chama para injetar a UI no jogo
void ShowSporkUI(void);
