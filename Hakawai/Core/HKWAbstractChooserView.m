//
//  HKWAbstractChooserView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWAbstractChooserView.h"

@implementation HKWAbstractChooserView

+ (instancetype)chooserViewWithFrame:(CGRect)frame
                            delegate:(id<UITableViewDelegate>)delegate
                          dataSource:(id<UITableViewDataSource>)dataSource {
    NSAssert(NO, @"Concrete subclasses must implement this method.");
    return nil;
}

- (void)resetScrollPositionAndHide {
    // Note that your concrete implementation should call UIAccessibilityPostNotification().
    NSAssert(NO, @"Concrete subclasses must implement this method.");
}

- (void)becomeVisible {
    // Default implementation
    self.hidden = NO;
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
}

- (void)reloadData {
    NSAssert(NO, @"Concrete subclasses must implement this method.");
}

@end
