//
//  HKWMentionsCreationStateMachine.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWMentionsCreationStateMachine.h"

#import "HKWChooserViewProtocol.h"
#import "_HKWDefaultChooserView.h"
#import "HKWMentionsAttribute.h"

#import "_HKWMentionsPrivateConstants.h"

/*!
 States for the master state machine.
 */
typedef NS_ENUM(NSInteger, HKWMentionsCreationState) {
    // The state machine is currently not creating a mention.
    HKWMentionsCreationStateQuiescent = 0,
    // The state machine is currently in the process of creating a mention, or is stalled.
    HKWMentionsCreationStateCreatingMention
};

/*!
 States for the network state subsidiary state machine.
 */
typedef NS_ENUM(NSInteger, HKWMentionsCreationNetworkState) {
    // The user is currently quiescent. The host will inform the state machine when mentions creation should start
    //  again. Slaved to HKWMentionsCreationStateQuiescent - DO NOT SET STATE TO THIS DIRECTLY.
    HKWMentionsCreationNetworkStateQuiescent = 0,

    // The mentions creation system is ready: data has been populated, and the system is waiting for the user to type
    //  a character, select a mention, or perform another action.
    HKWMentionsCreationNetworkStateReady,

    // The mentions creation system is ready, but the rate-limiting timer is still active.
    HKWMentionsCreationNetworkStateTimerCooldown,

    // The mentions creation system is ready, the rate-limiting timer is still active, and another request needs to be
    //  made once it expires.
    HKWMentionsCreationNetworkStatePendingRequestAfterCooldown,
};

/*!
 States for the mentions suggestion results subsidiary state machine.
 */
typedef NS_ENUM(NSInteger, HKWMentionsCreationResultsState) {
    // The mentions creation system is not active. Slaved to HKWMentionsCreationStateQuiescent - DO NOT SET STATE TO
    //  THIS DIRECTLY.
    HKWMentionsCreationResultsStateQuiescent = 0,

    // The mentions creation system is awaiting the result to the initial query.
    HKWMentionsCreationResultsStateAwaitingFirstResult,

    // The mentions creation system is creating a mention, and there is currently at least one result the user can
    //  select from.
    HKWMentionsCreationResultsStateCreatingMentionWithResults,

    // The mentions creation system is creating a mention, there are no results for the current query string, and the
    //  user has not typed a whitespace since the first contiguous query that returned no results.
    HKWMentionsCreationResultsStateNoResultsWithoutWhitespace
};

typedef NS_ENUM(NSInteger, HKWMentionsCreationChooserState) {
    HKWMentionsCreationChooserStateHidden = 0,
    HKWMentionsCreationChooserStateVisible
};

typedef NS_ENUM(NSInteger, HKWMentionsCreationAction) {
    HKWMentionsCreationActionNone = 0,
    HKWMentionsCreationActionNormalCharacterInserted,
    HKWMentionsCreationActionWhitespaceCharacterInserted,
    HKWMentionsCreationActionCharacterDeleted
};

@interface HKWMentionsCreationStateMachine () <HKWCustomChooserViewDelegate>

@property (nonatomic, weak) id<HKWMentionsCreationStateMachineProtocol> delegate;

@property (nonatomic, strong) NSTimer *cooldownTimer;
@property (nonatomic, readonly) NSTimeInterval cooldownPeriod;

/// A sequence number used by the state machine to disambiguate data provided by callbacks as valid or expired. The
/// sequence number monotonically increases.
@property (nonatomic) NSUInteger sequenceNumber;

@property (nonatomic) HKWMentionsCreationState state;
@property (nonatomic) HKWMentionsCreationNetworkState networkState;
@property (nonatomic) HKWMentionsCreationResultsState resultsState;
@property (nonatomic) HKWMentionsCreationChooserState chooserState;

@property (nonatomic, strong) UIView<HKWChooserViewProtocol> *entityChooserView;

/// An array serving as a backing store for the chooser table view; it contains objects representing mentions entities
/// that the user can select from.
@property (nonatomic) NSArray *entityArray;

@property (nonatomic) NSUInteger startingLocation;

/// What the last relevant action the user took within the text view was.
@property (nonatomic) HKWMentionsCreationAction lastTriggerAction;

/// Whether or not at least one set of results has been returned for the current query string.
@property (nonatomic) BOOL firstResultReturnedForCurrentQuery;

/// Whether or not the results for the current query string are 'finalized', i.e. attempts to append more results should
/// be ignored.
@property (nonatomic) BOOL currentQueryIsComplete;

@property (nonatomic) HKWMentionsSearchType searchType;
@property (nonatomic) unichar explicitSearchControlCharacter;

/*!
 A buffer containing the text typed by the user since mentions creation began, used to query the data source for
 potential matches.
 */
@property (nonatomic, strong) NSMutableString *stringBuffer;

@property (nonatomic, readonly) BOOL chooserViewInsideTextView;

@end

@implementation HKWMentionsCreationStateMachine

// NOTE: Do not remove these
@synthesize chooserViewBackgroundColor = _chooserViewBackgroundColor;

#pragma mark - API

+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsCreationStateMachineProtocol>)delegate {
    NSAssert(delegate != nil, @"Cannot create state machine with nil delegate.");
    HKWMentionsCreationStateMachine *sm = [[self class] new];
    sm.chooserViewClass = [HKWDefaultChooserView class];
    sm.sequenceNumber = 0;
    sm.delegate = delegate;
    sm.state = HKWMentionsCreationStateQuiescent;
    sm.chooserViewEdgeInsets = UIEdgeInsetsZero;
    return sm;
}

