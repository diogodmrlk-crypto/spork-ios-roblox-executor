// SporkUI.mm
#import <UIKit/UIKit.h>
#import "exploit.hpp"
#import "SporkUI.h"

@interface SporkUIViewController : UIViewController
@property (nonatomic, strong) UITextView *scriptEditor;
@property (nonatomic, strong) UIButton *executeButton;
@property (nonatomic, strong) UILabel *statusLabel;
@end

@implementation SporkUIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    
    // Script Editor
    self.scriptEditor = [[UITextView alloc] initWithFrame:CGRectZero];
    self.scriptEditor.font = [UIFont fontWithName:@"Menlo" size:12];
    self.scriptEditor.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.scriptEditor.layer.cornerRadius = 8.0;
    self.scriptEditor.text = @"print(\"hello from spork\")";
    self.scriptEditor.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scriptEditor];
    
    // Execute Button
    self.executeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.executeButton setTitle:@"Execute" forState:UIControlStateNormal];
    self.executeButton.backgroundColor = [UIColor systemBlueColor];
    [self.executeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.executeButton.layer.cornerRadius = 8.0;
    self.executeButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.executeButton addTarget:self
                           action:@selector(executeTapped:)
                 forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.executeButton];
    
    // Status Label
    self.statusLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.statusLabel.text = @"ready";
    self.statusLabel.font = [UIFont systemFontOfSize:12];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.statusLabel];
    
    // Constraints
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
    
    // Feedback visual
    self.executeButton.enabled = NO;
    self.statusLabel.text = @"queued...";
    
    // Enfileira na execução (NÃO executa direto)
    std::string scriptStr([script UTF8String]);
    RequestExecution(scriptStr);
    
    // Reset do botão após delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        self.executeButton.enabled = YES;
        self.statusLabel.text = @"executed";
    });
}

@end
