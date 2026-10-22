#import "SporkUI.h"

// --- Custom Button for Squish Effect ---
@interface SporkButton : UIButton
@end
@implementation SporkButton
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(0.92, 0.92);
    }];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:1.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [UIView animateWithDuration:0.4 delay:0 usingSpringWithDamping:0.5 initialSpringVelocity:1.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.transform = CGAffineTransformIdentity;
    } completion:nil];
}
@end

// --- Main View Controller ---
@interface SporkViewController ()
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIView *topBar;
@property (nonatomic, strong) UIView *contentContainer;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) NSArray *sidebarButtons;

// Views for Tabs
@property (nonatomic, strong) UIView *editorTabView;
@property (nonatomic, strong) UIView *homeTabView;
@property (nonatomic, strong) UIView *hacksTabView;
@end

@implementation SporkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupMainContainer];
    [self setupTopBar];
    [self setupSidebar];
    [self setupEditorTab];
    [self setupHomeTab];
    [self setupHacksTab];
    
    // Default to Editor Tab
    [self switchTab:3]; 
}

#pragma mark - Setup UI

- (void)setupMainContainer {
    self.mainContainer = [[UIView alloc] init];
    self.mainContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainContainer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];
    self.mainContainer.layer.cornerRadius = 12;
    self.mainContainer.layer.borderWidth = 1;
    self.mainContainer.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    self.mainContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mainContainer.layer.shadowOpacity = 0.8;
    self.mainContainer.layer.shadowRadius = 15;
    [self.view addSubview:self.mainContainer];

    NSLayoutConstraint *widthConstraint = [self.mainContainer.widthAnchor constraintEqualToConstant:650];
    widthConstraint.priority = UILayoutPriorityDefaultHigh;

    NSLayoutConstraint *heightConstraint = [self.mainContainer.heightAnchor constraintEqualToConstant:400];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.mainContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mainContainer.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        widthConstraint,
        [self.mainContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.95],
        heightConstraint,
        [self.mainContainer.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.8]
    ]];
}

