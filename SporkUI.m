#import "SporkUI.h"

@interface SporkViewController ()
@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UITextView *scriptEditor;
@property (nonatomic, strong) UIView *sidebar;
@property (nonatomic, strong) UIView *selectionIndicator;
@end

@implementation SporkViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    [self setupMainContainer];
    [self setupTopBar];
    [self setupSidebar];
    [self setupEditor];
}

- (void)setupMainContainer {
    self.mainContainer = [[UIView alloc] init];
    self.mainContainer.translatesAutoresizingMaskIntoConstraints = NO;
    self.mainContainer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.95];
    self.mainContainer.layer.cornerRadius = 12;
    self.mainContainer.layer.borderWidth = 1;
    self.mainContainer.layer.borderColor = [UIColor colorWithWhite:0.3 alpha:1.0].CGColor;
    self.mainContainer.layer.shadowColor = [UIColor blackColor].CGColor;
    self.mainContainer.layer.shadowOpacity = 0.5;
    self.mainContainer.layer.shadowRadius = 10;
    [self.view addSubview:self.mainContainer];

    // Safely constrain the size so it doesn't break on smaller/larger screens
    NSLayoutConstraint *widthConstraint = [self.mainContainer.widthAnchor constraintEqualToConstant:600];
    widthConstraint.priority = UILayoutPriorityDefaultHigh; // Allows it to shrink if screen is too small

    NSLayoutConstraint *heightConstraint = [self.mainContainer.heightAnchor constraintEqualToConstant:350];
    heightConstraint.priority = UILayoutPriorityDefaultHigh;

    [NSLayoutConstraint activateConstraints:@[
        [self.mainContainer.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.mainContainer.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        widthConstraint,
        [self.mainContainer.widthAnchor constraintLessThanOrEqualToAnchor:self.view.widthAnchor multiplier:0.9],
        heightConstraint,
        [self.mainContainer.heightAnchor constraintLessThanOrEqualToAnchor:self.view.heightAnchor multiplier:0.8]
    ]];
}

