//
//  HKWAbstractionLayer.h
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
#import <UIKit/UIKit.h>

/*!
 Known issues:
 - Proper handling of Korean input is currently not implemented.
 - Double-space after entering Japanese text results in a notification that a space was replaced with two spaces, not
   two insertions of one space each.
 */

/*!
 A protocol implemented by abstraction layer delegates wishing to be informed whenever user input modifies the text view
 text or the selection range.
 */
@protocol HKWAbstractionLayerDelegate <NSObject>

@optional

/*!
 Inform the delegate that text was non-destructively inserted at a given location.

 \param text        the string that was inserted; if the string is of length '1', a single character was typed
 \param location    the location within the text view's buffer where the text was inserted. For example, if the buffer
                    was formerly "hello", and is now "helloworld", location would be 5
 \returns           whether or not the change should be accepted (note that this only works if the layer was configured
                    to allow change rejection when initialized)
 */
- (BOOL)textView:(UITextView *)textView
    textInserted:(NSString *)text
      atLocation:(NSUInteger)location
     autocorrect:(BOOL)autocorrect;

/*!
 Inform the delegate that one or more characters were deleted.

 \param location    the location from which the characters were deleted. For example, if the buffer was formerly
                    "hello", and is now "he", location would be 5
 \param length      the number of characters that were deleted
 \returns           whether or not the change should be accepted (note that this only works if the layer was configured
                    to allow change rejection when initialized)
 */
- (BOOL)textView:(UITextView *)textView textDeletedFromLocation:(NSUInteger)location length:(NSUInteger)length;

/*!
 Inform the delegate that a string was inserted s.t. some text that was already in the buffer was replaced.

 \returns           whether or not the change should be accepted (note that this only works if the layer was configured
                    to allow change rejection when initialized)
 */
- (BOOL)textView:(UITextView *)textView replacedTextAtRange:(NSRange)replacementRange
         newText:(NSString *)newText
     autocorrect:(BOOL)autocorrect;

/*!
 Inform the delegate that the cursor was moved to a given location, and is in 'insertion' mode (no text is currently
 being selected).

 \note This method only fires if the user manually moves the cursor. It is not triggered if the cursor moves as part of
 an insertion, deletion, or replacement operation.
 */
- (void)textView:(UITextView *)textView cursorChangedToInsertion:(NSUInteger)location;

/*!
 Inform the delegate that some amount of text was selected by the user.

 \note This method only fires if the user manually moves the cursor. It is not triggered if the cursor moves as part of
 an insertion, deletion, or replacement operation.
 */
- (void)textView:(UITextView *)textView cursorChangedToSelection:(NSRange)selectionRange;

/*!
 Inform the delegate that character deletion was ignored.
 */
- (void)textView:(UITextView *)textView characterDeletionWasIgnoredAtLocation:(NSUInteger)location;

@end

@interface HKWAbstractionLayer : NSObject

@property (nonatomic, weak) id<HKWAbstractionLayerDelegate> delegate;

/*!
 Return a new instance of the abstraction layer
 \param textView    the \c UITextView or subclass (e.g. HKWTextView) which the layer should sit atop
 \param enabled     whether or not to enable the change rejection feature (the delegate can choose to reject changes,
                    but this requires extra memory consumption to store the text state)
 */
+ (instancetype)instanceWithTextView:(UITextView *)textView changeRejection:(BOOL)enabled;

/*!
 Push a token onto the 'ignore' stack. As long as there are tokens on the ignore stack, none of the abstraction layer
 delegate methods will be fired.

 \warning The ignore stack feature is meant for ignoring transient changes to the text view, and the push/pop methods
 should not be called in the middle of an editing run. (An editing run is defined to encompass the method calls which
 are fired in rapid succession when a discrete user change is made.)
 */
- (void)pushIgnore;

/*!
 Pop a token off the 'ignore' stack.
 */
- (void)popIgnore;

/// The depth of the ignore stack.
@property (nonatomic, readonly) NSUInteger ignoreStackDepth;

/*!
 Set this to YES to ignore the next single-character deletion; it will automatically reset to NO after this happens.
 */
@property (nonatomic) BOOL shouldIgnoreNextCharacterDeletion;

- (void)textViewDidProgrammaticallyUpdate;
- (BOOL)textViewShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)textViewDidChangeSelection;
- (void)textViewDidChange;

@end