- (void)setupTopBar {
    self.topBar = [[UIView alloc] init];
    self.topBar.translatesAutoresizingMaskIntoConstraints = NO;
    self.topBar.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    self.topBar.layer.cornerRadius = 12;
    self.topBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.mainContainer addSubview:self.topBar];
    
    // Drag Gesture
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.topBar addGestureRecognizer:pan];

    // Icon (Horse placeholder)
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"hare.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.tintColor = [UIColor whiteColor];
    [self.topBar addSubview:icon];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Spork";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    [self.topBar addSubview:title];

    UILabel *proBadge = [[UILabel alloc] init];
    proBadge.translatesAutoresizingMaskIntoConstraints = NO;
    proBadge.text = @" PRO ";
    proBadge.textColor = [UIColor whiteColor];
    proBadge.font = [UIFont boldSystemFontOfSize:10];
    proBadge.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    proBadge.layer.cornerRadius = 4;
    proBadge.clipsToBounds = YES;
    [self.topBar addSubview:proBadge];

    UILabel *execText = [[UILabel alloc] init];
    execText.translatesAutoresizingMaskIntoConstraints = NO;
    execText.text = @"Executor & Scripts Handler";
    execText.textColor = [UIColor lightGrayColor];
    execText.font = [UIFont systemFontOfSize:10];
    [self.topBar addSubview:execText];

    // Window Controls
    SporkButton *closeBtn = [SporkButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    [closeBtn setTintColor:[UIColor redColor]];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [self.topBar addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [self.topBar.topAnchor constraintEqualToAnchor:self.mainContainer.topAnchor],
        [self.topBar.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor],
        [self.topBar.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor],
        [self.topBar.heightAnchor constraintEqualToConstant:50],

        [icon.leadingAnchor constraintEqualToAnchor:self.topBar.leadingAnchor constant:15],
        [icon.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [icon.widthAnchor constraintEqualToConstant:20],
        [icon.heightAnchor constraintEqualToConstant:20],

        [title.leadingAnchor constraintEqualToAnchor:icon.trailingAnchor constant:8],
        [title.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],

        [proBadge.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:8],
        [proBadge.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [proBadge.heightAnchor constraintEqualToConstant:16],

        [execText.leadingAnchor constraintEqualToAnchor:proBadge.trailingAnchor constant:15],
        [execText.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],

        [closeBtn.trailingAnchor constraintEqualToAnchor:self.topBar.trailingAnchor constant:-15],
        [closeBtn.centerYAnchor constraintEqualToAnchor:self.topBar.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:24],
        [closeBtn.heightAnchor constraintEqualToConstant:24]
    ]];
}

- (void)setupSidebar {
    self.sidebar = [[UIView alloc] init];
    self.sidebar.translatesAutoresizingMaskIntoConstraints = NO;
    self.sidebar.backgroundColor = [UIColor colorWithRed:0.12 green:0.12 blue:0.12 alpha:1.0];
    self.sidebar.layer.cornerRadius = 12;
    self.sidebar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMinXMaxYCorner;
    [self.mainContainer addSubview:self.sidebar];

    NSArray *icons = @[@"doc.text.fill", @"house.fill", @"bolt.fill", @"chevron.left.forwardslash.chevron.right", @"doc.on.clipboard"];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 25;
    stack.alignment = UIStackViewAlignmentCenter;
    [self.sidebar addSubview:stack];

    NSMutableArray *buttons = [NSMutableArray array];
    for (int i = 0; i < icons.count; i++) {
        SporkButton *btn = [SporkButton buttonWithType:UIButtonTypeSystem];
        [btn setImage:[UIImage systemImageNamed:icons[i]] forState:UIControlStateNormal];
        [btn setTintColor:[UIColor lightGrayColor]];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.tag = i;
        [btn addTarget:self action:@selector(sidebarTapped:) forControlEvents:UIControlEventTouchUpInside];
        [btn.widthAnchor constraintEqualToConstant:30].active = YES;
        [btn.heightAnchor constraintEqualToConstant:30].active = YES;
        [stack addArrangedSubview:btn];
        [buttons addObject:btn];
    }
    self.sidebarButtons = buttons;

    self.selectionIndicator = [[UIView alloc] init];
    self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectionIndicator.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [self.sidebar addSubview:self.selectionIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.sidebar.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor],
        [self.sidebar.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor],
        [self.sidebar.bottomAnchor constraintEqualToAnchor:self.mainContainer.bottomAnchor],
        [self.sidebar.widthAnchor constraintEqualToConstant:60],

        [stack.topAnchor constraintEqualToAnchor:self.sidebar.topAnchor constant:30],
        [stack.centerXAnchor constraintEqualToAnchor:self.sidebar.centerXAnchor],

        [self.selectionIndicator.leadingAnchor constraintEqualToAnchor:self.sidebar.leadingAnchor],
        [self.selectionIndicator.topAnchor constraintEqualToAnchor:stack.topAnchor],
        [self.selectionIndicator.widthAnchor constraintEqualToConstant:4],
        [self.selectionIndicator.heightAnchor constraintEqualToConstant:30]
    ]];
}

- (void)setupContentContainer {
    if (self.contentContainer) return;
    self.contentContainer = [[UIView alloc] init];
    self.contentContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:self.contentContainer];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.contentContainer.topAnchor constraintEqualToAnchor:self.topBar.bottomAnchor],
        [self.contentContainer.leadingAnchor constraintEqualToAnchor:self.sidebar.trailingAnchor],
        [self.contentContainer.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor],
        [self.contentContainer.bottomAnchor constraintEqualToAnchor:self.mainContainer.bottomAnchor]
    ]];
}

#pragma mark - Tabs

