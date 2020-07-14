//
//  HKWAbstractionLayer.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

// 🍐 HAKAWAI TEXT VIEW ABSTRACTION LAYER 🍐 //

#import <UIKit/UIKit.h>

#import "HKWAbstractionLayer.h"

/*!
 An enum describing the states the state machine can be in.
 
 \c HKWAbstractionLayerStateQuiescent means the state machine is quiescent.
 
 \c HKWAbstractionLayerStateShouldChangeCalled means the \c textViewShouldChangeTextInRange:replacementText: method was
 previously called.
 
 \c HKWAbstractionLayerStateDidChangeSelectionCalled means the \c textViewDidChangeSelection method was previously
 called.

 \c HKWAbstractionLayerStateDidChangeCalled means the \c textViewDidChange method was previously called, but everything
 was properly addressed.

 \c HKWAbstractionLayerStateDidChangePendingUpdate means that the \c textViewDidChange method was previously called, and
 a potential insertion occured. This state is used to distinguish between the user inserting characters directly through
 the IME keyboard bar (e.g. without typing in pinyin), and the user's changes causing prospective text to change when
 using the handwriting keyboard.
 */
typedef NS_ENUM(NSInteger, HKWAbstractionLayerState) {
    HKWAbstractionLayerStateQuiescent,
    // NOTE: we currently don't handle the case where the delegate rejects the proposed text. There should be a
    //  separate mechanism for rejecting changes to the text.
    HKWAbstractionLayerStateShouldChangeCalled,
    HKWAbstractionLayerStateDidChangeSelectionCalled,
    HKWAbstractionLayerStateDidChangeCalled,
    HKWAbstractionLayerStateDidChangePendingUpdate
};

/*!
 An enum describing the state of text marking for this particular editing run.

 \c HKWAbstractionLayerMarkStateNone means that text has never been marked during this run.

 \c HKWAbstractionLayerMarkStateMarked means that text is currently marked.

 \c HKWAbstractionLayerMarkStatePreviouslyMarked means the text is not currently marked, but had been marked at some
    point during this run.
 */
typedef NS_ENUM(NSInteger, HKWAbstractionLayerMarkState) {
    HKWAbstractionLayerMarkStateNone,
    HKWAbstractionLayerMarkStateMarked,
    HKWAbstractionLayerMarkStatePreviouslyMarked
};

/*!
 An enum describing potential changes that might be made to the text view's text.
 */
typedef NS_ENUM(NSInteger, HKWAbstractionLayerChangeType) {
    HKWAbstractionLayerChangeTypeInsertion,
    HKWAbstractionLayerChangeTypeDeletion,
    HKWAbstractionLayerChangeTypeReplacement,
    HKWAbstractionLayerChangeTypeNone
};

/*!
 An enum describing the text input mode.
 */
typedef NS_ENUM(NSInteger, HKWAbstractionLayerInputMode) {
    HKWAbstractionLayerInputModeAlphabetical,
    HKWAbstractionLayerInputModeChinese,
    HKWAbstractionLayerInputModeJapanese,
    HKWAbstractionLayerInputModeKorean
};

@interface HKWAbstractionLayer ()

@property (nonatomic, weak) UITextView *parentTextView;

@property (nonatomic) HKWAbstractionLayerState state;
@property (nonatomic) HKWAbstractionLayerMarkState markState;
@property (nonatomic, readonly) HKWAbstractionLayerInputMode inputMode;

@property (nonatomic, readwrite) NSUInteger ignoreStackDepth;
@property (nonatomic, readonly) BOOL shouldIgnore;

@property (nonatomic) NSRange previousSelectedRange;
@property (nonatomic) NSUInteger previousTextLength;

/*!
 A range used to track the text view's selection range when IME entry began; this is necessary to properly report where
 text was replaced when the user ends up selecting a character or canceling the IME process.
 */
@property (nonatomic) NSRange selectedRangeWhenMarkingStarted;
@property (nonatomic) NSUInteger textLengthWhenMarkingStarted;
@property (nonatomic) BOOL lastMarkedCharactersJustDeleted;

/*!
 A range that describes the range of text the user last selected. It is used to determine what text was changed if the
 user selects some text, and then chooses a replacement string presented by an IME keyboard.
 
 Invariant: if the user changed the text cursor to insertion mode this property will always contain the null range;
 otherwise it will always contain a range corresponding to the location and length of the user's most recent text
 selection.
 */
