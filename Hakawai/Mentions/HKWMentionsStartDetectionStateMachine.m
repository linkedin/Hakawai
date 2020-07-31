//
//  HKWMentionsStartDetectionStateMachine.m
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
#import "_HKWMentionsStartDetectionStateMachine.h"

#import "_HKWPrivateConstants.h"

typedef NS_ENUM(NSInteger, HKWMentionsStartDetectionState) {
    // Initial state: the user may be able to create a mention
    HKWMentionsStartDetectionStateQuiescentReady = 0,

    // The user cancelled out of creating a mention, or created a new mention. They can't create a new mention unless
    //  they delete the entire word or start a new word.
    HKWMentionsStartDetectionStateQuiescentStalled,

    // The user is currently creating a mention. The host has control and will inform the state machine when the mention
    //  creation process is finished.
    HKWMentionsStartDetectionStateCreatingMention
};

typedef NS_ENUM(NSInteger, CharacterType) {
    // Characters of punctuation character set and whitespace and new line character set
    CharacterTypeSeparator = 0,

    // Characters of control character set
    CharacterTypeControlCharacter,

    // All characters other than characters of the other two character types
    CharacterTypeNormal
};

@interface HKWMentionsStartDetectionStateMachine ()

@property (nonatomic, weak) id<HKWMentionsStartDetectionStateMachineProtocol> delegate;

@property (nonatomic) HKWMentionsStartDetectionState state;
@property (nonatomic, readonly) BOOL inQuiescentState;
@property (nonatomic, readonly) BOOL inMentionCreationState;

@property (nonatomic) NSUInteger charactersSinceLastWhitespace;
@property (nonatomic, strong) NSMutableString *stringBuffer;

@property (nonatomic, readonly) BOOL implicitMentionsEnabled;

@property (nonatomic, strong, nonnull, class, readonly) NSCharacterSet *whitespaceSet;
@property (nonatomic, strong, nonnull, class, readonly) NSCharacterSet *punctuationSet;
@property (nonatomic, strong, nonnull, class, readonly) NSCharacterSet *separatorSet;

@end

@implementation HKWMentionsStartDetectionStateMachine

+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsStartDetectionStateMachineProtocol>)delegate {
    HKWMentionsStartDetectionStateMachine *sm = [[self class] new];
    sm.delegate = delegate;
    sm.state = HKWMentionsStartDetectionStateQuiescentReady;
    return sm;
}

-(void) resetStateUsingString:(NSString *)string {

    self.state = HKWMentionsStartDetectionStateQuiescentReady;
    self.charactersSinceLastWhitespace = 0;
    
    if (!string || string.length == 0) {
        self.stringBuffer = [@"" mutableCopy];
        
    } else {
        self.stringBuffer = [string mutableCopy];
        
        NSRange lastWhitespaceRange = [self.stringBuffer rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:NSBackwardsSearch];
        if (lastWhitespaceRange.location != NSNotFound && NSMaxRange(lastWhitespaceRange) <= self.stringBuffer.length) {
            self.charactersSinceLastWhitespace = self.stringBuffer.length - NSMaxRange(lastWhitespaceRange);
        }
    }
    
}

- (void)validStringInserted:(NSString *)string
                 atLocation:(NSUInteger)location
      usingControlCharacter:(BOOL)usingControlCharacter
           controlCharacter:(unichar)character {
    NSAssert([string length] > 0, @"Logic error: string is zero-length; it is the responsibility of the caller to \
             perform basic validation.");
    // State transition
    switch (self.state) {
        case HKWMentionsStartDetectionStateQuiescentReady: {
            // STATE: User is not creating mention, but can begin one
            if (self.implicitMentionsEnabled) {
                [self.stringBuffer appendString:string];
                self.charactersSinceLastWhitespace += [string length];
                __strong __auto_type delegate = self.delegate;
                NSAssert([delegate implicitSearchLength] >= 0, @"Internal error");
                if (self.charactersSinceLastWhitespace >= (NSUInteger)[delegate implicitSearchLength]) {
                    // The user has fired off enough characters to start a mention.
                    self.state = HKWMentionsStartDetectionStateCreatingMention;
                    [delegate beginMentionsCreationWithString:[self.stringBuffer copy]
                                                        atLocation:location
                                             usingControlCharacter:usingControlCharacter
                                                  controlCharacter:character];
                }
            }
            break;
        }
        case HKWMentionsStartDetectionStateQuiescentStalled: {
            // STATE: User is not creating mention, and can't start one without additional help
            // Note that inserting a new string does not help in this case, since the string can't contain whitespace
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // Don't do anything. Host determines whether input is invalid and when to stop creating mention.
            break;
        }
    }
}

