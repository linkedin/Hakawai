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

#import "HKWMentionsCreationStateMachineDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 This class represents a state machine that manages the creation of mentions. In this case, 'mentions creation' is
 defined as either an active state in which the editor text view's viewport is locked and a list of potential mentions
 is displayed, or a passive state where mentions creation is stalled but the user is still eligible to resume mentions
 creation. The state machine also manages making requests to the data source and displaying the chooser list. The state
 machine should inform the host when mentions creation is canceled or completed.
 */
@interface HKWMentionsCreationStateMachine : NSObject

/**
 The background color of the chooser view.
 */
@property (nonatomic, strong) UIColor *chooserViewBackgroundColor;

/**
 The edge insets applied to the chooser view. Only valid if the chooser view isn't using a custom frame.
 */
@property (nonatomic) UIEdgeInsets chooserViewEdgeInsets;

/**
 The class of the chooser view to instantiate. Must be a subclass of the \c UIView class. If set to an invalid value or nil, defaults to the built-in chooser view.
 */
@property (nonatomic) Class<HKWChooserViewProtocol> chooserViewClass;

/**
 Character control search explicit inputted in the chooser view.
 Needs to be public for integration between Hakawai and HotPot.
*/
@property (nonatomic) unichar explicitSearchControlCharacter;

/**
 Informs the state machine typeahead results are returned, so it can update its internal state accordingly.
 */
- (void)dataReturnedWithEmptyResults:(BOOL)isEmptyResults
         keystringEndsWithWhiteSpace:(BOOL)keystringEndsWithWhiteSpace;
/**
 Inform the state machine that a single character was typed by the user into the text view.
 */
- (void)characterTyped:(unichar)c;

/**
 Inform the state machine that a valid string was inserted into the text view (no spaces, newlines, or forbidden
 characters).
 */
- (void)validStringInserted:(NSString *)string;

/**
 Inform the state machine that a character or string was deleted from the text view.
 */
- (void)stringDeleted:(NSString *)deleteString;

/**
 Inform the state machine that the cursor was moved from its prior position and is now in insertion mode.
 */
- (void)cursorMoved;

/**
 Inform the state machine that mention creation has started.

 \param prefix                   a string containing text that the user typed before mentions creation started, but
                                 should be used as a query string for asking the data source for suggestions
 \param usingControlCharacter    whether or not the mention was started by typing a special control character
 \param character                if \c usingControlCharacter is NO, this is ignored; otherwise, the control character
                                 used to begin the mention
 \param location                 the index position where the completed mention should begin
 */
- (void)mentionCreationStartedWithPrefix:(NSString *)prefix
                   usingControlCharacter:(BOOL)usingControlCharacter
                        controlCharacter:(unichar)character
                                location:(NSUInteger)location;

/**
 Inform the state machine that mention creation must stop immediately.
 */
- (void)cancelMentionCreation;

/**
 Setup chooser view if needed.
 */
- (void)setupChooserViewIfNeeded;

/**
 Completely reset the chooser view. This is useful if the parent plug-in is detached from its editor text view.
 */
- (void)resetChooserView;

/**
 If the chooser arrow is showing, hide it until the next time the chooser view appears after disappearing.
 */
- (void)hideChooserArrow;

/**
 Inform the state machine to trigger fetch for initial mentions
 */
- (void)fetchInitialMentions;

/**
 Get the chooser view frame. If the chooser view has not yet been instantiated, returns the nil rectangle.
 */
- (CGRect)chooserViewFrame;

/**
 A reference to the entity chooser view, or nil if it hasn't yet been instantiated.
 */
- (UIView<HKWChooserViewProtocol> *)getEntityChooserView;

/**
 Return a rect describing the frame that would be assigned to the chooser view if in one of the preset modes, or
 \c CGRectNull otherwise.
 */
- (CGRect)frameForMode:(HKWMentionsChooserPositionMode)mode;

/**
 Shows the chooser view.
 Needs to be public for integration between Hakawai and HotPot.
 */
- (void)showChooserView;

/**
 Handles the selection from the user.
 Needs to be public for integration between Hakawai and HotPot.
 // TODO: remove indexPath as it's no longer needed for tracking
 */
- (void)handleSelectionForEntity:(id<HKWMentionsEntityProtocol>)entity indexPath:(NSIndexPath *)indexPath;

/**
 Reload the results chooser view.
 This needs to be called when the results data is updated.
 */
- (void)reloadChooserView;

/**
 Return a new, initialized state machine instance, and let it know whether we are using a custom chooser view or not
 */
+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsCreationStateMachineDelegate>)delegate isUsingCustomChooserView:(BOOL)isUsingCustomChooserView;

@end

NS_ASSUME_NONNULL_END
