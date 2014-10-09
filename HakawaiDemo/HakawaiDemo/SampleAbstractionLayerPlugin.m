//
//  SampleAbstractionLayerPlugin.m
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "SampleAbstractionLayerPlugin.h"
#import "AbstractionLayerDemoViewController.h"

#import "HKWTextView.h"

@implementation SampleAbstractionLayerPlugin

@synthesize pluginName = _pluginName;
@synthesize parentTextView = _parentTextView;

- (void)performInitialSetup {
    // don't do anything
}

- (void)performFinalCleanup {
    // don't do anything
}


#pragma mark - Callback methods

- (BOOL)textView:(UITextView *)textView
    textInserted:(NSString *)text
      atLocation:(NSUInteger)location
     autocorrect:(BOOL)autocorrect {
    if (self.changesEnabled) {
        NSString *log = [NSString stringWithFormat:@"INSERTED text '%@' at position %ld.",
                         text, (unsigned long) location];
        [self.parent writeTextToConsoleView:log];
    }
    return self.changesEnabled;
}

- (BOOL)textView:(UITextView *)textView textDeletedFromLocation:(NSUInteger)location length:(NSUInteger)length {
    if (self.changesEnabled) {
        NSString *log = [NSString stringWithFormat:@"DELETED %ld character(s) at position %ld.",
                         (unsigned long) length, (unsigned long) location];
        [self.parent writeTextToConsoleView:log];
    }
    return self.changesEnabled;
}

- (BOOL)textView:(UITextView *)textView replacedTextAtRange:(NSRange)replacementRange
         newText:(NSString *)newText
     autocorrect:(BOOL)autocorrect {
    if (self.changesEnabled) {
        NSString *log = [NSString stringWithFormat:@"REPLACED %ld character(s) at position %ld with new text '%@'.",
                         (unsigned long) replacementRange.length, (unsigned long) replacementRange.location, newText];
        [self.parent writeTextToConsoleView:log];
    }
    return self.changesEnabled;
}

- (void)textView:(UITextView *)textView cursorChangedToInsertion:(NSUInteger)location {
    NSString *log = [NSString stringWithFormat:@"Changed cursor to INSERTION at position %ld.",
                     (unsigned long) location];
    [self.parent writeTextToConsoleView:log];
}

- (void)textView:(UITextView *)textView cursorChangedToSelection:(NSRange)selectionRange {
    NSString *log = [NSString stringWithFormat:@"Changed cursor to SELECTION at position %ld, length %ld.",
                     (unsigned long) selectionRange.location, (unsigned long) selectionRange.length];
    [self.parent writeTextToConsoleView:log];
}

- (void)textView:(UITextView *)textView characterDeletionWasIgnoredAtLocation:(NSUInteger)location {
    // Not implemented
}

@end
