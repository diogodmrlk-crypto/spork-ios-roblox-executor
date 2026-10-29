// SporkUI.mm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "SporkUI.h"

// ============================================================
// PassThroughWindow (Deixa o toque passar pro jogo)
// ============================================================
@interface PassThroughWindow : UIWindow
@property (nonatomic, weak) UIView *interactableView;
@end

@implementation PassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (!hitView) return nil;
    if (self.interactableView && !self.interactableView.hidden) {
        CGPoint p = [self.interactableView convertPoint:point fromView:self];
        if ([self.interactableView pointInside:p withEvent:event]) return hitView;
    }
    return nil;
}
@end

// ============================================================
// Variável da Janela
// ============================================================
static PassThroughWindow *overlayWindow = nil;

// ============================================================
// SporkUIViewController (A Tua UI original)
// ============================================================
@implementation SporkUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.scriptEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    self.scriptEditor.font = [UIFont fontWithName:@"Menlo" size:12];
    self.scriptEditor.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.scriptEditor.layer.cornerRadius = 8.0;
    self.scriptEditor.text = @"print(\"hello from spork\")";
    self.scriptEditor.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scriptEditor];
    
    self.executeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.executeButton setTitle:@"Execute" forState:UIControlStateNormal];
    self.executeButton.backgroundColor = [UIColor systemBlueColor];
    [self.executeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.executeButton.layer.cornerRadius = 8.0;
    self.executeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.executeButton addTarget:self action:@selector(executeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.executeButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.text = @"ready";
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.scriptEditor.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:16],
        [self.scriptEditor.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.scriptEditor.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.scriptEditor.heightAnchor constraintEqualToConstant:300],
        
        [self.executeButton.topAnchor constraintEqualToAnchor:self.scriptEditor.bottomAnchor constant:12],
        [self.executeButton.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.executeButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
        [self.executeButton.heightAnchor constraintEqualToConstant:44],
        
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.executeButton.bottomAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16],
    ]];
}

- (void)executeTapped:(UIButton *)sender {
    NSString *script = self.scriptEditor.text;
    if (script.length == 0) {
        self.statusLabel.text = @"error: empty script";
        return;
    }
    
    self.executeButton.enabled = NO;
    self.statusLabel.text = @"queued...";
    
    std::string scriptStr([script UTF8String]);
    RequestExecution(scriptStr);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.executeButton.enabled = YES;
        self.statusLabel.text = @"executed";
    });
}

@end

// ============================================================
// ShowSporkUI (Chamado pelo Tweak.xm)
// ============================================================
void ShowSporkUI(void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(7.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (overlayWindow) return;

        UIWindowScene *activeScene = nil;
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if ([scene isKindOfClass:[UIWindowScene class]]) {
                activeScene = (UIWindowScene *)scene;
                break;
            }
        }

        overlayWindow = activeScene ? [[PassThroughWindow alloc] initWithWindowScene:activeScene] : [[PassThroughWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        
        overlayWindow.frame = [UIScreen mainScreen].bounds;
        overlayWindow.windowLevel = UIWindowLevelAlert + 1000;
        overlayWindow.backgroundColor = [UIColor clearColor];
        
        // Define o tamanho da UI flutuante
        SporkUIViewController *vc = [[SporkUIViewController alloc] init];
        vc.view.frame = CGRectMake(20, 100, self.view.bounds.size.width - 40, 400);
        
        overlayWindow.rootViewController = vc;
        overlayWindow.hidden = NO;
        [overlayWindow makeKeyAndVisible];
        
        overlayWindow.interactableView = vc.view;
    });
}