- (void)setupEditorTab {
    [self setupContentContainer];
    self.editorTabView = [[UIView alloc] init];
    self.editorTabView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.contentContainer addSubview:self.editorTabView];
    
    UIView *tabHeader = [[UIView alloc] init];
    tabHeader.translatesAutoresizingMaskIntoConstraints = NO;
    tabHeader.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    tabHeader.layer.cornerRadius = 8;
    tabHeader.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.editorTabView addSubview:tabHeader];

    UILabel *tabLabel = [[UILabel alloc] init];
    tabLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tabLabel.text = @"Script 1  x";
    tabLabel.textColor = [UIColor whiteColor];
    tabLabel.font = [UIFont systemFontOfSize:12];
    [tabHeader addSubview:tabLabel];

    UITextView *scriptEditor = [[UITextView alloc] init];
    scriptEditor.translatesAutoresizingMaskIntoConstraints = NO;
    scriptEditor.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.08 alpha:1.0];
    scriptEditor.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    scriptEditor.font = [UIFont fontWithName:@"Menlo" size:12];
    scriptEditor.text = @"loadstring(game:HttpGet(\"https://spork.com/script.lua\"))()";
    scriptEditor.layer.cornerRadius = 8;
    scriptEditor.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.editorTabView addSubview:scriptEditor];

    UIView *actionBar = [[UIView alloc] init];
    actionBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.editorTabView addSubview:actionBar];

    UIStackView *btnStack = [[UIStackView alloc] init];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = 8;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [actionBar addSubview:btnStack];

    NSArray *btnTitles = @[@"Execute", @"Clear", @"Copy", @"Paste", @"New"];
    for (int i = 0; i < btnTitles.count; i++) {
        SporkButton *btn = [SporkButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:btnTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        btn.backgroundColor = (i == 0) ? [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] : [UIColor colorWithWhite:0.2 alpha:1.0];
        btn.layer.cornerRadius = 6;
        [btnStack addArrangedSubview:btn];
    }

    [NSLayoutConstraint activateConstraints:@[
        [self.editorTabView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:15],
        [self.editorTabView.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:15],
        [self.editorTabView.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-15],
        [self.editorTabView.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor constant:-15],

        [tabHeader.topAnchor constraintEqualToAnchor:self.editorTabView.topAnchor],
        [tabHeader.leadingAnchor constraintEqualToAnchor:self.editorTabView.leadingAnchor],
        [tabHeader.trailingAnchor constraintEqualToAnchor:self.editorTabView.trailingAnchor],
        [tabHeader.heightAnchor constraintEqualToConstant:30],

        [tabLabel.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor constant:10],
        [tabLabel.centerYAnchor constraintEqualToAnchor:tabHeader.centerYAnchor],

        [scriptEditor.topAnchor constraintEqualToAnchor:tabHeader.bottomAnchor],
        [scriptEditor.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor],
        [scriptEditor.trailingAnchor constraintEqualToAnchor:tabHeader.trailingAnchor],
        [scriptEditor.bottomAnchor constraintEqualToAnchor:actionBar.topAnchor constant:-10],

        [actionBar.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor],
        [actionBar.trailingAnchor constraintEqualToAnchor:tabHeader.trailingAnchor],
        [actionBar.bottomAnchor constraintEqualToAnchor:self.editorTabView.bottomAnchor],
        [actionBar.heightAnchor constraintEqualToConstant:35],

        [btnStack.leadingAnchor constraintEqualToAnchor:actionBar.leadingAnchor],
        [btnStack.trailingAnchor constraintEqualToAnchor:actionBar.trailingAnchor],
        [btnStack.topAnchor constraintEqualToAnchor:actionBar.topAnchor],
        [btnStack.bottomAnchor constraintEqualToAnchor:actionBar.bottomAnchor]
    ]];
}