- (void)characterTyped:(unichar)c
   asInsertedCharacter:(BOOL)inserted
     previousCharacter:(unichar)previousCharacter
wordFollowingTypedCharacter:(nullable NSString *)wordFollowingTypedCharacter {
    __strong __auto_type delegate = self.delegate;
    // Determine character types
    enum CharacterType currentCharacterType = [self characterTypeOfCharacter:c];
    enum CharacterType previousCharacterType = [self characterTypeOfCharacter:previousCharacter];

    // State transition
    switch (self.state) {
        case HKWMentionsStartDetectionStateQuiescentReady: {
            // STATE: User is not creating mention, but can begin one
            if (currentCharacterType == CharacterTypeNormal) {
                // User typed in a new character; we may need to start an IMPLICIT MENTION
                if (self.implicitMentionsEnabled) {
                    self.charactersSinceLastWhitespace++;
                    unichar stackC = c;
                    [self.stringBuffer appendString:[NSString stringWithCharacters:&stackC length:1]];
                    NSAssert([delegate implicitSearchLength] >= 0, @"Internal error");
                    if (self.charactersSinceLastWhitespace >= (NSUInteger)[delegate implicitSearchLength]) {
                        // The user has fired off enough characters to start a mention.
                        self.state = HKWMentionsStartDetectionStateCreatingMention;
                        [delegate beginMentionsCreationWithString:[self.stringBuffer copy]
                                                       alreadyInserted:inserted
                                                 usingControlCharacter:NO
                                                      controlCharacter:0];
                    }
                }
            }
            else if ((currentCharacterType == CharacterTypeControlCharacter)
                     && (previousCharacterType == CharacterTypeSeparator || previousCharacter == 0)) {
                if (previousCharacter == 0 || previousCharacterType == CharacterTypeSeparator) {
                    // Start an EXPLICIT MENTION
                    if (wordFollowingTypedCharacter) {
                        self.stringBuffer = [wordFollowingTypedCharacter mutableCopy];
                    } else if (previousCharacterType == CharacterTypeSeparator) {
                        self.stringBuffer = [@"" mutableCopy];
                    }
                    self.state = HKWMentionsStartDetectionStateCreatingMention;
                    [delegate beginMentionsCreationWithString:[self.stringBuffer copy]
                                                   alreadyInserted:inserted
                                             usingControlCharacter:YES
                                                  controlCharacter:c];
                }
            }
            else if ([HKWMentionsStartDetectionStateMachine.whitespaceSet characterIsMember:c]) {
                // User typed a whitespace/newline. Reset the counter.
                self.charactersSinceLastWhitespace = 0;
                self.stringBuffer = [@"" mutableCopy];
            }
            break;
        }
        case HKWMentionsStartDetectionStateQuiescentStalled: {
            // STATE: User is not creating mention, and can't start one without additional help
            if (currentCharacterType == CharacterTypeSeparator) {
                // User typed a whitespace or a punctuation character. This means they can now try to create a mention.
                self.state = HKWMentionsStartDetectionStateQuiescentReady;
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // Don't do anything. Host determines whether input is invalid and when to stop creating mention.
            break;
        }
    }
}

- (void)deleteTypedCharacter:(unichar)deletedChar
withCharacterNowPrecedingCursor:(unichar)precedingChar
                    location:(NSUInteger)location
                textViewText:(nonnull NSString *)textViewText {
    // Determine the character types
    enum CharacterType deletedCharacterType = [self characterTypeOfCharacter:deletedChar];
    enum CharacterType precedingCharacterType = [self characterTypeOfCharacter:precedingChar];

    __strong __auto_type delegate = self.delegate;

    switch (self.state) {
        case HKWMentionsStartDetectionStateQuiescentReady: {
            // Mention can be triggered upon character deletion:
            // 1. when deleted character location is greater than 1 -> When previous character is a control character and character before previous character is a separator.
            // 2. when deleted character location is 1 -> If preceding character is a control character
            // (NOTE: When deleted character location is 0, mentions is never triggered)
            BOOL canCreateMention = NO;
            if (location > 1 && textViewText.length > location - 2) {
                const unichar characterBeforePrecedingChar = [textViewText characterAtIndex:location - 2];
                canCreateMention = [HKWMentionsStartDetectionStateMachine.separatorSet characterIsMember:characterBeforePrecedingChar]
                && precedingCharacterType == CharacterTypeControlCharacter;
            } else if (precedingCharacterType == CharacterTypeControlCharacter) {
                canCreateMention = YES;
            }
            // If user deletes white-space or separators between control character and word, then query mention with word next to whitepace.
            if ((deletedCharacterType == CharacterTypeSeparator || deletedCharacterType == CharacterTypeControlCharacter) && canCreateMention) {
                if (location > 0 && location <= [textViewText length]) {
                    self.state = HKWMentionsStartDetectionStateCreatingMention;
                    NSString *const keyword = [HKWMentionsStartDetectionStateMachine wordAfterLocation:location + 1 text:textViewText];
                    [delegate beginMentionsCreationWithString:keyword
                                                   atLocation:location - 1
                                        usingControlCharacter:YES
                                             controlCharacter:precedingChar];
                }
            } else if (precedingCharacterType == CharacterTypeNormal) {
                if (self.charactersSinceLastWhitespace == 0) {
                    // Being here means the user deleted enough characters to move the cursor into the previous word.
                    self.state = HKWMentionsStartDetectionStateQuiescentStalled;
                }
                else {
                    // Remove a character from the buffer.
                    self.charactersSinceLastWhitespace--;
                    [self.stringBuffer deleteCharactersInRange:NSMakeRange([self.stringBuffer length]-1, 1)];
                }
            }
            else if ([HKWMentionsStartDetectionStateMachine.whitespaceSet characterIsMember:precedingChar]) {
                self.charactersSinceLastWhitespace = 0;
                self.stringBuffer = [@"" mutableCopy];
            }
            break;
        }
        case HKWMentionsStartDetectionStateQuiescentStalled: {
            // Change state to QuiescentReady when either:
            //   1. A whitespace character is encountered
            //   2. A NON-whitespace character is encountered and a whitespace character was deleted
            //   3. A punctuation character is encountered
            if (precedingCharacterType == CharacterTypeSeparator
                || deletedCharacterType == CharacterTypeSeparator) {
                self.state = HKWMentionsStartDetectionStateQuiescentReady;
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // Don't do anything.
            break;
        }
    }
}

- (void)cursorMovedWithCharacterNowPrecedingCursor:(unichar)c {
    // Determine the type of the character
    enum CharacterType currentCharacterType = [self characterTypeOfCharacter:c];
    switch (self.state) {
        case HKWMentionsStartDetectionStateQuiescentReady:
        case HKWMentionsStartDetectionStateQuiescentStalled: {
            // Reset the string buffer
            self.stringBuffer = [@"" mutableCopy];
            self.charactersSinceLastWhitespace = 0;
            if (currentCharacterType == CharacterTypeSeparator || currentCharacterType == CharacterTypeControlCharacter) {
                // The user moved the cursor to the beginning of the text region, or right after a newline or whitespace or punctuation
                //  character or control character. This puts the user in the ready state.
                self.state = HKWMentionsStartDetectionStateQuiescentReady;
            }
            else if (currentCharacterType == CharacterTypeNormal) {
                // The user moved the cursor to a place in the middle of a word. This puts the user in the stalled
                //  state.
                self.state = HKWMentionsStartDetectionStateQuiescentStalled;
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // Don't do anything.
            break;
        }
    }
}

- (void)mentionCreationEnded:(BOOL)canImmediatelyRestart {
    if (!HKWTextView.enableMentionsPluginV2) {
        // For the simple refactor, we only focus on cursor movement to determine when to start mention creation, and don't use the state machine to determine
        // the validity of this call
        NSAssert(self.inMentionCreationState,
                 @"mentionCreationEnded was called, but the state machine was not in the mention creation state.");
    }
    // User must type at least one space/newline to start a new mention.
    self.state = canImmediatelyRestart ? HKWMentionsStartDetectionStateQuiescentReady : HKWMentionsStartDetectionStateQuiescentStalled;
}

- (void)mentionCreationResumed {
    self.state = HKWMentionsStartDetectionStateQuiescentReady;
    self.state = HKWMentionsStartDetectionStateCreatingMention;
}

#pragma mark - Public helper method

/**
 Returns a word after a certain location until a delimiter (whitespace or newline) is found.
 Returns nil if no non-delimeter text is available.
 */
+ (nullable NSString *)wordAfterLocation:(NSUInteger)location text:(nonnull NSString *)text {
    NSMutableString *const word = [[NSMutableString alloc] init];
    for(NSUInteger i = location; i < text.length ; i++) {
        const unichar character = [text characterAtIndex:i];
        if ([HKWMentionsStartDetectionStateMachine.whitespaceSet characterIsMember:character]) {
            break;
        }
        [word appendString:[NSString stringWithCharacters:&character length:1]];
    }
    if (word.length == 0) {
        return nil;
    }
    return [word copy];
}

#pragma mark - Private helper method

- (CharacterType)characterTypeOfCharacter:(unichar)aCharacter {
    __auto_type __strong delegate = self.delegate;
    CharacterType characterType = CharacterTypeNormal;
    if ([HKWMentionsStartDetectionStateMachine.whitespaceSet characterIsMember:aCharacter] || aCharacter == 0) {
        characterType = CharacterTypeSeparator;
    } else {
        // Check first for control character because control character can be a separator.
        // e.g "@" and "#" are both control character and separator.
        NSCharacterSet *const controlCharacterSet = [delegate controlCharacterSet];
        if (controlCharacterSet && [controlCharacterSet characterIsMember:aCharacter]) {
            characterType = CharacterTypeControlCharacter;
        } else if ([HKWMentionsStartDetectionStateMachine.punctuationSet characterIsMember:aCharacter]) {
            characterType = CharacterTypeSeparator;
        }
    }
    return characterType;
}

#pragma mark - Properties and Constants

- (NSMutableString *)stringBuffer {
    if (!_stringBuffer) {
        _stringBuffer = [NSMutableString string];
    }
    return _stringBuffer;
}

- (BOOL)implicitMentionsEnabled {
    return [self.delegate implicitSearchLength] > 0;
}

/**
 Character set of whitespace and new line
 */
+ (nonnull NSCharacterSet *)whitespaceSet {
    static NSCharacterSet *whitespaceSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    });
    return whitespaceSet;
}

/**
 Character set of punctuations
 */
+ (nonnull NSCharacterSet *)punctuationSet {
    static NSCharacterSet *punctuationSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        punctuationSet = [NSCharacterSet punctuationCharacterSet];
    });
    return punctuationSet;
}

