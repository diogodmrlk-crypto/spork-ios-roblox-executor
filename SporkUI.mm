- (void)injectExecutorAction {
    self.statusLabel.text = @"Injecting... (see logs)";
    self.statusLabel.textColor = [UIColor yellowColor];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SetupHooks();
        
        // Wait 2 seconds for the game to naturally call lua_gettop
        [NSThread sleepForTimeInterval:2.0];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (g_live_L) {
                self.statusLabel.text = @"Success! Injected.";
                self.statusLabel.textColor = [UIColor greenColor];
                [self.injectBtn setTitle:@"Injected" forState:UIControlStateNormal];
                self.injectBtn.enabled = NO;
            } else {
                self.statusLabel.text = @"Failed (check logs)";
                self.statusLabel.textColor = [UIColor redColor];
            }
        });
    });
}
