//
//  AbstractionLayerDemoViewController.m
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "AbstractionLayerDemoViewController.h"

#import "SampleAbstractionLayerPlugin.h"

#import "HKWTextView.h"

@interface AbstractionLayerDemoViewController ()

@property (nonatomic, weak) IBOutlet HKWTextView *textView;
@property (nonatomic, weak) IBOutlet UITextView *consoleTextView;

@property (nonatomic, strong) SampleAbstractionLayerPlugin *plugin;

@end

@implementation AbstractionLayerDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add a border to the text view to make it look nicer
    self.textView.layer.borderWidth = 0.5;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    self.consoleTextView.layer.borderWidth = 0.5;
    self.consoleTextView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    // Set up the plug-in
    self.textView.abstractionControlFlowPlugin = self.plugin;
}

- (void)writeTextToConsoleView:(NSString *)text {
    if ([text length] == 0) {
        return;
    }
    NSString *fullText = [NSString stringWithFormat:@"%@\n", text];
    self.consoleTextView.text = [self.consoleTextView.text stringByAppendingString:fullText];
    // Jump to bottom
    [self.consoleTextView scrollRangeToVisible:NSMakeRange([self.consoleTextView.text length], 0)];
}


#pragma mark - Controls

- (IBAction)doneEditingButtonTapped {
    [self.textView resignFirstResponder];
}

- (IBAction)disableEnableButtonTapped:(UIButton *)sender {
    if (self.plugin.changesEnabled) {
        self.plugin.changesEnabled = NO;
        [sender setTitle:@"Enable" forState:UIControlStateNormal];
    }
    else {
        self.plugin.changesEnabled = YES;
        [sender setTitle:@"Disable" forState:UIControlStateNormal];
    }
}

- (IBAction)clearConsoleButtonTapped {
    self.consoleTextView.text = @"";
}


#pragma mark - Misc

- (SampleAbstractionLayerPlugin *)plugin {
    if (!_plugin) {
        _plugin = [SampleAbstractionLayerPlugin new];
        _plugin.changesEnabled = YES;
        _plugin.parent = self;
    }
    return _plugin;
}

@end
