//
//  MentionsDemoViewController.m
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "MentionsDemoViewController.h"

#import "MentionsManager.h"
#import "HakawaiDemo-Swift.h"

#import "HKWTextView.h"
#import "HKWMentionsPlugin.h"
#import "_HKWOSVersionMacros.h"

@interface MentionsDemoViewController ()
@property (nonatomic, weak) IBOutlet HKWTextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *listMentionsButton;
@property (nonatomic, strong) HKWMentionsPlugin *plugin;
@end

@implementation MentionsDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add a border to the text view to make it look nicer
    self.textView.layer.borderWidth = 0.5;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;

    if (HKW_SYSTEM_VERSION_LESS_THAN(_iOS_7_1)) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warning"
                                                        message:@"The mentions plug-in is only supported on iOS 7.1 and later."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        self.textView.editable = NO;
        self.listMentionsButton.enabled = NO;
    }
    else {
        // Set up the mentions system
        HKWMentionsChooserPositionMode mode = HKWMentionsChooserPositionModeEnclosedTop;
        // In this demo, the user may explicitly begin a mention with either the '@' or '+' characters
        NSCharacterSet *controlCharacters = [NSCharacterSet characterSetWithCharactersInString:@"@+"];
        // The user may also begin a mention by typing three characters (set searchLength to 0 to disable)
        HKWMentionsPlugin *mentionsPlugin = [HKWMentionsPlugin mentionsPluginWithChooserMode:mode
                                                                           controlCharacters:controlCharacters
                                                                                searchLength:3];

        // NOTE: If you want to see an example of a custom chooser, uncomment the following line.
//        mentionsPlugin.chooserViewClass = [SimpleChooserView class];


        // If the text view loses focus while the mention chooser is up, and then regains focus, it will automatically put
        //  the mentions chooser back up
        mentionsPlugin.resumeMentionsCreationEnabled = YES;
        // Add edge insets so chooser view doesn't overlap the text view's cosmetic grey border
        mentionsPlugin.chooserViewEdgeInsets = UIEdgeInsetsMake(2, 0.5, 0.5, 0.5);
        self.plugin = mentionsPlugin;
        self.plugin.chooserViewBackgroundColor = LIGHT_GRAY_COLOR;
        // The mentions plug-in requires a delegate, which provides it with mentions entities in response to a query string
        mentionsPlugin.delegate = [MentionsManager sharedInstance];
        mentionsPlugin.stateChangeDelegate = [MentionsManager sharedInstance];
        self.textView.controlFlowPlugin = mentionsPlugin;
    }
}


#pragma mark - Controls

- (IBAction)doneEditingButtonTapped {
    [self.textView resignFirstResponder];
}

- (IBAction)listMentionsButtonTapped {
    NSArray *mentions = [self.plugin mentions];
    NSLog(@"There are %ld mention(s): %@", (unsigned long)[mentions count], mentions);
}

@end
