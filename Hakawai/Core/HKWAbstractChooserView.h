//
//  HKWAbstractChooserView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <UIKit/UIKit.h>
#import "HKWChooserViewProtocol.h"

typedef enum {
    HKWChooserBorderModeTop = 0,
    HKWChooserBorderModeBottom,
    HKWChooserBorderModeNone
} HKWChooserBorderMode;

@interface HKWAbstractChooserView : UIView <HKWChooserViewProtocol>

/// A background color to be applied to the chooser view in the most appropriate way (e.g. table view background color).
@property (nonatomic, strong) UIColor *chooserBackgroundColor;

/*! 
 A 'border mode' describing the positioning of an interface between the chooser view and the editor text view's content
 in question. For example, a value of \c HKWChooserBorderModeTop indicates that the chooser view is positioned below the
 relevant content, and that there should therefore be some sort of interface element making that distinction clear.
 */
@property (nonatomic) HKWChooserBorderMode borderMode;

- (void)becomeVisible;
- (void)resetScrollPositionAndHide;

/*!
 Reload the chooser view's data due to changes in the backing store or data source. (In most cases this will trigger a
 subsidiary table view to reload its data.)
 */
- (void)reloadData;

@end