- (void)characterTyped:(unichar)c {
    BOOL isNewline = [[NSCharacterSet newlineCharacterSet] characterIsMember:c];
    BOOL isWhitespace = [[NSCharacterSet whitespaceCharacterSet] characterIsMember:c];

    // Preprocessing if the user types a whitespace character
    switch (self.resultsState) {
        case HKWMentionsCreationResultsStateQuiescent:
        case HKWMentionsCreationResultsStateCreatingMentionWithResults:
            break;
        case HKWMentionsCreationResultsStateAwaitingFirstResult:
        case HKWMentionsCreationResultsStateNoResultsWithoutWhitespace:
            // If the user types a whitespace when there are no results, cancel mentions creation
            if (isWhitespace) {
                self.state = HKWMentionsCreationStateQuiescent;
                [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
                return;
            }
    }
    if ([self.stringBuffer length] == 0 && isWhitespace) {
        self.state = HKWMentionsCreationStateQuiescent;
        [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
        return;
    }
    unichar stackC = c;
    NSString *characterString = [NSString stringWithCharacters:&stackC length:1];
    [self stringInserted:characterString isWhitespace:isWhitespace isNewline:isNewline];
}

- (void)validStringInserted:(NSString *)string {
    [self stringInserted:string isWhitespace:NO isNewline:NO];
}

- (void)stringInserted:(NSString *)string isWhitespace:(BOOL)isWhitespace isNewline:(BOOL)isNewline {
    NSAssert([string length] > 0, @"String must be nonzero length.");

    // State transition
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateQuiescent:
            // User not creating a mention right now.
            return;
        case HKWMentionsCreationNetworkStateReady: {
            // User is creating a mention, and can fire off a network request immediately if necessary.
            if (isNewline) {
                // User ended mention creation by typing a newline
                self.state = HKWMentionsCreationStateQuiescent;
                [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
            }
            else {
                [self.stringBuffer appendString:string];
                // Fire off the request and start the timer
                self.sequenceNumber += 1;
                NSUInteger sequenceNumber = self.sequenceNumber;
                __weak typeof(self) __self = self;

                // Start the cooldown timer and fire off a request
                [self activateCooldownTimer];
                [self.delegate asyncRetrieveEntitiesForKeyString:[self.stringBuffer copy]
                                                      searchType:self.searchType
                                                controlCharacter:self.explicitSearchControlCharacter
                                                      completion:^(NSArray *results, BOOL dedupe, BOOL isComplete) {
                                                          [__self dataReturnedWithResults:results
                                                                           sequenceNumber:sequenceNumber
                                                                            triggerAction:(isWhitespace
                                                                                           ? HKWMentionsCreationActionWhitespaceCharacterInserted
                                                                                           : HKWMentionsCreationActionNormalCharacterInserted)
                                                                            dedupeResults:dedupe
                                                                      dataFetchIsComplete:isComplete];
                                                      }];
            }
            break;
        }
        case HKWMentionsCreationNetworkStateTimerCooldown:
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            self.lastTriggerAction = (isWhitespace
                                      ? HKWMentionsCreationActionWhitespaceCharacterInserted
                                      : HKWMentionsCreationActionNormalCharacterInserted);
            // User is creating a mention, but the cooldown timer is active
            if (isNewline) {
                // User ended mention creation by typing a newline
                self.state = HKWMentionsCreationStateQuiescent;
                [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
            }
            else {
                [self.stringBuffer appendString:string];
                // Move the state to 'pending request'. This will cause another request to be fired as soon as the
                //  timer expires.
                self.networkState = HKWMentionsCreationNetworkStatePendingRequestAfterCooldown;
            }
            break;
    }
}

- (void)stringDeleted:(NSString *)deleteString {
    // State transition
    NSAssert([deleteString length] > 0, @"Logic error: string to be deleted must not be empty.");

    // Whether or not the buffer is empty (no characters to search upon).
    // Note that, if the mention is an explicit mention (use control character), user can back out to beginning. But if
    //  the mention is implicit, backing out to the beginning will cancel mentions creation.
    BOOL bufferAlreadyEmpty = ([self.stringBuffer length] == 0
                               || (self.searchType == HKWMentionsSearchTypeImplicit
                                   && [self.stringBuffer length] == 1));
    
    // The range of the buffer string that corresponds to the delete string (if the delete string is valid)
    NSRange toDeleteRange = NSMakeRange([self.stringBuffer length] - [deleteString length], [deleteString length]);

    // If YES, the deletion string is a 'transient' that should be ignored
    BOOL deleteStringIsTransient = NO;
    if ([self.stringBuffer length] == 0) {
        // Don't treat the delete string as transient if the buffer is actually empty
    }
    else if ([deleteString length] > [self.stringBuffer length]) {
        NSString *trimmedDeleteString = [deleteString substringWithRange:NSMakeRange([deleteString length] - [self.stringBuffer length],
                                                                                     [self.stringBuffer length])];
        deleteStringIsTransient = ![trimmedDeleteString isEqualToString:self.stringBuffer];
    }
    else {
        NSString *trimmedStringBuffer = [self.stringBuffer substringWithRange:toDeleteRange];
        deleteStringIsTransient = ![trimmedStringBuffer isEqualToString:deleteString];
    }

    // Switch on the overall state
    switch (self.state) {
        case HKWMentionsCreationStateQuiescent:
            // User not creating a mention right now
            return;
        case HKWMentionsCreationStateCreatingMention:
            if (deleteStringIsTransient) {
                // Delete was typed, but for some sort of transient state (e.g. keyboard suggestions); don't do anything
                return;
            }
            else if ([deleteString length] > [self.stringBuffer length]) {
                // Delete will completely clear out the string buffer
                [self cursorMoved];
                return;
            }
            else if (bufferAlreadyEmpty) {
                // User ended mentions creation by deleting enough characters to completely remove the mention
                self.state = HKWMentionsCreationStateQuiescent;
                [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
                return;
            }
            break;
    }

    // Switch on the results state (for now, only to ensure consistency)
    switch (self.resultsState) {
        case HKWMentionsCreationResultsStateQuiescent:
            NSAssert(NO, @"Results state was Quiescent when main state was not Quiescent");
            return;
        case HKWMentionsCreationResultsStateAwaitingFirstResult:
        case HKWMentionsCreationResultsStateCreatingMentionWithResults:
        case HKWMentionsCreationResultsStateNoResultsWithoutWhitespace:
            break;
    }

    // Switch on the network state
    NSAssert(!deleteStringIsTransient && !bufferAlreadyEmpty,
             @"At this point, we must be in a state where we can create a smaller buffer and search on that");
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateQuiescent:
            NSAssert(NO, @"Network state was Quiescent when main state was not Quiescent");
            return;
        case HKWMentionsCreationNetworkStateReady: {
            // The user hasn't completely backed out of mentions creation, so we can continue firing requests.
            // Remove a character from the buffer and immediately fire a request
            [self.stringBuffer deleteCharactersInRange:toDeleteRange];
            // Fire off the request and start the timer
            self.sequenceNumber += 1;
            NSUInteger sequenceNumber = self.sequenceNumber;
            __weak typeof(self) __self = self;

            // Start the cooldown timer and fire off a request
            [self activateCooldownTimer];
            [self.delegate asyncRetrieveEntitiesForKeyString:[self.stringBuffer copy]
                                                  searchType:self.searchType
                                            controlCharacter:self.explicitSearchControlCharacter
                                                  completion:^(NSArray *results, BOOL dedupe, BOOL isComplete) {
                                                      [__self dataReturnedWithResults:results
                                                                       sequenceNumber:sequenceNumber
                                                                        triggerAction:HKWMentionsCreationActionCharacterDeleted
                                                                        dedupeResults:dedupe
                                                                  dataFetchIsComplete:isComplete];
                                                  }];
            break;
        }
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
        case HKWMentionsCreationNetworkStateTimerCooldown:
            self.lastTriggerAction = HKWMentionsCreationActionCharacterDeleted;
            // Remove a character from the buffer and queue a request
            [self.stringBuffer deleteCharactersInRange:toDeleteRange];
            self.networkState = HKWMentionsCreationNetworkStatePendingRequestAfterCooldown;
            break;
    }
}

- (void)cursorMoved {
    // State transition
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateQuiescent:
            // User not creating a mention right now.
            return;
        case HKWMentionsCreationNetworkStateReady:
        case HKWMentionsCreationNetworkStateTimerCooldown:
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            // If the user moves their cursor, mentions creation automatically ends.
            self.state = HKWMentionsCreationStateQuiescent;
            [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
            break;
    }
}

- (void)mentionCreationStartedWithPrefix:(NSString *)prefix
                   usingControlCharacter:(BOOL)usingControlCharacter
                        controlCharacter:(unichar)character
                                location:(NSUInteger)location {
    if (self.networkState != HKWMentionsCreationNetworkStateQuiescent) {
        return;
    }
    self.state = HKWMentionsCreationStateCreatingMention;
    self.searchType = usingControlCharacter ? HKWMentionsSearchTypeExplicit : HKWMentionsSearchTypeImplicit;
    self.explicitSearchControlCharacter = usingControlCharacter ? character : 0;

    self.stringBuffer = [prefix mutableCopy];
    NSAssert(location != NSNotFound, @"Cannot start mentions creation with NSNotFound as starting location.");
    self.startingLocation = location;

    // Fire off the request and start the timer
    self.sequenceNumber += 1;
    NSUInteger sequenceNumber = self.sequenceNumber;
    __weak typeof(self) __self = self;

    // Prepare state
    self.resultsState = HKWMentionsCreationResultsStateAwaitingFirstResult;

    // Start the timer and fire off a request
    self.networkState = HKWMentionsCreationNetworkStateReady;
    [self activateCooldownTimer];
    [self.delegate asyncRetrieveEntitiesForKeyString:prefix
                                          searchType:self.searchType
                                    controlCharacter:self.explicitSearchControlCharacter
                                          completion:^(NSArray *results, BOOL dedupe, BOOL isComplete) {
                                              [__self dataReturnedWithResults:results
                                                               sequenceNumber:sequenceNumber
                                                                triggerAction:HKWMentionsCreationActionNone
                                                                dedupeResults:dedupe
                                                          dataFetchIsComplete:isComplete];
                                          }];
}

- (void)cancelMentionCreation {
    if (self.networkState == HKWMentionsCreationNetworkStateQuiescent) {
        return;
    }
    self.state = HKWMentionsCreationStateQuiescent;
    [self.delegate cancelMentionFromStartingLocation:0];
}

- (void)resetChooserView {
    self.state = HKWMentionsCreationStateQuiescent;
    self.entityChooserView = nil;
    self.entityArray = nil;
}

- (void)hideChooserArrow {
    if ([self.entityChooserView respondsToSelector:@selector(setInsertionPointMarkerEnabled:)]) {
        self.entityChooserView.insertionPointMarkerEnabled = NO;
    }
}

- (UIView<HKWChooserViewProtocol> *)getEntityChooserView {
    if (_entityChooserView) {
        return _entityChooserView;
    }
    return nil;
}


#pragma mark - Chooser View Frame

+ (BOOL)modeConfiguresArrowPointingUp:(HKWMentionsChooserPositionMode)mode {
    return (mode == HKWMentionsChooserPositionModeEnclosedTop
            || mode == HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
            || mode == HKWMentionsChooserPositionModeCustomLockBottomArrowPointingUp
            || mode == HKWMentionsChooserPositionModeCustomNoLockArrowPointingUp);
}

+ (BOOL)modeConfiguresArrowPointingDown:(HKWMentionsChooserPositionMode)mode {
    return (mode == HKWMentionsChooserPositionModeEnclosedBottom
            || mode == HKWMentionsChooserPositionModeCustomLockTopArrowPointingDown
            || mode == HKWMentionsChooserPositionModeCustomLockBottomArrowPointingDown
            || mode == HKWMentionsChooserPositionModeCustomNoLockArrowPointingDown);
}

+ (BOOL)modeRequiresCustomFrame:(HKWMentionsChooserPositionMode)mode {
    return (mode != HKWMentionsChooserPositionModeEnclosedTop && mode != HKWMentionsChooserPositionModeEnclosedBottom);
}

- (CGRect)chooserViewFrame {
    if (!_entityChooserView) {
        return CGRectNull;
    }
    return self.entityChooserView.frame;
}

- (CGRect)frameForMode:(HKWMentionsChooserPositionMode)mode {
    CGRect chooserFrame = [self.delegate boundsForParentEditorView];
    CGFloat viewportHeight = [self.delegate heightForSingleLineViewport];

    if (mode == HKWMentionsChooserPositionModeEnclosedTop) {
        chooserFrame.size.height -= viewportHeight;
        chooserFrame.origin.y = viewportHeight;
        // Inset corrections
        chooserFrame.size.width -= (self.chooserViewEdgeInsets.left + self.chooserViewEdgeInsets.right);
        chooserFrame.size.height -= (self.chooserViewEdgeInsets.top + self.chooserViewEdgeInsets.bottom);
        chooserFrame.origin.x += self.chooserViewEdgeInsets.left;
        chooserFrame.origin.y += self.chooserViewEdgeInsets.top;
    }
    else if (mode == HKWMentionsChooserPositionModeEnclosedBottom) {
        chooserFrame.size.height -= viewportHeight;
        chooserFrame.origin.y = 0;
        // Inset corrections
        chooserFrame.size.width -= (self.chooserViewEdgeInsets.left + self.chooserViewEdgeInsets.right);
        chooserFrame.size.height -= (self.chooserViewEdgeInsets.top + self.chooserViewEdgeInsets.bottom);
        chooserFrame.origin.x += self.chooserViewEdgeInsets.left;
        chooserFrame.origin.y += self.chooserViewEdgeInsets.top;
    }
    else {
        chooserFrame = CGRectNull;
    }
    return chooserFrame;
}


#pragma mark - Private (chooser view related)

- (void)showChooserView {
    [self.delegate accessoryViewStateWillChange:YES];

    self.chooserState = HKWMentionsCreationChooserStateVisible;
    [self.entityChooserView becomeVisible];
    if ([self.entityChooserView respondsToSelector:@selector(setInsertionPointMarkerEnabled:)]) {
        self.entityChooserView.insertionPointMarkerEnabled = YES;
    }
    HKWAccessoryViewMode mode = (self.chooserViewInsideTextView
                                 ? HKWAccessoryViewModeSibling
                                 : HKWAccessoryViewModeFreeFloating);
    [self.delegate attachViewToParentEditor:self.entityChooserView
                                     origin:self.entityChooserView.frame.origin
                                       mode:mode];
    [self.delegate accessoryViewActivated:YES];

    // Move the chooser cursor to the right position
    CGFloat newPosition = [self.delegate positionForChooserCursorRelativeToView:self.entityChooserView
                                                                     atLocation:self.startingLocation];
    if ([self.entityChooserView respondsToSelector:@selector(moveInsertionPointMarkerToXPosition:)]) {
        [self.entityChooserView moveInsertionPointMarkerToXPosition:newPosition];
    }
}

- (void)hideChooserView {
    [self.delegate accessoryViewStateWillChange:NO];
    [self.entityChooserView resetScrollPositionAndHide];
    [self.delegate accessoryViewActivated:NO];
}

- (UIView<HKWChooserViewProtocol> *)createNewChooserView {
    HKWMentionsChooserPositionMode mode = [self.delegate chooserPositionMode];
    CGRect chooserFrame = [self frameForMode:mode];
    // Handle the case where the chooser frame is completely custom
    if ([HKWMentionsCreationStateMachine modeRequiresCustomFrame:mode]) {
        // Placeholder frame; used until the constraints are properly applied
        chooserFrame = CGRectMake(0,
                                  0,
                                  [UIApplication sharedApplication].keyWindow.bounds.size.width,
                                  100);
    }
    NSAssert(!CGRectIsNull(chooserFrame), @"Logic error: got a null rect for the chooser view's frame");

    // Instantiate the chooser view
    UIView<HKWChooserViewProtocol> *chooserView = nil;
    if ([(id)self.chooserViewClass respondsToSelector:@selector(chooserViewWithFrame:delegate:)]) {
        chooserView = [self.chooserViewClass chooserViewWithFrame:chooserFrame delegate:self];
    }
    else if ([(id)self.chooserViewClass respondsToSelector:@selector(chooserViewWithFrame:delegate:dataSource:)]) {
        chooserView = [self.chooserViewClass chooserViewWithFrame:chooserFrame
                                                         delegate:self
                                                       dataSource:self];
    }
    else {
        NSAssert(NO, @"Chooser view class must support one or both of the following methods: \
                 chooserViewWithFrame:delegate: or chooserViewWithFrame:delegate:dataSource:");
    }

    if ([chooserView respondsToSelector:@selector(setBorderMode:)]) {
        if ([HKWMentionsCreationStateMachine modeConfiguresArrowPointingUp:mode]) {
            chooserView.borderMode = HKWChooserBorderModeTop;
        }
        else if ([HKWMentionsCreationStateMachine modeConfiguresArrowPointingDown:mode]) {
            chooserView.borderMode = HKWChooserBorderModeBottom;
        }
        else {
            chooserView.borderMode = HKWChooserBorderModeNone;
        }
    }
    return chooserView;
}


#pragma mark - Private (timer related)

/*!
 Configure and activate the cooldown timer. If the cooldown timer was already active, restarts it.
 */
- (void)activateCooldownTimer {
    // Remove any pre-existing timers.
    [self.cooldownTimer invalidate];

    // Advance state
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateQuiescent:
            NSAssert(NO, @"Timer should never be activated when state machine is quiescent.");
            break;
        case HKWMentionsCreationNetworkStateReady:
            self.networkState = HKWMentionsCreationNetworkStateTimerCooldown;
            break;
        case HKWMentionsCreationNetworkStateTimerCooldown:
            NSAssert(NO, @"Timer should never be activated when state machine is waiting for timer cooldown.");
            break;
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            // Valid state transition. This happens if a new request is fired as soon as the timer times out.
            self.networkState = HKWMentionsCreationNetworkStateTimerCooldown;
            break;
    }

    // Add and activate the timer
    NSTimer *timer = [NSTimer timerWithTimeInterval:self.cooldownPeriod
                                             target:self
                                           selector:@selector(cooldownTimerFired:)
                                           userInfo:nil
                                            repeats:NO];
    self.cooldownTimer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

/*!
 Handle actions and state transitions after the cooldown timer fires. If the user has queued up another request, this
 method may fire another typeahead request to the server immediately. Otherwise, the firing of the timer indicates that
 it is acceptable to send another request at any time.
 */
- (void)cooldownTimerFired:(NSTimer *)timer {
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateQuiescent:
            // User not creating a mention right now.
            return;
        case HKWMentionsCreationNetworkStateReady:
            NSAssert(NO, @"Timer should never be active when state machine is in the 'ready' state.");
            return;
        case HKWMentionsCreationNetworkStateTimerCooldown:
            self.networkState = HKWMentionsCreationNetworkStateReady;
            break;
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            // Fire off another request immediately
            self.sequenceNumber += 1;
            NSUInteger sequenceNumber = self.sequenceNumber;
            __weak typeof(self) __self = self;

            [self activateCooldownTimer];
            [self.delegate asyncRetrieveEntitiesForKeyString:[self.stringBuffer copy]
                                                  searchType:self.searchType
                                            controlCharacter:self.explicitSearchControlCharacter
                                                  completion:^(NSArray *results, BOOL dedupe, BOOL isComplete) {
                                                      [__self dataReturnedWithResults:results
                                                                       sequenceNumber:sequenceNumber
                                                                        triggerAction:self.lastTriggerAction
                                                                        dedupeResults:dedupe
                                                                  dataFetchIsComplete:isComplete];
                                                  }];
            break;
    }
}


#pragma mark - Private (data related)

/*!
 Handle updated data received from the data source.
 */
- (void)dataReturnedWithResults:(NSArray *)results
                 sequenceNumber:(NSUInteger)sequence
                  triggerAction:(HKWMentionsCreationAction)action
                  dedupeResults:(BOOL)dedupe
            dataFetchIsComplete:(BOOL)isComplete {
    // Check for error conditions
    if (sequence != self.sequenceNumber) {
        // This is a response to an out-of-date request.
        HKWLOG(@"  DEBUG: out-of-date request (seq: %lu, current: %lu)",
                (unsigned long)sequence, (unsigned long)self.sequenceNumber);
        return;
    }
    if (self.state == HKWMentionsCreationStateQuiescent) {
        NSAssert(self.chooserState == HKWMentionsCreationChooserStateHidden,
                 @"Logic error: entity chooser view is active even though state machine is quiescent.");
        self.entityArray = nil;
        return;
    }

    // At this point, check whether or not we've received at least one set of results for the current query.
    if (self.firstResultReturnedForCurrentQuery) {
        if (self.currentQueryIsComplete) {
            HKWLOG(@"Delegate tried to append data, but the current query is already complete. Ignoring.");
        }
        else {
            // Append additional data and update the state.
            self.currentQueryIsComplete = isComplete;
            [self appendAdditionalResults:results dedupeResults:dedupe previousAction:action];
        }
        return;
    }

    // At this point, we are handling the *first* response for a given query.
    self.firstResultReturnedForCurrentQuery = YES;
    self.currentQueryIsComplete = isComplete || [results count] == 0;
    if ([results count] == 0) {
        // No responses
        self.entityArray = nil;
        [self handleFinalizedQueryWithNoResults:action];
        return;
    }

    // We have at least one response
    self.resultsState = HKWMentionsCreationResultsStateCreatingMentionWithResults;

    NSUInteger numResults = [results count];
    NSMutableArray *validResults = [NSMutableArray arrayWithCapacity:numResults];
    NSMutableSet *uniqueIds = [NSMutableSet setWithCapacity:numResults];
    for (id entity in results) {
#ifdef DEBUG
        // Validate
        NSAssert([entity conformsToProtocol:@protocol(HKWMentionsEntityProtocol)],
                 @"Data results array contained at least one object that didn't conform to the protocol. This is a \
                 serious error. Object: %@",
                 entity);
#endif
        if (dedupe) {
            // This is the first response; protect against duplicates within this response
            NSString *uniqueId = [self uniqueIdForEntity:entity];
            if ([uniqueId length] && ![uniqueIds containsObject:uniqueId]) {
                [validResults addObject:entity];
                [uniqueIds addObject:uniqueId];
            }
        }
        else {
            [validResults addObject:entity];
        }
    }
    self.entityArray = [validResults copy];

    // If mentions creation is still active and we haven't shown the chooser view, show it now.
    if (self.state != HKWMentionsCreationStateQuiescent
        && self.chooserState == HKWMentionsCreationChooserStateHidden) {
        [self showChooserView];
    }
}

- (void)appendAdditionalResults:(NSArray *)results
                  dedupeResults:(BOOL)dedupe
                 previousAction:(HKWMentionsCreationAction)previousAction {

    // Append the additional results to the current list of results
    if ([results count] > 0) {
        // If results should be deduped, create a set containing uniqueIds for all existing entities.
        NSMutableSet *uniqueIds = [NSMutableSet setWithCapacity:[self.entityArray count]];
        if (dedupe) {
            for (id entity in self.entityArray) {
                if ([entity conformsToProtocol:@protocol(HKWMentionsEntityProtocol)]) {
                    NSString *uniqueId = [self uniqueIdForEntity:entity];
                    if ([uniqueId length]) {
                        [uniqueIds addObject:uniqueId];
                    }
                }
            }
        }

        NSMutableArray *resultsBuffer = [NSMutableArray arrayWithArray:self.entityArray ?: @[]];
        for (id result in results) {
            if ([result conformsToProtocol:@protocol(HKWMentionsEntityProtocol)]) {
                // This is a subsequent response; protect against adding duplicates from previous responses
                if (dedupe) {
                    NSString *uniqueId = [self uniqueIdForEntity:result];
                    if ([uniqueId length] && ![uniqueIds containsObject:uniqueId]) {
                        [resultsBuffer addObject:result];
                        // Protect against duplicates within the new data set being appended
                        [uniqueIds addObject:uniqueId];
                    }
                }
                else {
                    [resultsBuffer addObject:result];
                }
            }
        }
        self.entityArray = [resultsBuffer copy];
    }
    else {
        // No results
        [self.entityChooserView reloadData];
        if ([self.entityArray count] == 0 && self.currentQueryIsComplete) {
            // We have absolutely no results, and we've finalized the results for this query.
            [self handleFinalizedQueryWithNoResults:previousAction];
        }
        return;
    }

    // At this point, we have at least one mention
    self.resultsState = HKWMentionsCreationResultsStateCreatingMentionWithResults;

    // Force the chooser view to update state
    if (self.chooserState == HKWMentionsCreationChooserStateHidden) {
        // We hid the chooser view, possibly because we hadn't gotten results previously
        [self showChooserView];
    }
    [self.entityChooserView reloadData];
}

- (NSString *)uniqueIdForEntity:(id<HKWMentionsEntityProtocol>)entity {
    if ([entity respondsToSelector:@selector(uniqueId)]) {
        return [entity uniqueId];
    }
    else {
        // Default to using the entityId when a uniqueId is not provided
        return [entity entityId];
    }
}

/*!
 Perform all necessary state transitions when the results callback block is called, the query results are finalized, and
 there are no results at all. This may either result in terminating mentions creation, or going into a quiescent mode.
 */
- (void)handleFinalizedQueryWithNoResults:(HKWMentionsCreationAction)previousAction {
    // There are no more results, so mentions creation should stall
    self.chooserState = HKWMentionsCreationChooserStateHidden;

    // However, there are two conditions under which mentions creation should actually end completely:
    // 1. The user's initial query turned up no results
    // 2. There are no results because the last character the user typed was a whitespace or newline (whether or not
    //    the previous request resulted in results or not)
    BOOL shouldStop = (self.resultsState == HKWMentionsCreationResultsStateAwaitingFirstResult
                       || previousAction == HKWMentionsCreationActionWhitespaceCharacterInserted);
    if (shouldStop) {
        [self.delegate cancelMentionFromStartingLocation:self.startingLocation];
        self.state = HKWMentionsCreationStateQuiescent;
        return;
    }

    // Advance the results state. The user could have been in one of two states formally: results existed, or there were
    //  no results but the user hadn't typed a whitespace character since results stopped coming back
    NSAssert(self.resultsState == HKWMentionsCreationResultsStateCreatingMentionWithResults
             || self.resultsState == HKWMentionsCreationResultsStateNoResultsWithoutWhitespace,
             @"Logic error in dataReturnedForResults:...; resultsState is inconsistent. Got %@, which is invalid.",
             nameForResultsState(self.resultsState));
    self.resultsState = HKWMentionsCreationResultsStateNoResultsWithoutWhitespace;
}


#pragma mark - Custom chooser view

- (BOOL)shouldDisplayLoadingIndicator {
    return !self.currentQueryIsComplete;
}

- (NSInteger)numberOfModelObjects {
    return [self.entityArray count];
}

- (id)modelObjectForIndex:(NSInteger)index {
    return self.entityArray[index];
}

- (void)modelObjectSelectedAtIndex:(NSInteger)index {
    id<HKWMentionsEntityProtocol> entity = self.entityArray[index];
    HKWMentionsAttribute *mention = [HKWMentionsAttribute mentionWithText:[entity entityName]
                                                               identifier:[entity entityId]];
    mention.metadata = [entity entityMetadata];
    self.state = HKWMentionsCreationStateQuiescent;
    [self.delegate createMention:mention startingLocation:self.startingLocation];
}


#pragma mark - Table view
// Note: the table view data source and delegate here service the table view embedded within the state machine's
//  entity chooser view.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0 || indexPath.section == 1,
             @"Entity chooser table view can only have up to 2 sections. Method was called for section %ld.",
             (long)indexPath.section);
    if (indexPath.section == 1) {
        // Loading cell
        NSAssert(self.delegate.loadingCellSupported,
                 @"Table view has 2 sections but the delegate doesn't support a loading cell. This is an error.");
        UITableViewCell *cell = [self.delegate loadingCellForTableView:tableView];
        cell.userInteractionEnabled = NO;
        return cell;
    }
    NSAssert(indexPath.row >= 0 && indexPath.row < [self.entityArray count],
             @"Entity chooser table view requested a cell with an out-of-bounds index path row.");
    id<HKWMentionsEntityProtocol> entity = self.entityArray[indexPath.row];
    return [self.delegate cellForMentionsEntity:entity withMatchString:[self.stringBuffer copy] tableView:tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.delegate.loadingCellSupported && !self.currentQueryIsComplete) ? 2 : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(section == 0 || section == 1,
             @"Entity chooser table view can only have up to 2 sections.");
    if (section == 1) {
        // Loading cell
        return 1;
    }
    return [self.entityArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0 || indexPath.section == 1,
             @"Entity chooser table view can only have up to 2 sections.");
    if (indexPath.section == 1) {
        // Loading cell
        return [self.delegate heightForLoadingCellInTableView:tableView];
    }
    NSAssert(indexPath.row >= 0 && indexPath.row < [self.entityArray count],
             @"Entity chooser table view requested a cell with an out-of-bounds index path row.");
    id<HKWMentionsEntityProtocol> entity = self.entityArray[indexPath.row];
    return [self.delegate heightForCellForMentionsEntity:entity tableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        return;
    }
    // Create the mention
    id<HKWMentionsEntityProtocol> entity = self.entityArray[indexPath.row];
    HKWMentionsAttribute *mention = [HKWMentionsAttribute mentionWithText:[entity entityName]
                                                                 identifier:[entity entityId]];
    mention.metadata = [entity entityMetadata];
    self.state = HKWMentionsCreationStateQuiescent;
    [self.delegate createMention:mention startingLocation:self.startingLocation];
}


