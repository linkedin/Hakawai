//
//  _HKWTextView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTextView.h"

#import "HKWTextView+Plugins.h"
#import "HKWAbstractionLayer.h"

@interface HKWTextView ()

#pragma mark - Abstraction layer

@property (nonatomic, strong) HKWAbstractionLayer *abstractionLayer;
@property (nonatomic, readonly) BOOL abstractionLayerEnabled;


#pragma mark - Support machinery

/*!
 A dictionary of custom attributes to be applied to newly typed text. Custom attributes are not by default applied to
 newly typed text; they must be explicitly added to this dictionary.
 */
@property (nonatomic, strong) NSMutableDictionary *customTypingAttributes;


// This property prevents any of the UITextView delegate methods from being fired while it is YES. This is used to
// prevent several types of manipulations to the text view from spuriously triggering additional behavior.
@property (nonatomic, readwrite) BOOL firstResponderIsCycling;

/*!
 This property prevents the 'selection changed' \c UITextViewDelegate method from being forwarded to any registered
 plug-ins if the text view is currently performing a text transformation.
 */
@property (nonatomic) BOOL transformInProgress;

/*!
 If running on iOS 7 or greater, this is the line fragment padding of the text container. Here for iOS 6 compatibility.
 */
@property (nonatomic, readonly) CGFloat lineFragmentPadding;

/// Backing property for 'disableVerticalScrolling'
@property (nonatomic) BOOL disableVerticalScrolling;


#pragma mark - Single line viewport mode

/*!
 Whether or not the text view is in 'single line' viewport mode. This mode locks the viewport to the top or bottom of
 the text view at the line where the insertion point was when entering this mode, and prohibits scrolling.
 */
@property (nonatomic, readwrite) BOOL inSingleLineViewportMode;

/// Whether or not the single line viewport should change to reflect changes in the current line of text
@property (nonatomic) BOOL singleLineViewportShouldFollowInsertionCaret;

/// The viewport mode the text view is configured for
@property (nonatomic) HKWViewportMode viewportMode;

/// The content offset of the viewport when in 'single line' mode.
@property (nonatomic) CGPoint viewportContentOffset;

/// The original content offset, saved when entering 'single line' mode so the viewport can be restored afterwards.
@property (nonatomic) CGPoint originalContentOffset;

/// View for capturing touches in single line viewport mode
@property (nonatomic, strong) UIView *touchCaptureOverlayView;


#pragma mark - Accessory view

@property (nonatomic, copy) void(^onAccessoryViewAttachmentBlock)(UIView *, BOOL);

/// An array holding on to a list of Auto Layout constraints for an accessory view.
@property (nonatomic, strong) NSMutableArray *accessoryViewConstraints;

/// The attached accessory view (if any). Note that this is a weak reference.
@property (nonatomic, weak, readwrite) UIView *attachedAccessoryView;

/// A reference to an optional user-defined 'top level' view, used when placing accessory views in free-floating mode.
@property (nonatomic, weak, readwrite) UIView *customTopLevelView;

/// The mode the accessory view is attached under.
@property (nonatomic) HKWAccessoryViewMode accessoryViewMode;

/// The original origin of the accessory view, if attached as a subview of the superview.
@property (nonatomic) CGPoint accessorySiblingViewOrigin;


#pragma mark - AutoX overrides

@property (nonatomic) BOOL shouldRejectAutocorrectInsertions;

@property (nonatomic) UITextAutocapitalizationType originalAutocapitalization;
@property (nonatomic) UITextAutocorrectionType originalAutocorrection;
@property (nonatomic) UITextSpellCheckingType originalSpellChecking;

@property (nonatomic) BOOL overridingAutocapitalization;
@property (nonatomic) BOOL overridingAutocorrection;
@property (nonatomic) BOOL overridingSpellChecking;


#pragma mark - Other proeprties

@property (nonatomic, strong, readwrite) UIFont *fontSetByApp;
@property (nonatomic, strong, readwrite) UIColor *textColorSetByApp;

@end
