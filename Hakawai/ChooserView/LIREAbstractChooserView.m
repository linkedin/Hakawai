//
//  LIREAbstractChooserView.m
//  LIRichEditorLib
//
//  Created by Austin Zheng on 7/4/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import "LIREAbstractChooserView.h"

@implementation LIREAbstractChooserView

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
