//
//  HKWMentionsCreationStateMachine.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <Foundation/Foundation.h>

#import "HKWChooserViewProtocol.h"
#import "HKWTextView.h"
#import "HKWTextView+Plugins.h"
#import "HKWMentionsPlugin.h"

@class HKWMentionsAttribute;

@protocol HKWMentionsCreationStateMachineProtocol <HKWMentionsDelegate>

/*!
 Get whether or not the host app supports displaying a loading cell.
 */
@property (nonatomic, readonly) BOOL loadingCellSupported;

/*!
 Request the bounds of the editor text view owning the delegate.
 */
- (CGRect)boundsForParentEditorView;

/*!
 Request the origin of the editor text view owning the delegate.
 */
- (CGPoint)originForParentEditorView;

/*!
 Request that the delegate attach a view to the parent editor text view at the specified origin. If sibling mode, the
 origin should be relative to the parent editor text view's frame (as if the view were to be added as a subview). If
 in free-floating mode, the origin should be relative to the topmost view in the view hierarchy.
 */
- (void)attachViewToParentEditor:(UIView *)view origin:(CGPoint)origin mode:(HKWAccessoryViewMode)mode;

/*!
 Inform the delegate that the accessory view is about to be activated or deactivated.
 */
- (void)accessoryViewStateWillChange:(BOOL)activated;

/*!
 Inform the delegate that the accessory view has been activated or deactivated.
 */
- (void)accessoryViewActivated:(BOOL)activated;

/*!
 Inform the delegate that a new mention annotation should be created. Relevant metadata are contained in the \c mention
 argument. This method also moves the editor view out of the mention creation state.
 */
- (void)createMention:(HKWMentionsAttribute *)mention startingLocation:(NSUInteger)location;

/*!
 Inform the delegate that the editor view should move out of the mention creation state without adding a new mention
 annotation.
 */
- (void)cancelMentionFromStartingLocation:(NSUInteger)location;

- (HKWMentionsChooserPositionMode)chooserPositionMode;

- (CGFloat)heightForSingleLineViewport;

/*!
 Return the position of the center of the chooser cursor, relative to the text view itself.
 */
- (CGFloat)positionForChooserCursorRelativeToView:(UIView *)view atLocation:(NSUInteger)location;

@end

/*!
 This class represents a state machine that manages the creation of mentions. In this case, 'mentions creation' is
 defined as either an active state in which the editor text view's viewport is locked and a list of potential mentions
 is displayed, or a passive state where mentions creation is stalled but the user is still eligible to resume mentions
 creation. The state machine also manages making requests to the data source and displaying the chooser list. The state
 machine should inform the host when mentions creation is canceled or completed.
 */
@class HKWDefaultChooserView;
@interface HKWMentionsCreationStateMachine : NSObject

/// The background color of the chooser view.
@property (nonatomic, strong) UIColor *chooserViewBackgroundColor;

/// The edge insets applied to the chooser view. Only valid if the chooser view isn't using a custom frame.
@property (nonatomic) UIEdgeInsets chooserViewEdgeInsets;

/// The class of the chooser view to instantiate. Must be a subclass of the \c UIView class. If set to an invalid value
/// or nil, defaults to the built-in chooser view.
@property (nonatomic) Class<HKWChooserViewProtocol> chooserViewClass;

/*!
 Return a new, initialized state machine instance.
 */
+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsCreationStateMachineProtocol>)delegate;

/*!
 Inform the state machine that a single character was typed by the user into the text view.
 */
- (void)characterTyped:(unichar)c;

/*!
 Inform the state machine that a valid string was inserted into the text view (no spaces, newlines, or forbidden
 characters).
 */
- (void)validStringInserted:(NSString *)string;

/*!
 Inform the state machine that a character or string was deleted from the text view.
 */
- (void)stringDeleted:(NSString *)deleteString;

/*!
 Inform the state machine that the cursor was moved from its prior position and is now in insertion mode.
 */
- (void)cursorMoved;

/*!
 Inform the state machine that mention creation has started.

 \param prefix                   a string containing text that the user typed before mentions creation started, but
                                 should be used as a query string for asking the data source for suggestions
 \param usingControlCharacter    whether or not the mention was started by typing a special control character
 \param controlCharacter         if \c usingControlCharacter is NO, this is ignored; otherwise, the control character
                                 used to begin the mention
 \param location                 the index position where the completed mention should begin
 */
- (void)mentionCreationStartedWithPrefix:(NSString *)prefix
                   usingControlCharacter:(BOOL)usingControlCharacter
                        controlCharacter:(unichar)character
                                location:(NSUInteger)location;

/*!
 Inform the state machine that mention creation must stop immediately.
 */
- (void)cancelMentionCreation;

/*!
 Completely reset the chooser view. This is useful if the parent plug-in is detached from its editor text view.
 */
- (void)resetChooserView;

/*!
 If the chooser arrow is showing, hide it until the next time the chooser view appears after disappearing.
 */
- (void)hideChooserArrow;

/*!
 Get the chooser view frame. If the chooser view has not yet been instantiated, returns the nil rectangle.
 */
- (CGRect)chooserViewFrame;

/*!
 A reference to the entity chooser view, or nil if it hasn't yet been instantiated.
 */
- (UIView<HKWChooserViewProtocol> *)getEntityChooserView;

/*!
 Return a rect describing the frame that would be assigned to the chooser view if in one of the preset modes, or
 \c CGRectNull otherwise.
 */
- (CGRect)frameForMode:(HKWMentionsChooserPositionMode)mode;

@end
