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