/**
 Union set of whitespace set and punctuation set whose contents are treated as separators
 Mentions trigger after these separators
 */
+ (nonnull NSCharacterSet *)separatorSet {
    static NSCharacterSet *separatorSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *const mutableSeparatorSet = [HKWMentionsStartDetectionStateMachine.punctuationSet mutableCopy];
        [mutableSeparatorSet formUnionWithCharacterSet:HKWMentionsStartDetectionStateMachine.whitespaceSet];
        separatorSet = [mutableSeparatorSet copy];
    });
    return separatorSet;
}


#pragma mark - State machine

- (BOOL)inQuiescentState {
    return !self.inMentionCreationState;
}

- (BOOL)inMentionCreationState {
    return (self.state == HKWMentionsStartDetectionStateCreatingMention);
}

- (void)setState:(HKWMentionsStartDetectionState)state {
    HKWMentionsStartDetectionState oldState = _state;
    // Validate state transitions.
    NSAssert(!(_state == HKWMentionsStartDetectionStateQuiescentStalled
               && state == HKWMentionsStartDetectionStateCreatingMention),
             @"State transition from Stalled --> CreatingMention is illegal.");
    [self willChangeValueForKey:@"state"];
    _state = state;
    [self didChangeValueForKey:@"state"];

    if (oldState == state) {
        // Do nothing, including state transition side effects, if the states are the same.
        return;
    }
    // State transition side effects
    if (state == HKWMentionsStartDetectionStateQuiescentReady) {
        self.charactersSinceLastWhitespace = 0;
        self.stringBuffer = [@"" mutableCopy];
    }
}


#pragma mark - Development

NSString *nameForStartDetectionState(HKWMentionsStartDetectionState s) {
    switch (s) {
        case HKWMentionsStartDetectionStateQuiescentReady:
            return @"QuiescentReady";
        case HKWMentionsStartDetectionStateQuiescentStalled:
            return @"QuiescentStalled";
        case HKWMentionsStartDetectionStateCreatingMention:
            return @"CreatingMention";
    }
}

@end