@property (nonatomic) NSRange selectedRangeWhenTextWasLastSelected;

/*!
 The length of the text view's text at the time that the \c selectedRangeWhenTextWasLastSelected property was most
 recently updated with a valid value.
 */
@property (nonatomic) NSUInteger textLengthWhenTextWasLastSelected;

/*!
 If the state machine is in 'pending update' mode (trying to distinguish between the user drawing characters on a
 handwriting keyboard, and the user directly selecting options from an IME keyboard's menu), this range describes the
 number and location of characters that were inserted by the user selection.
 */
@property (nonatomic) NSRange pendingUpdateMarkRange;

// Properties for determining whether typing a space after the insertion of a predictive suggestion is actually
//  committed to the text buffer. (For example, choosing 'The', inserting 'The ', and then typing a space will almost
//  certainly cause the space to not appear.)
@property (nonatomic) BOOL lastChangeWasSpaceInsertion;
@property (nonatomic) NSUInteger textLengthWhenSpaceWasInserted;

// User change tracking properties. These properties are used to determine what type of change (insertion, replacement,
//  deletion, etc) is made in response to user input.
@property (nonatomic) HKWAbstractionLayerChangeType changeType;
@property (nonatomic, strong) NSString *changeString;
@property (nonatomic) NSRange changeRange;
@property (nonatomic) BOOL changeIsPaste;

@property (nonatomic) BOOL changeRejectionEnabled;
@property (nonatomic, strong) NSAttributedString *previousText;

@end

@implementation HKWAbstractionLayer

+ (instancetype)instanceWithTextView:(UITextView *)textView changeRejection:(BOOL)enabled {
    if (!textView) {
        return nil;
    }
    HKWAbstractionLayer *layer = [self new];
    [layer setupWithTextView:textView changeRejection:enabled];
    return layer;
}

- (void)setupWithTextView:(UITextView *)textView changeRejection:(BOOL)enabled {
    self.parentTextView = textView;
    self.ignoreStackDepth = 0;

    // State-related
    self.state = HKWAbstractionLayerStateQuiescent;
    self.changeType = HKWAbstractionLayerChangeTypeNone;
    self.markState = HKWAbstractionLayerMarkStateNone;
    self.selectedRangeWhenTextWasLastSelected = (textView.selectedRange.length > 0
                                                 ? textView.selectedRange
                                                 : NSMakeRange(NSNotFound, 0));
    self.textLengthWhenTextWasLastSelected = (textView.selectedRange.length > 0
                                              ? [textView.text length]
                                              : 0);
    self.pendingUpdateMarkRange = NSMakeRange(NSNotFound, 0);
    self.previousSelectedRange = textView.selectedRange;
    self.previousTextLength = [textView.text length];

    self.changeRejectionEnabled = enabled;
    if (enabled) {
        self.previousText = [textView.attributedText copy];
    }
}

- (void)pushIgnore {
    self.ignoreStackDepth++;
}

- (void)popIgnore {
    if (self.ignoreStackDepth == 0) {
        return;
    }
    self.ignoreStackDepth--;
    if (self.ignoreStackDepth == 0) {
        [self textViewDidProgrammaticallyUpdate];
    }
}

- (BOOL)shouldIgnore {
    return self.ignoreStackDepth > 0;
}


#pragma mark - Change notifications

- (void)textViewDidProgrammaticallyUpdate {
    UITextView *textView = self.parentTextView;
    if (!textView) {
        return;
    }
    self.state = HKWAbstractionLayerStateQuiescent;
    self.markState = HKWAbstractionLayerMarkStateNone;
    self.previousTextLength = [textView.attributedText length];
    self.previousSelectedRange = textView.selectedRange;
    if (self.changeRejectionEnabled) {
        self.previousText = [textView.attributedText copy];
    }
}