- (void)setupHomeTab {
    [self setupContentContainer];
    self.homeTabView = [[UIView alloc] init];
    self.homeTabView.translatesAutoresizingMaskIntoConstraints = NO;
    self.homeTabView.hidden = YES;
    [self.contentContainer addSubview:self.homeTabView];
    
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Key System Status";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    [self.homeTabView addSubview:title];
    
    // Fake Progress Bar
    UIView *progressBg = [[UIView alloc] init];
    progressBg.translatesAutoresizingMaskIntoConstraints = NO;
    progressBg.backgroundColor = [UIColor darkGrayColor];
    progressBg.layer.cornerRadius = 6;
    [self.homeTabView addSubview:progressBg];
    
    UIView *progressFill = [[UIView alloc] init];
    progressFill.translatesAutoresizingMaskIntoConstraints = NO;
    progressFill.backgroundColor = [UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0];
    progressFill.layer.cornerRadius = 6;
    [progressBg addSubview:progressFill];

    [NSLayoutConstraint activateConstraints:@[
        [self.homeTabView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:15],
        [self.homeTabView.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:15],
        [self.homeTabView.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-15],
        [self.homeTabView.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor constant:-15],
        
        [title.topAnchor constraintEqualToAnchor:self.homeTabView.topAnchor constant:10],
        [title.leadingAnchor constraintEqualToAnchor:self.homeTabView.leadingAnchor constant:10],
        
        [progressBg.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [progressBg.leadingAnchor constraintEqualToAnchor:self.homeTabView.leadingAnchor constant:10],
        [progressBg.trailingAnchor constraintEqualToAnchor:self.homeTabView.trailingAnchor constant:-10],
        [progressBg.heightAnchor constraintEqualToConstant:12],
        
        [progressFill.leadingAnchor constraintEqualToAnchor:progressBg.leadingAnchor],
        [progressFill.topAnchor constraintEqualToAnchor:progressBg.topAnchor],
        [progressFill.bottomAnchor constraintEqualToAnchor:progressBg.bottomAnchor],
        [progressFill.widthAnchor constraintEqualToAnchor:progressBg.widthAnchor multiplier:0.7]
    ]];
}

- (void)setupHacksTab {
    [self setupContentContainer];
    self.hacksTabView = [[UIView alloc] init];
    self.hacksTabView.translatesAutoresizingMaskIntoConstraints = NO;
    self.hacksTabView.hidden = YES;
    [self.contentContainer addSubview:self.hacksTabView];
    
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Recommended Scripts";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    [self.hacksTabView addSubview:title];
    
    UIStackView *btnStack = [[UIStackView alloc] init];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisVertical;
    btnStack.spacing = 8;
    [self.hacksTabView addSubview:btnStack];
    
    NSArray *scripts = @[@"Fates ESP", @"BTools", @"Shiftlock", @"DEX Explorer", @"Infinite Yield"];
    for (NSString *name in scripts) {
        SporkButton *btn = [SporkButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:name forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        btn.layer.cornerRadius = 6;
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 0);
        [btn.heightAnchor constraintEqualToConstant:30].active = YES;
        [btnStack addArrangedSubview:btn];
    }
    
    [NSLayoutConstraint activateConstraints:@[
        [self.hacksTabView.topAnchor constraintEqualToAnchor:self.contentContainer.topAnchor constant:15],
        [self.hacksTabView.leadingAnchor constraintEqualToAnchor:self.contentContainer.leadingAnchor constant:15],
        [self.hacksTabView.trailingAnchor constraintEqualToAnchor:self.contentContainer.trailingAnchor constant:-15],
        [self.hacksTabView.bottomAnchor constraintEqualToAnchor:self.contentContainer.bottomAnchor constant:-15],
        
        [title.topAnchor constraintEqualToAnchor:self.hacksTabView.topAnchor constant:10],
        [title.leadingAnchor constraintEqualToAnchor:self.hacksTabView.leadingAnchor constant:10],
        
        [btnStack.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [btnStack.leadingAnchor constraintEqualToAnchor:self.hacksTabView.leadingAnchor constant:10],
        [btnStack.trailingAnchor constraintEqualToAnchor:self.hacksTabView.trailingAnchor constant:-10]
    ]];
}

#pragma mark - Actions

- (void)sidebarTapped:(SporkButton *)sender {
    [self switchTab:sender.tag];
}

- (void)switchTab:(NSInteger)index {
    // Hide all
    self.homeTabView.hidden = YES;
    self.hacksTabView.hidden = YES;
    self.editorTabView.hidden = YES;
    
    // Show selected
    if (index == 0) {
        self.editorTabView.hidden = NO;
    } else if (index == 1) {
        self.homeTabView.hidden = NO;
    } else if (index == 2) {
        self.hacksTabView.hidden = NO;
    } else if (index == 3) {
        self.editorTabView.hidden = NO;
    } else {
        self.editorTabView.hidden = NO;
    }
    
    // Animate indicator
    SporkButton *selectedBtn = self.sidebarButtons[index];
    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.7 initialSpringVelocity:0.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
        self.selectionIndicator.center = CGPointMake(self.selectionIndicator.center.x, selectedBtn.center.y + 30);
    } completion:nil];
}

- (void)hideMenu {
    self.mainContainer.hidden = YES;
}

#pragma mark - Drag & Squish Animation

- (void)handlePan:(UIPanGestureRecognizer *)sender {
    CGPoint translation = [sender translationInView:self.view];
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        // SQUISH EFFECT ON GRAB
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.mainContainer.transform = CGAffineTransformMakeScale(0.96, 0.96);
        } completion:nil];
    }
    
    // Move the container
    self.mainContainer.center = CGPointMake(self.mainContainer.center.x + translation.x, self.mainContainer.center.y + translation.y);
    [sender setTranslation:CGPointZero inView:self.view];
    
    if (sender.state == UIGestureRecognizerStateEnded || sender.state == UIGestureRecognizerStateCancelled) {
        // BOUNCY SPRING EFFECT ON RELEASE
        [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.4 initialSpringVelocity:1.5 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            self.mainContainer.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

@end
