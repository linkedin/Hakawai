//
//  HKWMentionsStartDetectionStateMachine.h
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

@protocol HKWMentionsStartDetectionStateMachineProtocol <NSObject>

/*!
 Return a character set corresponding to the valid control characters, or nil if no control characters are enabled.
 */
- (NSCharacterSet *)controlCharacterSet;

/*!
 Return boolean indicating if implicit mentions search is enabled or not.
 */
- (BOOL)implicitMentionsSearchEnabled;

/*!
 Return the number of characters to wait before beginning an 'implicit' mention. If this is 0 or negative, implicit
 mentions will not be supported.
 */
- (NSInteger)implicitSearchLength;

/*!
 Activate the mentions creation process, using the provided string as a seed. The string may be zero length (e.g. if the
 user enters the special control character).

 \param prefix                     if an implicit mention, the characters the user already typed that should form part
                                   of the completed mention (if one is created)
 \param alreadyInserted            whether or not either the control character (if an explicit mention was created) or
                                   the prefix (if an implicit mention was created) was fully inserted into the text view
                                   buffer at the time the method was invoked
 \param usingControlCharacter      whether the mention was begun by the user typing a special control character
 \param controlCharacter           if \c usingControlCharacter is NO, ignored; otherwise, the control character used to
                                   begin the mention
 */
- (void)beginMentionsCreationWithString:(NSString *)prefix
                        alreadyInserted:(BOOL)alreadyInserted
                  usingControlCharacter:(BOOL)usingControlCharacter
                       controlCharacter:(unichar)character;

@end

/*!
 This class represents a state machine that monitors the text view and determines when it is appropriate to begin
 mentions creation. When mentions creation should begin, it calls the \c beginMentionsCreationWithString: method on its
 delegate. The delegate (or another parent object) is responsible for notifying the state machine when text view events
 happen, or when mentions creation is completed.
 */
@interface HKWMentionsStartDetectionStateMachine : NSObject

/*!
 Return a new, initialized state machine instance. The \c delegate argument is required and cannot be nil.
 */
+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsStartDetectionStateMachineProtocol>)delegate;

/*!
 Inform the state machine that a valid string was typed (or pasted, or auto-inserted) by the user into the text view.
 \param inserted    whether the string in question has already been inserted into the text view's buffer before this
                    method began executing
 */
- (void)validStringInserted:(NSString *)string alreadyInserted:(BOOL)inserted;

/*!
 Inform the state machine that a character was typed by the user into the text view.
 \param inserted    whether the character was already inserted into the text view's text buffer
 */
- (void)characterTyped:(unichar)c asInsertedCharacter:(BOOL)inserted;

/*!
 Inform the state machine that a character was deleted by the user from the text view.
 */
- (void)deleteTypedWithCharacterNowPrecedingCursor:(unichar)c;

/*!
 Inform the state machine that the cursor was moved from its prior position and is now in insertion mode.
 */
- (void)cursorMovedWithCharacterNowPrecedingCursor:(unichar)c;

/*!
 Inform the state machine that mention creation has ended and that it should begin watching again.
 */
- (void)mentionCreationEnded:(BOOL)canImmediatelyRestart;

/*!
 Inform the state machine that mention creation has manually resumed. Force the state machine into the 'Creating
 Mention' state.

 \warning Calling this method without actually starting mention creation will bring the state machine system into a bad
 state.
 */
- (void)mentionCreationResumed;

@end