- (BOOL)textViewShouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text wasPaste:(BOOL)wasPaste {
//    NSLog(@"textViewShouldChangeTextInRange:... called. Replacement: '%@', location: %ld, length: %ld; marked text: %@; text view text: '%@'",
//          text, range.location, range.length, self.parentTextView.markedTextRange, self.parentTextView.text);
//    NSLog(@"  > The current input mode is %@", [HKWAbstractionLayer nameForMode:self.inputMode]);

    // Note that the only way we can be marked at this point is if the previous cycle ended with text still marked.
    if (self.shouldIgnore) {
        return YES;
    }
    __strong __auto_type parentTextView = self.parentTextView;
    BOOL currentlyMarked = (parentTextView.markedTextRange != nil);

    self.lastChangeWasSpaceInsertion = NO;

    switch (self.state) {
        case HKWAbstractionLayerStateQuiescent:
            // This only happens if the user makes a change to the text while it is unmarked, OR if the user commits to
            //  text for the handwriting-based keyboard.
            self.state = HKWAbstractionLayerStateShouldChangeCalled;
            // The user made a change to the text. Note that we can't report it immediately, because we don't yet know
            //  if the text is going to be marked.
            if ([text length] == 0 && range.length > 0) {
                // User deleted text
                if (self.shouldIgnoreNextCharacterDeletion
                    && range.length == 1) {
                    self.shouldIgnoreNextCharacterDeletion = NO;
                    self.state = HKWAbstractionLayerStateQuiescent;
                    __strong __auto_type delegate = self.delegate;
                    if ([delegate respondsToSelector:@selector(textView:characterDeletionWasIgnoredAtLocation:)]) {
                        [delegate textView:parentTextView characterDeletionWasIgnoredAtLocation:range.location];
                    }
                    return NO;
                }
                self.changeType = HKWAbstractionLayerChangeTypeDeletion;
                self.changeRange = range;
                self.changeString = [parentTextView.text substringWithRange:range];
                self.changeIsPaste = wasPaste;
            }
            else if ([text length] > 0 && range.length == 0) {
                // User inserted text
                self.changeType = HKWAbstractionLayerChangeTypeInsertion;
                self.changeRange = NSMakeRange(range.location, 0);
                self.changeString = text;
                self.lastChangeWasSpaceInsertion = [HKWAbstractionLayer changeIsSpaceInsertion:text range:range];
                self.textLengthWhenSpaceWasInserted = [parentTextView.text length];
            }
            else if (range.length > 0 && [text length] > 0) {
                // User replaced text
                self.changeType = HKWAbstractionLayerChangeTypeReplacement;
                self.changeRange = range;
                self.changeString = text;
                self.changeIsPaste = wasPaste;
            }
            else {
                // No change (e.g. user tapped backspace when there was no text)
                self.state = HKWAbstractionLayerStateQuiescent;
                return YES;
            }
            break;
        case HKWAbstractionLayerStateShouldChangeCalled:
            NSAssert(self.markState == HKWAbstractionLayerMarkStateNone, @"Internal error");
            NSAssert(!currentlyMarked, @"Internal error");
            if (self.changeType == HKWAbstractionLayerChangeTypeInsertion) {
                // This only happens when the two-space-to-period feature is invoked
                // In this case, the original change (insert a [second] space) is discarded, and replaced with the new
                //  update
                NSAssert([self.changeString length] == 1, @"Internal error");
                if ([text length] > 0 && range.length > 0) {
                    // Discard the previous insertion
                    self.changeType = HKWAbstractionLayerChangeTypeReplacement;
                    self.changeRange = range;
                    self.changeString = text;
                }
                else {
                    NSAssert(NO, @"Internal error: unsupported state");
                }
                self.state = HKWAbstractionLayerStateShouldChangeCalled;
                break;
            }
            // Otherwise, fall through (this can happen if changes are disabled and the user taps a predictive
            //  suggestion)
        case HKWAbstractionLayerStateDidChangeSelectionCalled:
            // This only happens if a predictive suggestion completes or replaces existing text; it allows the space
            //  following the word to be inserted
            NSAssert(self.markState == HKWAbstractionLayerMarkStateNone, @"Internal error");
            NSAssert([text length] > 0, @"Internal error");
            NSAssert(!currentlyMarked, @"Internal error");
            switch (self.changeType) {
                case HKWAbstractionLayerChangeTypeInsertion:
                case HKWAbstractionLayerChangeTypeReplacement:
                    if (range.location == self.changeRange.location + [self.changeString length]) {
                        // This is the space following the word
                        self.changeString = [self.changeString stringByAppendingString:text];
                    }
                    else {
                        // If we get here, the user has attempted to select a predictive autocorrect suggestion to
                        //  complete a word right after a change is rejected. Even though we ask the text view to insert
                        //  the word, it won't. The abstraction layer chooses to report the actual behavior.
                        // EXAMPLE: We type in 'T', then we set the delegate to reject changes and type in 'h' and 'a'
                        //  (both of which won't actually show up). Then we select "That'll" from the suggestions. Even
                        //  though the text view delegate will attempt to insert "That'll" and " ", only the " " will
                        //  actually be committed to the buffer.
                        self.changeType = HKWAbstractionLayerChangeTypeInsertion;
                        self.changeString = text;
                        self.changeRange = range;
                        // TODO: Figure out why the initial change isn't being committed. Is this a problem with the
                        //  abstraction layer or an OS issue?
                    }
                    break;
                case HKWAbstractionLayerChangeTypeDeletion:
                case HKWAbstractionLayerChangeTypeNone:
                    NSAssert(NO, @"Internal error: unsupported state");
                    break;
            }
            self.state = HKWAbstractionLayerStateShouldChangeCalled;
            break;
        case HKWAbstractionLayerStateDidChangeCalled:
            // This only happens if the user was in marked text (IME) mode during the last cycle. In this case, we don't
            //  do anything significant. However, we do need to check if the last marked characters were deleted so we
            //  can handle it properly later.
            NSAssert(self.markState != HKWAbstractionLayerMarkStateNone, @"Internal error");
            self.lastMarkedCharactersJustDeleted = NO;
            if ([text length] == 0
                && range.length > 0
                && parentTextView.markedTextRange) {
                // We're in marked text mode. We need to check if the last character is going to be deleted, and if it
                //  is, raise a special flag so that textViewDidChange can distinguish between behaviors.
                NSRange markedRange = [self markedTextRange];
                if (markedRange.length == range.length) {
                    // We are deleting as many characters as there are marked characters left over
                    self.lastMarkedCharactersJustDeleted = YES;
                }
            }
            self.state = HKWAbstractionLayerStateShouldChangeCalled;
            self.markState = (currentlyMarked
                              ? HKWAbstractionLayerMarkStateMarked
                              : HKWAbstractionLayerMarkStatePreviouslyMarked);
            break;
        case HKWAbstractionLayerStateDidChangePendingUpdate:
            NSAssert(NO, @"Internal error: illegal state transition");
            break;
    }
    return YES;
}

