//
//  HKWTControlFlowDummyPlugin.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTControlFlowDummyPlugin.h"

@implementation HKWTControlFlowDummyPlugin

@synthesize parentTextView;

+ (instancetype)dummyPluginWithName:(NSString *)name {
    HKWTControlFlowDummyPlugin *plugin = [self new];
    plugin.pluginName = name;
    return plugin;
}

- (void)resetBlocks {
    self.shouldBeginEditingBlock = nil;
    self.didBeginEditingBlock = nil;
    self.shouldEndEditingBlock = nil;
    self.didEndEditingBlock = nil;
    self.shouldChangeTextInRangeBlock = nil;
    self.didChangeBlock = nil;
    self.didChangeSelectionBlock = nil;
    self.shouldInteractWithTextAttachmentBlock = nil;
    self.shouldInteractWithURLBlock = nil;
}


#pragma mark - Delegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (self.shouldBeginEditingBlock) {
        self.shouldBeginEditingBlock();
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.didBeginEditingBlock) {
        self.didBeginEditingBlock();
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (self.shouldEndEditingBlock) {
        self.shouldEndEditingBlock();
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.didEndEditingBlock) {
        self.didEndEditingBlock();
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText {
    if (self.shouldChangeTextInRangeBlock) {
        self.shouldChangeTextInRangeBlock();
    }
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.didChangeBlock) {
        self.didChangeBlock();
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.didChangeSelectionBlock) {
        self.didChangeSelectionBlock();
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    if (self.shouldInteractWithTextAttachmentBlock) {
        self.shouldInteractWithTextAttachmentBlock();
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.shouldInteractWithURLBlock) {
        self.shouldInteractWithURLBlock();
    }
    return YES;
}

@end
