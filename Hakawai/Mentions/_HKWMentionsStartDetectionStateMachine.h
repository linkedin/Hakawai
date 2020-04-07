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
 \param character                  if \c usingControlCharacter is NO, ignored; otherwise, the control character used to
                                   begin the mention
 */
- (void)beginMentionsCreationWithString:(NSString *)prefix
                        alreadyInserted:(BOOL)alreadyInserted
                  usingControlCharacter:(BOOL)usingControlCharacter
                       controlCharacter:(unichar)character;

/*!
 Activate the mentions creation process, using the provided string as a seed. The string may be zero length (e.g. if the
 user enters the special control character).

 \param prefix                     if an implicit mention, the characters the user already typed that should form part
                                   of the completed mention (if one is created)
 \param location                   the index in the textView which identifies the start of the target string (including
                                   the control char if present)
 \param usingControlCharacter      whether the mention was begun by the user typing a special control character
 \param character                  if \c usingControlCharacter is NO, ignored; otherwise, the control character used to
                                   begin the mention
 */
- (void)beginMentionsCreationWithString:(NSString *)prefix
                             atLocation:(NSUInteger)location
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
 \param string                   the string that is being analyzed in the text view (not including a control character
                                 if one exists)
 \param location                 the text view index of the \c character if present, or the start index of the \c string
                                 if a \c character is not present
 \param usingControlCharacter    whether the mention was begun by the user typing a special control character
 \param character                if \c usingControlCharacter is NO, ignored; otherwise, the control character used to
                                 begin the mention
 */
- (void)validStringInserted:(NSString *)string
                 atLocation:(NSUInteger)location
      usingControlCharacter:(BOOL)usingControlCharacter
           controlCharacter:(unichar)character;

/*!
 Inform the state machine that a character was typed by the user into the text view.
 \param c                                   Character typed
 \param inserted                            Whether the character was already inserted into the text view's text buffer
 \param previousCharacter                   Character preceding typed character
 \param wordFollowingTypedCharacter         Word following the typed character
 */
- (void)characterTyped:(unichar)c
   asInsertedCharacter:(BOOL)inserted
     previousCharacter:(unichar)previousCharacter
wordFollowingTypedCharacter:(NSString *)wordFollowingTypedCharacter;

/*!
 Inform the state machine that a character was deleted by the user from the text view.
 \param deletedChar                         Character to be deleted
 \param precedingChar                       Character before character to be deleted
 \param location                            Location of character to be deleted
 \param textViewText                        Text displayed by text view
 */
- (void)deleteTypedCharacter:(unichar)deletedChar
withCharacterNowPrecedingCursor:(unichar)precedingChar
                    location:(NSUInteger)location
                textViewText:(NSString *)textViewText;

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

/*!
 Inform the state machine that the attached control view has reset it's state, and now represents the specified string
 */
-(void) resetStateUsingString:(NSString *)string;

/*!
 Return characters after given location till whitespace is encountered.
 */
+ (NSString *)wordAfterLocation:(NSUInteger)location text:(NSString *)text;

@end