- (void)setupTopBar {
    UIView *topBar = [[UIView alloc] init];
    topBar.translatesAutoresizingMaskIntoConstraints = NO;
    topBar.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    topBar.layer.cornerRadius = 12;
    topBar.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.mainContainer addSubview:topBar];

    // Logo / Title
    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Spork";
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont boldSystemFontOfSize:16];
    [topBar addSubview:title];

    // NEO Badge
    UILabel *neoBadge = [[UILabel alloc] init];
    neoBadge.translatesAutoresizingMaskIntoConstraints = NO;
    neoBadge.text = @" NEO ";
    neoBadge.textColor = [UIColor whiteColor];
    neoBadge.font = [UIFont boldSystemFontOfSize:10];
    neoBadge.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    neoBadge.layer.cornerRadius = 4;
    neoBadge.clipsToBounds = YES;
    [topBar addSubview:neoBadge];

    // Executor Text
    UILabel *execText = [[UILabel alloc] init];
    execText.translatesAutoresizingMaskIntoConstraints = NO;
    execText.text = @"Executor & Scripts Handler";
    execText.textColor = [UIColor lightGrayColor];
    execText.font = [UIFont systemFontOfSize:10];
    [topBar addSubview:execText];

    // Close Button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [closeBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    [closeBtn setTintColor:[UIColor redColor]];
    [closeBtn addTarget:self action:@selector(hideMenu) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [topBar.topAnchor constraintEqualToAnchor:self.mainContainer.topAnchor],
        [topBar.leadingAnchor constraintEqualToAnchor:self.mainContainer.leadingAnchor],
        [topBar.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor],
        [topBar.heightAnchor constraintEqualToConstant:45],

        [title.leadingAnchor constraintEqualToAnchor:topBar.leadingAnchor constant:15],
        [title.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],

        [neoBadge.leadingAnchor constraintEqualToAnchor:title.trailingAnchor constant:8],
        [neoBadge.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
        [neoBadge.heightAnchor constraintEqualToConstant:16],

        [execText.leadingAnchor constraintEqualToAnchor:neoBadge.trailingAnchor constant:15],
        [execText.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],

        [closeBtn.trailingAnchor constraintEqualToAnchor:topBar.trailingAnchor constant:-15],
        [closeBtn.centerYAnchor constraintEqualToAnchor:topBar.centerYAnchor],
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

    // Sidebar Icons
    NSArray *icons = @[@"doc.text.fill", @"house.fill", @"bolt.fill", @"chevron.left.forwardslash.chevron.right", @"doc.on.clipboard"];
    UIStackView *stack = [[UIStackView alloc] init];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    stack.axis = UILayoutConstraintAxisVertical;
    stack.spacing = 25;
    stack.alignment = UIStackViewAlignmentCenter;
    [self.sidebar addSubview:stack];

    for (int i = 0; i < icons.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setImage:[UIImage systemImageNamed:icons[i]] forState:UIControlStateNormal];
        [btn setTintColor:[UIColor lightGrayColor]];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        [btn.widthAnchor constraintEqualToConstant:30].active = YES;
        [btn.heightAnchor constraintEqualToConstant:30].active = YES;
        [stack addArrangedSubview:btn];
    }

    // Selection Indicator (Blue Line)
    self.selectionIndicator = [[UIView alloc] init];
    self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectionIndicator.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0];
    [self.sidebar addSubview:self.selectionIndicator];

    [NSLayoutConstraint activateConstraints:@[
        [self.sidebar.topAnchor constraintEqualToAnchor:self.mainContainer.topAnchor constant:45],
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

- (void)setupEditor {
    // Tab Header
    UIView *tabHeader = [[UIView alloc] init];
    tabHeader.translatesAutoresizingMaskIntoConstraints = NO;
    tabHeader.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    tabHeader.layer.cornerRadius = 8;
    tabHeader.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
    [self.mainContainer addSubview:tabHeader];

    UILabel *tabLabel = [[UILabel alloc] init];
    tabLabel.translatesAutoresizingMaskIntoConstraints = NO;
    tabLabel.text = @"Script 1  x";
    tabLabel.textColor = [UIColor whiteColor];
    tabLabel.font = [UIFont systemFontOfSize:12];
    [tabHeader addSubview:tabLabel];

    // Editor Area
    self.scriptEditor = [[UITextView alloc] init];
    self.scriptEditor.translatesAutoresizingMaskIntoConstraints = NO;
    self.scriptEditor.backgroundColor = [UIColor colorWithRed:0.08 green:0.08 blue:0.08 alpha:1.0];
    self.scriptEditor.textColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    self.scriptEditor.font = [UIFont fontWithName:@"Menlo" size:12];
    self.scriptEditor.text = @"loadstring(game:HttpGet(\"https://spork.com/script.lua\"))()";
    self.scriptEditor.layer.cornerRadius = 8;
    self.scriptEditor.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
    [self.mainContainer addSubview:self.scriptEditor];

    // Bottom Action Bar
    UIView *actionBar = [[UIView alloc] init];
    actionBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:actionBar];

    UIStackView *btnStack = [[UIStackView alloc] init];
    btnStack.translatesAutoresizingMaskIntoConstraints = NO;
    btnStack.axis = UILayoutConstraintAxisHorizontal;
    btnStack.spacing = 8;
    btnStack.distribution = UIStackViewDistributionFillEqually;
    [actionBar addSubview:btnStack];

    NSArray *btnTitles = @[@"Execute", @"Clear", @"Copy", @"Paste", @"New"];
    for (int i = 0; i < btnTitles.count; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        [btn setTitle:btnTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont boldSystemFontOfSize:12];
        btn.backgroundColor = (i == 0) ? [UIColor colorWithRed:0.0 green:0.5 blue:1.0 alpha:1.0] : [UIColor colorWithWhite:0.2 alpha:1.0];
        btn.layer.cornerRadius = 6;
        [btnStack addArrangedSubview:btn];
    }

    [NSLayoutConstraint activateConstraints:@[
        [tabHeader.topAnchor constraintEqualToAnchor:self.sidebar.topAnchor],
        [tabHeader.leadingAnchor constraintEqualToAnchor:self.sidebar.trailingAnchor constant:15],
        [tabHeader.trailingAnchor constraintEqualToAnchor:self.mainContainer.trailingAnchor constant:-15],
        [tabHeader.heightAnchor constraintEqualToConstant:30],

        [tabLabel.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor constant:10],
        [tabLabel.centerYAnchor constraintEqualToAnchor:tabHeader.centerYAnchor],

        [self.scriptEditor.topAnchor constraintEqualToAnchor:tabHeader.bottomAnchor],
        [self.scriptEditor.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor],
        [self.scriptEditor.trailingAnchor constraintEqualToAnchor:tabHeader.trailingAnchor],
        [self.scriptEditor.bottomAnchor constraintEqualToAnchor:actionBar.topAnchor constant:-10],

        [actionBar.leadingAnchor constraintEqualToAnchor:tabHeader.leadingAnchor],
        [actionBar.trailingAnchor constraintEqualToAnchor:tabHeader.trailingAnchor],
        [actionBar.bottomAnchor constraintEqualToAnchor:self.mainContainer.bottomAnchor constant:-15],
        [actionBar.heightAnchor constraintEqualToConstant:35],

        [btnStack.leadingAnchor constraintEqualToAnchor:actionBar.leadingAnchor],
        [btnStack.trailingAnchor constraintEqualToAnchor:actionBar.trailingAnchor],
        [btnStack.topAnchor constraintEqualToAnchor:actionBar.topAnchor],
        [btnStack.bottomAnchor constraintEqualToAnchor:actionBar.bottomAnchor]
    ]];
}

- (void)hideMenu {
    self.mainContainer.hidden = YES;
}

@end