#pragma mark - Properties

- (UIColor *)chooserViewBackgroundColor {
    if (!_chooserViewBackgroundColor) {
        _chooserViewBackgroundColor = [UIColor whiteColor];
    }
    return _chooserViewBackgroundColor;
}

- (void)setChooserViewBackgroundColor:(UIColor *)chooserViewBackgroundColor {
    _chooserViewBackgroundColor = chooserViewBackgroundColor;
    if (_entityChooserView && [_entityChooserView respondsToSelector:@selector(setChooserBackgroundColor:)]) {
        [_entityChooserView setChooserBackgroundColor:chooserViewBackgroundColor];
    }
}

- (void)setChooserViewEdgeInsets:(UIEdgeInsets)chooserViewEdgeInsets {
    HKWMentionsChooserPositionMode mode = [self.delegate chooserPositionMode];
    if (mode != HKWMentionsChooserPositionModeEnclosedTop
        && mode != HKWMentionsChooserPositionModeEnclosedBottom) {
        // The edge insets are only valid for the modes where the chooser view is automatically positioned inside the
        //  text view. Otherwise, the user can just define the custom frame however they wish.
        return;
    }
    UIEdgeInsets oldInsets = _chooserViewEdgeInsets;
    UIEdgeInsets newInsets = chooserViewEdgeInsets;
    _chooserViewEdgeInsets = chooserViewEdgeInsets;
    if (_entityChooserView) {
        // Adjust the frame of the chooser view to match the new insets
        CGFloat widthDelta = (oldInsets.left + oldInsets.right) - (newInsets.left + newInsets.right);
        CGFloat heightDelta = (oldInsets.top + oldInsets.bottom) - (newInsets.top + newInsets.bottom);
        CGFloat xDelta = newInsets.left - oldInsets.left;
        CGFloat yDelta = newInsets.top - oldInsets.top;
        CGRect f = self.entityChooserView.frame;
        f.origin.x += xDelta;
        f.origin.y += yDelta;
        f.size.width += widthDelta;
        f.size.height += heightDelta;
        self.entityChooserView.frame = f;
    }
}