- (void)textViewDidChangeSelection {
    if (self.shouldIgnore) {
        return;
    }
    __strong __auto_type parentTextView = self.parentTextView;
    NSRange selectedRange = parentTextView.selectedRange;
//    NSLog(@"textViewDidChangeSelection called. New selected range: location: %ld, length: %ld; marked text: %@; parent text: '%@'",
//          selectedRange.location, selectedRange.length, self.parentTextView.markedTextRange, self.parentTextView.text);

    BOOL previouslyMarked = self.markState == HKWAbstractionLayerMarkStateMarked;
    BOOL cursorActuallyMoved = !NSEqualRanges(selectedRange, self.previousSelectedRange);
    BOOL currentlyMarked = (parentTextView.markedTextRange != nil);

    if (currentlyMarked) {
        self.changeType = HKWAbstractionLayerChangeTypeNone;
    }

     __strong __auto_type delegate = self.delegate;
    switch (self.state) {
        case HKWAbstractionLayerStateQuiescent:
            if (currentlyMarked) {
                // The user moved the cursor while text was marked for IME entry. We don't report this, and we don't
                //  change the state either.
                break;
            }
            else if (selectedRange.length == 0 && cursorActuallyMoved) {
                // The user moved the cursor and it's in insertion mode
                self.selectedRangeWhenTextWasLastSelected = NSMakeRange(NSNotFound, 0);
                if ([delegate respondsToSelector:@selector(textView:cursorChangedToInsertion:)]) {
                    [delegate textView:parentTextView cursorChangedToInsertion:selectedRange.location];
                }
            }
            else if (selectedRange.length > 0 && cursorActuallyMoved) {
                // The user moved the cursor and selected text
                self.selectedRangeWhenTextWasLastSelected = selectedRange;
                self.textLengthWhenTextWasLastSelected = [parentTextView.text length];
                if ([delegate respondsToSelector:@selector(textView:cursorChangedToSelection:)]) {
                    [delegate textView:parentTextView cursorChangedToSelection:selectedRange];
                }
            }
            break;
        case HKWAbstractionLayerStateShouldChangeCalled:
            // This is the selection change immediately following textViewShouldChangeTextAtRange:...
            self.state = HKWAbstractionLayerStateDidChangeSelectionCalled;
            if (self.lastChangeWasSpaceInsertion &&
                [parentTextView.text length] == self.textLengthWhenSpaceWasInserted) {
                NSAssert(self.changeType == HKWAbstractionLayerChangeTypeInsertion, @"Internal error");
                // The space the user tried to insert was overridden somehow, and we shouldn't report it
                self.lastChangeWasSpaceInsertion = NO;
                self.textLengthWhenSpaceWasInserted = 0;
                self.changeType = HKWAbstractionLayerChangeTypeNone;
            }
            break;
        case HKWAbstractionLayerStateDidChangeSelectionCalled:
            // Ignore this
            self.state = HKWAbstractionLayerStateDidChangeSelectionCalled;
            break;
        case HKWAbstractionLayerStateDidChangeCalled:
            self.state = HKWAbstractionLayerStateDidChangeSelectionCalled;
            break;
        case HKWAbstractionLayerStateDidChangePendingUpdate:
            // At this point we can determine whether the pending update corresponds to the user drawing stuff (ignore),
            //  or the user directly selecting an option on the IME keyboard bar (report).
            if (currentlyMarked) {
                // User drawing stuff; don't allow it to be reported.
                self.state = HKWAbstractionLayerStateDidChangeSelectionCalled;
            }
            else {
                // Leave state as is; change will be reported imminently.
            }
            break;
    }

    // Update mark state
    if (currentlyMarked) {
        if (!previouslyMarked) {
            // We entered marked text mode.
            // Store the selected range. This is necessary, for example, if the user selected some text and then
            //  replaced it with pinyin.
            self.selectedRangeWhenMarkingStarted = self.previousSelectedRange;
            self.textLengthWhenMarkingStarted = self.previousTextLength;
        }
        self.markState = HKWAbstractionLayerMarkStateMarked;
    }
    else if ((!currentlyMarked && previouslyMarked)
             || self.markState == HKWAbstractionLayerMarkStatePreviouslyMarked) {
        self.markState = HKWAbstractionLayerMarkStatePreviouslyMarked;
    }
    else {
        self.markState = HKWAbstractionLayerMarkStateNone;
    }
    self.previousSelectedRange = selectedRange;
    self.previousTextLength = [parentTextView.text length];
}

