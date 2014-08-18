//
//  LIREAbstractChooserView.h
//  LIRichEditorLib
//
//  Created by Austin Zheng on 7/4/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LIREChooserViewProtocol.h"

typedef enum {
    LIREChooserBorderModeTop = 0,
    LIREChooserBorderModeBottom,
    LIREChooserBorderModeNone
} LIREChooserBorderMode;

@interface LIREAbstractChooserView : UIView <LIREChooserViewProtocol>

/// A background color to be applied to the chooser view in the most appropriate way (e.g. table view background color).
@property (nonatomic, strong) UIColor *chooserBackgroundColor;

/*! 
 A 'border mode' describing the positioning of an interface between the chooser view and the editor text view's content
 in question. For example, a value of \c LIREChooserBorderModeTop indicates that the chooser view is positioned below
 the relevant content, and that there should therefore be some sort of interface element making that distinction clear.
 */
@property (nonatomic) LIREChooserBorderMode borderMode;

- (void)becomeVisible;
- (void)resetScrollPositionAndHide;

/*!
 Reload the chooser view's data due to changes in the backing store or data source. (In most cases this will trigger a
 subsidiary table view to reload its data.)
 */
- (void)reloadData;

@end