- (void)setSequenceNumber:(NSUInteger)sequenceNumber {
    self.currentQueryIsComplete = NO;
    self.firstResultReturnedForCurrentQuery = NO;
    _sequenceNumber = sequenceNumber;
}

- (void)setState:(HKWMentionsCreationState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    if (state == HKWMentionsCreationStateQuiescent) {
        // Reset the buffer
        self.stringBuffer = [NSMutableString string];
        // Hide the chooser view
        self.chooserState = HKWMentionsCreationChooserStateHidden;
        // Reset the sub-FSM states
        self.networkState = HKWMentionsCreationNetworkStateQuiescent;
        self.resultsState = HKWMentionsCreationResultsStateQuiescent;
    }
}

- (void)setNetworkState:(HKWMentionsCreationNetworkState)networkState {
    if (_networkState == networkState) {
        return;
    }
    HKW_STATE_LOG(@"  Creation SM Network State Transition: %@ --> %@",
                   nameForNetworkState(_networkState), nameForNetworkState(networkState));
    _networkState = networkState;
    if (_networkState == HKWMentionsCreationNetworkStateQuiescent) {
        // Reset the cooldown timer
        [self.cooldownTimer invalidate];
    }
}

- (void)setResultsState:(HKWMentionsCreationResultsState)resultsState {
    if (_resultsState == resultsState) {
        return;
    }
    HKW_STATE_LOG(@"  Creation SM Results State Transition: %@ --> %@",
                   nameForResultsState(_resultsState), nameForResultsState(resultsState));
    _resultsState = resultsState;
}

