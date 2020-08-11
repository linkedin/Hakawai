//
//  HKWTextView+Plugins.h
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

/*!
 An enum describing a version of the single line viewport mode supported by the rich text editor.

 \c HKWViewportModeTop locks the viewport to the top line of text.

 \c HKWViewportModeBottom locks the viewport to the bottom line of text.
 */
typedef NS_ENUM(NSInteger, HKWViewportMode) {
    HKWViewportModeTop = 0,
    HKWViewportModeBottom
};

/*!
 An enum describing the way the accessory view should be added to the parent view.

 \c HKWAccessoryViewModeSibling causes the accessory view to be attached to the text view's superview, so the text view
 and accessory view are 'siblings' in the view hierarchy. This mode is intended for use cases where the text view
 resides within some container that should also hold the accessory views.

 \c HKWAccessoryViewModeFreeFloating causes the accessory view to be attached to the 'top level' view, specified by the
 \c setTopLevelViewForAccessoryViewPositioning: method. If the top level view is not specified, the text view tries to
 figure out the top level view at the time the view is attached.
 */
typedef NS_ENUM(NSInteger, HKWAccessoryViewMode) {
    HKWAccessoryViewModeSibling = 0,
    HKWAccessoryViewModeFreeFloating
};

/*!
 This category provides an API for plug-ins registered to the text view. You are free to use these features outside the
 context of implementing a plug-in, but your plug-ins may not function correctly if you do this. (If you are not using
 plug-ins with the text view, you are free to use any of these methods without additional safeguards.)
 */
@interface HKWTextView (Plugins)

#pragma mark - API (viewport)

/*!
 Order the text view to enter the 'single line viewport mode', where the current line is fixed in a given position and
 scrolling is disabled. If the text view is already in this mode, this method does nothing.

 \warning Do not move the text view to a different superview while the text view is in single-line viewport mode; this
 will cause problems.

 \param shouldCaptureTouches    if YES, taps on the text view while in single line viewport mode will not be forwarded
                                to the text view; instead they will trigger special events (that the plug-in can respond to)

 \returns a \c CGRect describing (relative to the editor view's bounds) the rectangle occupied by the single line
          viewport
 */
- (CGRect)enterSingleLineViewportMode:(HKWViewportMode)mode captureTouches:(BOOL)shouldCaptureTouches;

/*!
 Order the text view to exit the 'single line viewport mode'. This restores the user's position and the appearance of
 the text view. If the text view was not already in this mode, this method does nothing.
 */
- (void)exitSingleLineViewportMode;

/*!
 Return a rect describing the bounds of the single line viewport if the text view were ordered to enter the single line
 mode with the current selection (by calling the \c enterSingleLineViewportMode method).
 */
- (CGRect)rectForSingleLineViewportInMode:(HKWViewportMode)mode;

#pragma mark - API (helper views)

/*!
 An optional property containing a block to be run whenever an accessory view is attached. The block should take two
 parameters: the accessory view and a boolean flag which is YES if the accessory view is free-floating, NO if it is a
 sibling view.
 */
@property (nonatomic, copy) void(^onAccessoryViewAttachmentBlock)(UIView *, BOOL);

/*!
 Attach an accessory view to the text editor as a sibling view. An accessory view floats 'above' the text editor view
 and intercepts touch events within its bounds. Only one accessory view can be attached at a time. Calling this method
 with an accessory view already attached is a no-op.
 */
- (void)attachSiblingAccessoryView:(UIView *)view position:(CGPoint)position;

/*!
 Attach an accessory view to the primary view of the key window's root view controller. This is suitable for 'floating'
 accessory views whose position is only loosely coupled to the position of the text view.
 */
- (void)attachFreeFloatingAccessoryView:(UIView *)view absolutePosition:(CGPoint)position;

/*!
 Detach a previously attached accessory view.

 \note If the view was not previously attached, this method does nothing.

 \warning After detachment the view's frame's origin will be relative to the origin of the text editor's superview,
 regardless of which method was used to attach the text view.
 */
- (void)detachAccessoryView:(UIView *)view;

/*!
 Allow a plug-in to set the custom top level view.
 */
- (void)setTopLevelViewForAccessoryViewPositioning:(UIView *)view;

#pragma mark - API (autocorrect)

/*!
 Whether or not the first responder is cycling. Host apps that respond to keyboard change events may need to
 conditionally execute behavior depending on whether or not the first responder is cycling.
 */
@property (nonatomic, readonly) BOOL firstResponderIsCycling;

/*!
 A property allowing a plug-in to inform the text view as to whether or not attempts by the autocorrect/predictive text
 system should be ignored.

 \warning This property is ignored if the abstraction layer is in use. The abstraction layer uses a different mechanism
 to accept or ignore attempted changes to the text view.
 */
@property (nonatomic) BOOL shouldRejectAutocorrectInsertions;

/*!
 If an autocorrect suggestion is currently being proposed, reject it. Otherwise, this method does nothing.
 */
- (void)dismissAutocorrectSuggestion;

/*!
 Temporarily override the text view's autocapitalization mode.
 */
- (void)overrideAutocapitalizationWith:(UITextAutocapitalizationType)override;

/*!
 If the text view's autocapitalization mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
 in the process of losing its first responder status
 */
- (void)restoreOriginalAutocapitalization:(BOOL)shouldCycle;

/*!
 Temporarily override the text view's autocorrection mode.
 */
- (void)overrideAutocorrectionWith:(UITextAutocorrectionType)override;

/*!
 If the text view's autocorrection mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
 in the process of losing its first responder status
 */
- (void)restoreOriginalAutocorrection:(BOOL)shouldCycle;

/*!
 Temporarily override the text view's spell checking mode.
 */
- (void)overrideSpellCheckingWith:(UITextSpellCheckingType)override;

/*!
 If the text view's spell checking mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
 in the process of losing its first responder status
 */
- (void)restoreOriginalSpellChecking:(BOOL)shouldCycle;


#pragma mark - API (misc)

/*!
 If the app explicitly set the text view font, or the text view was initialized from an XIB, return the most recent font
 set by the app. If the app never set the font, return nil.
 */
@property (nonatomic, readonly) UIFont *fontSetByApp;

/*!
 If the app explicitly set the text view's text color, or the text view was initialized from an XIB, return the most
 recent text color set by the app. If the app never set the text color, return nil.
 */
@property (nonatomic, readonly) UIColor *textColorSetByApp;

@end
