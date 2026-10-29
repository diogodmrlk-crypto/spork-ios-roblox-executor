// SporkUI.mm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "SporkUI.h"

// ============================================================
// Overlay Window (Deixa o toque passar pro jogo)
// ============================================================
@interface PassThroughWindow : UIWindow
@property (nonatomic, weak) UIView *interactableView1;
@property (nonatomic, weak) UIView *interactableView2;
@end

@implementation PassThroughWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if (!hitView) return nil;
    
    if (self.interactableView1 && !self.interactableView1.hidden) {
        CGPoint p = [self.interactableView1 convertPoint:point fromView:self];
        if ([self.interactableView1 pointInside:p withEvent:event]) return hitView;
    }
    if (self.interactableView2 && !self.interactableView2.hidden) {
        CGPoint p = [self.interactableView2 convertPoint:point fromView:self];
        if ([self.interactableView2 pointInside:p withEvent:event]) return hitView;
    }
    return nil; // Toque vai pro Roblox
}
@end

// ============================================================
// Globals
// ============================================================
static PassThroughWindow *overlayWindow = nil;
NSMutableArray<NSString *> *g_logs = nil;

void SporkLog(NSString *format, ...) {
    va_list args;
    va_start(args, format);
    NSString *msg = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    
    if (!g_logs) g_logs = [NSMutableArray array];
    [g_logs addObject:msg];
    NSLog(@"[Spork] %@", msg);
}

// ============================================================
// SporkViewController (A Tua UI)
// ============================================================
@implementation SporkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    self.mainContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.mainContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.mainContainer];
    
    self.scriptEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    self.scriptEditor.font = [UIFont fontWithName:@"Menlo" size:12];
    self.scriptEditor.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.scriptEditor.layer.cornerRadius = 8.0;
    self.scriptEditor.text = @"print(\"hello from spork\")";
    self.scriptEditor.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:self.scriptEditor];
    
    self.executeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.executeButton setTitle:@"Execute" forState:UIControlStateNormal];
    self.executeButton.backgroundColor = [UIColor systemBlueColor];
    [self.executeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.executeButton.layer.cornerRadius = 8.0;
    self.executeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.executeButton addTarget:self action:@selector(executeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.mainContainer addSubview:self.executeButton];
    
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.text = @"ready";
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:self.statusLabel];
    
    // Botão flutuante para abrir/fechar
    self.floatingButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.floatingButton.backgroundColor = [UIColor systemBlueColor];
    self.floatingButton.layer.cornerRadius = 28.0;
    [self.floatingButton setTitle:@"S" forState:UIControlStateNormal];
    [self.floatingButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.floatingButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.floatingButton addTarget:self action:@selector(toggleMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.floatingButton];
    
    [NSLayoutConstraint activateConstraints:@[
        // Floating Button
        [self.floatingButton.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor constant:20],
        [self.floatingButton.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-20],
        [self.floatingButton.widthAnchor constraintEqualToConstant:56],
        [self.floatingButton.heightAnchor constraintEqualToConstant:56],
        
        // Main Container
        [self.mainContainer.topAnchor constraintEqualToAnchor:self.floatingButton.bottomAnchor constant:20],
        [self.mainContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mainContainer.widthAnchor constraintEqualToConstant:320],
        [self.mainContainer.heightAnchor constraintEqualToConstant:400],
        
        // Editor
        [self.scriptEditor.topAnchor constraintEqualToAnchor:self.mainContainer.topAnchor constant:12],
        [self.scriptEditor.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor constant:12],
        [self.scriptEditor.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor constant:-12],
        [self.scriptEditor.heightAnchor constraintEqualToConstant:300],
        
        // Button
        [self.executeButton.topAnchor constraintEqualToAnchor:self.scriptEditor.bottomAnchor constant:12],
        [self.executeButton.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor constant:12],
        [self.executeButton.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor constant:-12],
        [self.executeButton.heightAnchor constraintEqualToConstant:44],
        
        // Label
        [self.statusLabel.topAnchor constraintEqualToAnchor:self.executeButton.bottomAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor constant:12],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor constant:-12],
    ]];
}

- (void)toggleMenu {
    self.mainContainer.hidden = !self.mainContainer.hidden;
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
        
        SporkViewController *vc = [[SporkViewController alloc] init];
        overlayWindow.rootViewController = vc;
        overlayWindow.hidden = NO;
        [overlayWindow makeKeyAndVisible];
        
        overlayWindow.interactableView1 = vc.mainContainer;
        overlayWindow.interactableView2 = vc.floatingButton;
        
        SporkLog(@"overlay ready");
    });
}