- (void)setChooserState:(HKWMentionsCreationChooserState)chooserState {
    if (_chooserState == chooserState) {
        return;
    }
    _chooserState = chooserState;
    if (chooserState == HKWMentionsCreationChooserStateHidden) {
        [self hideChooserView];
    }
}

- (void)setEntityArray:(NSArray *)entityArray {
    if (!_entityArray && !entityArray) {
        return;
    }
    _entityArray = entityArray;
    // Force the entity chooser's table view to update
    [self.entityChooserView reloadData];
}

- (UIView<HKWChooserViewProtocol> *)entityChooserView {
    if (!_entityChooserView) {
        _entityChooserView = [self createNewChooserView];
        if ([_entityChooserView respondsToSelector:@selector(setChooserBackgroundColor:)]) {
            [_entityChooserView setChooserBackgroundColor:self.chooserViewBackgroundColor];
        }
    }
    return _entityChooserView;
}

- (NSMutableString *)stringBuffer {
    if (!_stringBuffer) {
        _stringBuffer = [NSMutableString string];
    }
    return _stringBuffer;
}

- (NSTimeInterval)cooldownPeriod {
    return 0.1;
}

- (BOOL)chooserViewInsideTextView {
    HKWMentionsChooserPositionMode mode = [self.delegate chooserPositionMode];
    return mode == HKWMentionsChooserPositionModeEnclosedBottom || mode == HKWMentionsChooserPositionModeEnclosedTop;
}