- (void)textViewDidChange {
    if (self.shouldIgnore) {
        return;
    }
//    NSLog(@"textViewDidChange called. Marked text: %@; parent text: '%@'",
//          self.parentTextView.markedTextRange, self.parentTextView.text);

    // Update the marked text state before running logic
    __strong __auto_type parentTextView = self.parentTextView;
    __strong __auto_type delegate = self.delegate;
    BOOL previouslyMarked = self.markState == HKWAbstractionLayerMarkStateMarked;
    BOOL currentlyMarked = (parentTextView.markedTextRange != nil);
    if (currentlyMarked) {
        self.markState = HKWAbstractionLayerMarkStateMarked;
    }
    else if ((!currentlyMarked && previouslyMarked)
             || self.markState == HKWAbstractionLayerMarkStatePreviouslyMarked) {
        self.markState = HKWAbstractionLayerMarkStatePreviouslyMarked;
    }
    else {
        self.markState = HKWAbstractionLayerMarkStateNone;
    }

    switch (self.state) {
        case HKWAbstractionLayerStateQuiescent: {
            if (self.lastMarkedCharactersJustDeleted) {
                self.lastMarkedCharactersJustDeleted = NO;
                // This is called as a result of having deleted the last marked characters. (This is the second call of
                //  this method, following the 'main' call that runs through the large
                //  HKWAbstractionLayerStateDidChangeSelectionCalled switch statement.) We should just ignore it.
            }
            else if (currentlyMarked) {
                BOOL textWasPreviouslySelected = self.selectedRangeWhenTextWasLastSelected.location != NSNotFound;
                NSAssert([self markedTextRange].length > 0,
                         @"Internal error: text cannot be currently marked with a mark range length of 0");
                if (textWasPreviouslySelected) {
                    // The user selected text and has chosen replacement CJK text using an IME keyboard.
                    NSUInteger location = self.selectedRangeWhenTextWasLastSelected.location;
                    NSAssert(self.selectedRangeWhenTextWasLastSelected.length > 0, @"Internal error");
                    NSInteger lengthDelta = (NSInteger)[parentTextView.text length] - (NSInteger)self.textLengthWhenTextWasLastSelected;
                    NSInteger newLength = (NSInteger)self.selectedRangeWhenTextWasLastSelected.length + lengthDelta;
                    NSAssert(newLength > 0, @"Internal error");
                    if ([delegate respondsToSelector:@selector(textView:replacedTextAtRange:newText:autocorrect:)]) {
                        NSString *newText = [parentTextView.text substringWithRange:NSMakeRange(location, (NSUInteger)newLength)];
                        BOOL shouldChange = [delegate textView:parentTextView
                                           replacedTextAtRange:self.selectedRangeWhenTextWasLastSelected
                                                       newText:newText
                                                   autocorrect:NO];
                        if (self.changeRejectionEnabled) {
                            if (shouldChange) {
                                self.previousText = [parentTextView.attributedText copy];
                            }
                            else {
                                parentTextView.attributedText = [self.previousText copy];
                                self.state = HKWAbstractionLayerStateQuiescent;
                            }
                        }
                    }
                    // Reset the trigger. The user has to manually select another piece of text before this option can
                    //  execute again.
                    self.selectedRangeWhenTextWasLastSelected = NSMakeRange(NSNotFound, 0);
                }
                else {
                    // Without being in marked text mode the user has selected one or more characters from the IME
                    //  keyboard menu. OR the user is writing characters using the handwriting keyboard. We put the
                    //  state machine in this provisional state. The next time textViewDidChangeSelection is called, its
                    //  code will be able to disambiguate the two cases.
                    self.pendingUpdateMarkRange = [self markedTextRange];
                    self.state = HKWAbstractionLayerStateDidChangePendingUpdate;
                }
            }
            break;
        }
        case HKWAbstractionLayerStateShouldChangeCalled:
            NSAssert(NO, @"Internal error: illegal state transition");
            break;
        case HKWAbstractionLayerStateDidChangeSelectionCalled:
            // Note that only at this point do we report many of the state changes.
            // Note that if the text is still in the marked state, we never do anything.
            switch (self.markState) {
                case HKWAbstractionLayerMarkStateNone: {
                    // The non-IME case: an IME was NOT involved during this editing run; just report the changes as
                    //  expected.
                    switch (self.changeType) {
                        case HKWAbstractionLayerChangeTypeInsertion:
                            if ([delegate respondsToSelector:@selector(textView:textInserted:atLocation:autocorrect:)]) {
                                NSAssert([self.changeString length] > 0, @"Internal error");
                                BOOL shouldChange = [delegate textView:parentTextView
                                                          textInserted:self.changeString
                                                            atLocation:self.changeRange.location
                                                           autocorrect:!self.changeIsPaste];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                            break;
                        case HKWAbstractionLayerChangeTypeDeletion:
                            if ([delegate respondsToSelector:@selector(textView:textDeletedFromLocation:length:)]) {
                                BOOL shouldChange = [delegate textView:parentTextView
                                               textDeletedFromLocation:self.changeRange.location
                                                                length:[self.changeString length]];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                            break;
                        case HKWAbstractionLayerChangeTypeReplacement:
                            if ([delegate respondsToSelector:@selector(textView:replacedTextAtRange:newText:autocorrect:)]) {
                                BOOL shouldChange = [delegate textView:parentTextView
                                                   replacedTextAtRange:self.changeRange
                                                               newText:self.changeString
                                                           autocorrect:!self.changeIsPaste];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                            break;
                        case HKWAbstractionLayerChangeTypeNone:
                            // TODO: make sure that ignoring this is acceptable.
                            break;
                    }
                    self.changeType = HKWAbstractionLayerChangeTypeNone;
                    self.state = HKWAbstractionLayerStateQuiescent;
                    break;
                }
                case HKWAbstractionLayerMarkStateMarked:
                    // The user typed a character or deleted a character and is still in marked text mode. Do nothing.
                    // NOTE: We don't return to the quiescent state yet. While the user is in marked text mode, they
                    //  always remain in one of the intermediate states. This gives subsequent editing runs a hint that
                    //  they should behave differently.
                    self.state = HKWAbstractionLayerStateDidChangeCalled;
                    break;
                case HKWAbstractionLayerMarkStatePreviouslyMarked:
                    // The user completed marked text mode. They may have done one of several things:
                    //  * Chosen a character after entering some roman letters
                    //  * Deleted all marked text, exiting marked text mode
                    //  * Cancelled marked text mode by tapping/selecting text outside the marked region; this turns the
                    //    marked text into normal text
                    NSAssert(self.selectedRangeWhenMarkingStarted.location != NSNotFound, @"Internal error");
                    BOOL textWasSelectedWhenMarkingStarted = (self.selectedRangeWhenMarkingStarted.length > 0);
                    NSUInteger currentTextLength = [parentTextView.text length];

                    if (textWasSelectedWhenMarkingStarted) {
                        // The user started out with text selected
                        NSInteger textLengthAfterDeletion = (NSInteger)self.textLengthWhenMarkingStarted - (NSInteger)self.selectedRangeWhenMarkingStarted.length;
                        NSInteger start = (NSInteger)self.selectedRangeWhenMarkingStarted.location;
                        if ((NSInteger)currentTextLength == textLengthAfterDeletion) {
                            // The user deleted all the marked mode text. Notify of deletion.
                            if ([delegate respondsToSelector:@selector(textView:textDeletedFromLocation:length:)]) {
                                NSUInteger length = self.selectedRangeWhenMarkingStarted.length;
                                BOOL shouldChange = [delegate textView:parentTextView
                                               textDeletedFromLocation:(NSUInteger)start
                                                                length:length];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                        }
                        else {
                            // Replacement of text.
                            NSAssert((NSInteger)currentTextLength > textLengthAfterDeletion, @"Internal error");
                            NSInteger length = (NSInteger)currentTextLength - textLengthAfterDeletion;
                            NSString *insertedText = [parentTextView.text substringWithRange:NSMakeRange((NSUInteger)start, (NSUInteger)length)];
                            if ([delegate respondsToSelector:@selector(textView:replacedTextAtRange:newText:autocorrect:)]) {
                                NSRange markingRange = self.selectedRangeWhenMarkingStarted;
                                BOOL shouldChange = [delegate textView:parentTextView
                                                   replacedTextAtRange:markingRange
                                                               newText:insertedText
                                                           autocorrect:NO];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                        }
                    }
                    else {
                        // The user started out in insertion mode
                        if (currentTextLength == self.textLengthWhenMarkingStarted) {
                            // The user deleted all the marked mode text. Nothing should be done.
                        }
                        else {
                            // Insertion of text.
                            NSAssert(currentTextLength > self.textLengthWhenMarkingStarted, @"Internal error");
                            NSUInteger start = self.selectedRangeWhenMarkingStarted.location;
                            NSUInteger length = currentTextLength - self.textLengthWhenMarkingStarted;
                            NSString *insertedText = [parentTextView.text substringWithRange:NSMakeRange(start, length)];
                            if ([delegate respondsToSelector:@selector(textView:textInserted:atLocation:autocorrect:)]) {
                                BOOL shouldChange = [delegate textView:parentTextView
                                                          textInserted:insertedText
                                                            atLocation:start
                                                           autocorrect:NO];
                                if (self.changeRejectionEnabled) {
                                    if (shouldChange) {
                                        self.previousText = [parentTextView.attributedText copy];
                                    }
                                    else {
                                        parentTextView.attributedText = [self.previousText copy];
                                        self.state = HKWAbstractionLayerStateQuiescent;
                                    }
                                }
                            }
                        }
                    }

                    // Reset state
                    self.state = HKWAbstractionLayerStateQuiescent;
                    self.markState = HKWAbstractionLayerMarkStateNone;
                    self.selectedRangeWhenMarkingStarted = NSMakeRange(NSNotFound, 0);
                    self.textLengthWhenMarkingStarted = 0;
                    break;
            }

            break;
        case HKWAbstractionLayerStateDidChangeCalled:
            NSAssert(NO, @"Internal error: illegal state transition");
            break;
        case HKWAbstractionLayerStateDidChangePendingUpdate: {
            // If we get here, this means the user tapped an option on the IME keyboard's bar or menu, bypassing (e.g.)
            //  inputting pinyin. We should report an insertion.
            NSUInteger location = self.pendingUpdateMarkRange.location;
            NSAssert(location != NSNotFound, @"Internal error");
            NSString *newText = [parentTextView.text substringWithRange:self.pendingUpdateMarkRange];
            if ([delegate respondsToSelector:@selector(textView:textInserted:atLocation:autocorrect:)]) {
                BOOL shouldChange = [delegate textView:parentTextView
                                          textInserted:newText
                                            atLocation:location
                                           autocorrect:NO];
                if (self.changeRejectionEnabled) {
                    if (shouldChange) {
                        self.previousText = [parentTextView.attributedText copy];
                    }
                    else {
                        parentTextView.attributedText = [self.previousText copy];
                        self.state = HKWAbstractionLayerStateQuiescent;
                    }
                }
            }
            self.state = HKWAbstractionLayerStateQuiescent;
            break;
        }
    }
}


#pragma mark - Private helper methods

- (HKWAbstractionLayerInputMode)inputMode {
    UITextInputMode *mode = self.parentTextView.textInputMode;
    if (!mode) {
        // emoji on iOS 7
        return HKWAbstractionLayerInputModeAlphabetical;
    }
    NSString *language = mode.primaryLanguage;
    if ([language length] < 2) {
        // This is probably a system error...
        NSAssert(NO, @"Internal error: input mode language is invalid (%@)", language);
        return HKWAbstractionLayerInputModeAlphabetical;
    }
    NSString *code = [language substringToIndex:2];
    if ([code isEqualToString:@"zh"]) {
        return HKWAbstractionLayerInputModeChinese;
    }
    else if ([code isEqualToString:@"ja"]) {
        return HKWAbstractionLayerInputModeJapanese;
    }
    else if ([code isEqualToString:@"ko"]) {
        return HKWAbstractionLayerInputModeKorean;
    }
    return HKWAbstractionLayerInputModeAlphabetical;
}

/*!
 Return whether or not a prospective text insertion (e.g. shouldChangeText...) corresponds to the insertion of a single
 whitespace character (newlines are excluded).
 */
+ (BOOL)changeIsSpaceInsertion:(NSString *)text range:(NSRange)range {
    return (range.length == 0
            && [text length] == 1
            && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[text characterAtIndex:0]]);
}

/*!
 Return an \c NSRange struct representing the marked text range for the parent text view if both exist, or the standard
 error range otherwise.
 */
- (NSRange)markedTextRange {
    __strong __auto_type parentTextView = self.parentTextView;
    UITextRange *markedRange = parentTextView.markedTextRange;
    if (!markedRange || !parentTextView) {
        return NSMakeRange(NSNotFound, 0);
    }
    NSInteger start = [parentTextView offsetFromPosition:parentTextView.beginningOfDocument
                                              toPosition:markedRange.start];
    NSInteger end = [parentTextView offsetFromPosition:parentTextView.beginningOfDocument
                                            toPosition:markedRange.end];
    NSAssert(end >= start, @"Internal error: marked text range is inconsistent; this is an OS error");
    return NSMakeRange((NSUInteger)start, (NSUInteger)(end - start));
}


#pragma mark - Private developer methods

+ (NSString *)nameForState:(HKWAbstractionLayerState)state {
    switch (state) {
        case HKWAbstractionLayerStateQuiescent:
            return @"Quiescent";
        case HKWAbstractionLayerStateShouldChangeCalled:
            return @"ShouldChangeCalled";
        case HKWAbstractionLayerStateDidChangeSelectionCalled:
            return @"DidChangeSelectionCalled";
        case HKWAbstractionLayerStateDidChangeCalled:
            return @"DidChangeCalled";
        case HKWAbstractionLayerStateDidChangePendingUpdate:
            return @"DidChangePendingUpdate";
    }
}

+ (NSString *)nameForMode:(HKWAbstractionLayerInputMode)mode {
    switch (mode) {
        case HKWAbstractionLayerInputModeAlphabetical:
            return @"Alphabetical";
        case HKWAbstractionLayerInputModeChinese:
            return @"Chinese";
        case HKWAbstractionLayerInputModeJapanese:
            return @"Japanese";
        case HKWAbstractionLayerInputModeKorean:
            return @"Korean";
    }
}

@end
