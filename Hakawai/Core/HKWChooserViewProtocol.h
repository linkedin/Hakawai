//
//  HKWChooserViewProtocol.h
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

typedef NS_ENUM(NSInteger, HKWChooserBorderMode) {
    HKWChooserBorderModeTop,
    HKWChooserBorderModeBottom,
    HKWChooserBorderModeNone
};

/*!
 A protocol describing a \c UIView subclass that can act as a chooser view for the Hakawai text view (for example, when
 displaying mentions).
 */
@protocol HKWChooserViewProtocol <NSObject>

/*!
 Show the chooser view.
 */
- (void)becomeVisible;

/*!
 Hide the chooser view and, if applicable, reset its 'scroll position' (e.g. a chooser view backed by a table view
 should reset its table view's scroll position to the top).
 */
- (void)resetScrollPositionAndHide;

/*!
 Reload the chooser view's data due to changes in the backing store or data source. (In most cases this will trigger a
 subsidiary table view to reload its data.)
 */
- (void)reloadData;

@optional

/*!
 Return an instance of the chooser view with a given frame with no delegate. This method is intended for
 use with completely custom chooser views.
 */
+ (id)chooserViewWithFrame:(CGRect)frame;

/*!
 Return an instance of the chooser view with a given frame, properly setting the delegate. This method is intended for
 use with chooser views that are not backed by a \c UITableView instance, or wish to completely control the process of
 displaying chooser options, although it can be used for table view-backed views.

 \warning At least one of the two methods: this method, or \c chooserViewWithFrame:delegate:dataSource must be
 implemented, unless you are using a custom chooser view.
 */
+ (id)chooserViewWithFrame:(CGRect)frame
                  delegate:(id<UITableViewDelegate>)delegate;

/*!
 Return an instance of the chooser view with a given frame, properly setting the delegate and data source. This method
 is intended for use with chooser views that are backed by a \c UITableView instance.

 \warning At least one of the two methods: this method, or \c chooserViewWithFrame:delegate: must be implemented, unless you are using a custom chooser view.
 */
+ (id)chooserViewWithFrame:(CGRect)frame
                  delegate:(id<UITableViewDelegate>)delegate
                dataSource:(id<UITableViewDataSource>)dataSource;

/*!
 A 'border mode' describing the positioning of an interface between the chooser view and the editor text view's content
 in question. For example, a value of \c HKWChooserBorderModeTop indicates that the chooser view is positioned below the
 relevant content, and that there should therefore be some sort of interface element making that distinction clear.
 */
@property (nonatomic) HKWChooserBorderMode borderMode;

/*!
 Insets for the scroll indicators for the view displaying the chooser options, if any.
 */
@property (nonatomic) UIEdgeInsets dataViewScrollIndicatorInsets;

/*!
 Content insets for the view displaying the chooser options, if any.
 */
@property (nonatomic) UIEdgeInsets dataViewContentInset;

/*!
 A background color to be applied to the chooser view in some appropriate manner.
 */
@property (nonatomic, strong) UIColor *chooserBackgroundColor;

/*!
 If the chooser view supports an 'insertion cursor' view that points to the x-position of the text entry point, whether
 or not that view is enabled.
 */
@property (nonatomic) BOOL insertionPointMarkerEnabled;

/*!
 If the chooser view supports an 'insertion cursor' view that points to the x-position of the text entry point, move
 the insertion cursor view to the new x-position.
 */
- (void)moveInsertionPointMarkerToXPosition:(CGFloat)position;

@end