- (void)setChooserViewClass:(Class)chooserViewClass {
    if (!chooserViewClass
        || ![chooserViewClass conformsToProtocol:@protocol(HKWChooserViewProtocol)]
        || ![chooserViewClass isSubclassOfClass:[UIView class]]) {
        return;
    }
    _chooserViewClass = chooserViewClass;
}


#pragma mark - Development

NSString *nameForMentionsCreationState(HKWMentionsCreationState s) {
    switch (s) {
        case HKWMentionsCreationStateQuiescent:
            return @"Quiescent";
        case HKWMentionsCreationStateCreatingMention:
            return @"CreatingMention";
    }
}

NSString *nameForResultsState(HKWMentionsCreationResultsState s) {
    switch (s) {
        case HKWMentionsCreationResultsStateQuiescent:
            return @"Quiescent";
        case HKWMentionsCreationResultsStateAwaitingFirstResult:
            return @"AwaitingFirstResult";
        case HKWMentionsCreationResultsStateCreatingMentionWithResults:
            return @"CreatingMentionWithResults";
        case HKWMentionsCreationResultsStateNoResultsWithoutWhitespace:
            return @"NoResultsWithoutWhitespace";
    }
}

NSString *nameForNetworkState(HKWMentionsCreationNetworkState s) {
    switch (s) {
        case HKWMentionsCreationNetworkStateQuiescent:
            return @"Quiescent";
        case HKWMentionsCreationNetworkStateReady:
            return @"Ready";
        case HKWMentionsCreationNetworkStateTimerCooldown:
            return @"TimerCooldown";
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            return @"PendingRequestAfterCooldown";
    }
}

@end
