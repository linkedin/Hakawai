//
//  BasicDemoViewController.m
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "BasicDemoViewController.h"

#import "HKWTextView.h"
#import "HKWTextView+Plugins.h"

@interface BasicDemoViewController ()
@property (weak, nonatomic) IBOutlet HKWTextView *textView;
@end

@implementation BasicDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Add a border to the text view to make it look nicer
    self.textView.layer.borderWidth = 0.5;
    self.textView.layer.borderColor = [UIColor lightGrayColor].CGColor;
}


#pragma mark - Controls

- (IBAction)doneEditingButtonTapped {
    [self.textView resignFirstResponder];
}

- (IBAction)palindromeButtonTapped {
    if (self.textView.selectedRange.length == 0) {
        return;
    }
    [self.textView transformSelectedTextWithTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSString *rawInput = [input string];
        NSMutableString *buffer = [NSMutableString string];
        unichar stackC;
        for (NSInteger i=[rawInput length] - 1; i>=0; i--) {
            stackC = [rawInput characterAtIndex:i];
            [buffer appendString:[NSString stringWithCharacters:&stackC length:1]];
        }
        NSDictionary *attrs = [input attributesAtIndex:0 effectiveRange:NULL];
        return [[NSAttributedString alloc] initWithString:buffer attributes:attrs];
    }];
}

- (IBAction)rot13ButtonTapped {
    if (self.textView.selectedRange.length == 0) {
        return;
    }
    [self.textView transformSelectedTextWithTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSString *rawInput = [input string];
        NSMutableString *buffer = [NSMutableString string];
        unichar stackC;
        for (NSInteger i=0; i<[input length]; i++) {
            stackC = [rawInput characterAtIndex:i];
            if (stackC >= 'A' && stackC <= 'Z') {
                stackC += 13;
                if (stackC > 'Z') {
                    stackC -= 26;
                }
            }
            else if (stackC >= 'a' && stackC <= 'z') {
                stackC += 13;
                if (stackC > 'z') {
                    stackC -= 26;
                }
            }
            [buffer appendString:[NSString stringWithCharacters:&stackC length:1]];
        }
        NSDictionary *attrs = [input attributesAtIndex:0 effectiveRange:NULL];
        return [[NSAttributedString alloc] initWithString:buffer attributes:attrs];
    }];
}

@end
