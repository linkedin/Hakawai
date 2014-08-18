//
//  HKWAbstractChooserView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
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
