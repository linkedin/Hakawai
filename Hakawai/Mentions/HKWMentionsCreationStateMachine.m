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
#import "HKWMentionDataProvider.h"

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

@interface HKWMentionsCreationStateMachine ()

@property (nonatomic, weak) id<HKWMentionsCreationStateMachineDelegate> delegate;

@property (nonatomic, nullable) HKWMentionDataProvider *dataProvider;
@property (nonatomic) HKWMentionsCreationState state;
@property (nonatomic) HKWMentionsCreationResultsState resultsState;
@property (nonatomic) HKWMentionsCreationChooserState chooserState;

@property (nonatomic, strong) UIView<HKWChooserViewProtocol> *entityChooserView;
// TODO: Update to cursorLocation with ramp of plugin v2
// JIRA: POST-14031
@property (nonatomic) NSUInteger startingLocation;
/// What the last relevant action the user took within the text view was.
@property (nonatomic) HKWMentionsCreationAction lastTriggerAction;

@property (nonatomic) HKWMentionsSearchType searchType;

/*!
 A buffer containing the text typed by the user since mentions creation began, used to query the data source for
 potential matches.
 */
@property (nonatomic, strong) NSMutableString *stringBuffer;

@property (nonatomic, readonly) BOOL chooserViewInsideTextView;

@property (nonatomic, readwrite) BOOL chooserViewDidSetup;

@end

@implementation HKWMentionsCreationStateMachine

// NOTE: Do not remove these
@synthesize chooserViewBackgroundColor = _chooserViewBackgroundColor;
@synthesize chooserViewClass = _chooserViewClass;
@synthesize chooserViewEdgeInsets = _chooserViewEdgeInsets;
@synthesize explicitSearchControlCharacter = _explicitSearchControlCharacter;

#pragma mark - API

+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsCreationStateMachineDelegate>)delegate isUsingCustomChooserView:(BOOL)isUsingCustomChooserView {
    NSAssert(delegate != nil, @"Cannot create state machine with nil delegate.");
    HKWMentionsCreationStateMachine *sm = [[self class] new];
    sm.chooserViewClass = [HKWDefaultChooserView class];
    sm.delegate = delegate;
    sm.state = HKWMentionsCreationStateQuiescent;
    sm.chooserViewEdgeInsets = UIEdgeInsetsZero;
    // We only need a data provider if we are not using a custom chooser view
    if (!isUsingCustomChooserView) {
        sm.dataProvider = [[HKWMentionDataProvider alloc] initWithStateMachine:sm delegate:delegate];
    }
    return sm;
}

- (void)characterTyped:(unichar)c {
    BOOL isNewline = [[NSCharacterSet newlineCharacterSet] characterIsMember:c];
    BOOL isWhitespace = [[NSCharacterSet whitespaceCharacterSet] characterIsMember:c];
    __strong __auto_type delegate = self.delegate;

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
                [delegate cancelMentionFromStartingLocation:self.startingLocation];
                return;
            }
    }
    if ([self.stringBuffer length] == 0 && isWhitespace) {
        self.state = HKWMentionsCreationStateQuiescent;
        [delegate cancelMentionFromStartingLocation:self.startingLocation];
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
    __strong __auto_type delegate = self.delegate;

    // State transition
    switch (self.state) {
        case HKWMentionsCreationStateQuiescent:
            // User not creating a mention right now.
            return;
        case HKWMentionsCreationStateCreatingMention: {
            // User is creating a mention, and can fire off a network request immediately if necessary.
            if (isNewline) {
                // User ended mention creation by typing a newline
                self.state = HKWMentionsCreationStateQuiescent;
                [delegate cancelMentionFromStartingLocation:self.startingLocation];
            } else {
                self.lastTriggerAction = (isWhitespace
                                          ? HKWMentionsCreationActionWhitespaceCharacterInserted
                                          : HKWMentionsCreationActionNormalCharacterInserted);
                [self.stringBuffer appendString:string];
                if (self.dataProvider) {
                    // Fire off the request and start the timer
                    [self.dataProvider queryUpdatedWithKeyString:[self.stringBuffer copy]
                                                      searchType:self.searchType
                                                    isWhitespace:isWhitespace
                                                controlCharacter:self.explicitSearchControlCharacter];
                } else {
                    // If we do not have a data provider, just pass the updated query directly to the mention plugin
                    [delegate didUpdateKeyString:[self.stringBuffer copy]
                                controlCharacter:self.explicitSearchControlCharacter];
                }
            }
            break;
        }
    }
}

- (void)stringDeleted:(NSString *)deleteString {
    // State transition
    NSAssert([deleteString length] > 0, @"Logic error: string to be deleted must not be empty.");

    // Whether or not the buffer is empty (no characters to search upon).
    // Note that, if the mention is an explicit mention (use control character), user can back out to beginning. But if
    // the mention is implicit, backing out to the beginning will cancel mentions creation.
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

    __strong __auto_type delegate = self.delegate;

    /**
     When mentions was originally triggered because the whitespace between a control character and a word was deleted,
     the cursor is next to the control character (like "@|John", where '|' represents the cursor-state). If the user then deletes the control character,
     the string buffer will not be empty (it will have "John" in it), but mentions has to stop, because control character is deleted.
     We use the isControlCharacterDeleted flag to decide what to do in this case of control character deletion.
     */
    BOOL isControlCharacterDeleted = NO;
    if (deleteString.length == 1
        && [deleteString containsString:[NSString stringWithFormat:@"%C", self.explicitSearchControlCharacter]]
        && self.stringBuffer.length > 0
        && [self.stringBuffer characterAtIndex:self.stringBuffer.length - 1] != self.explicitSearchControlCharacter) {
        isControlCharacterDeleted = YES;
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

    // Switch on the overall state
    switch (self.state) {
        case HKWMentionsCreationStateQuiescent:
            // User not creating a mention right now
            return;
        case HKWMentionsCreationStateCreatingMention:
            if (isControlCharacterDeleted) {
                // When user deletes control character during mention creation state, then end mention creation.
                self.state = HKWMentionsCreationStateQuiescent;
                [delegate cancelMentionFromStartingLocation:self.startingLocation];
                return;
            }

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
                [delegate cancelMentionFromStartingLocation:self.startingLocation];
                return;
            }
            self.lastTriggerAction = HKWMentionsCreationActionCharacterDeleted;
            // The user hasn't completely backed out of mentions creation, so we can continue firing requests.
            // Remove a character from the buffer and immediately fire a request
            [self.stringBuffer deleteCharactersInRange:toDeleteRange];
            if (self.dataProvider) {
                // Fire off the request and start the timer
                [self.dataProvider queryUpdatedWithKeyString:[self.stringBuffer copy]
                                                  searchType:self.searchType
                                                isWhitespace:NO
                                            controlCharacter:self.explicitSearchControlCharacter];
            } else {
                // If we do not have a data provider, just pass the updated query directly to the mention plugin
                [delegate didUpdateKeyString:[self.stringBuffer copy]
                            controlCharacter:self.explicitSearchControlCharacter];
            }
            break;
    }

    // Switch on the network state
    NSAssert(!deleteStringIsTransient && !bufferAlreadyEmpty,
             @"At this point, we must be in a state where we can create a smaller buffer and search on that");
}

- (void)cursorMoved {
    // State transition
    switch (self.state) {
        case HKWMentionsCreationStateQuiescent:
            // User not creating a mention right now.
            return;
        case HKWMentionsCreationStateCreatingMention:
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
    if (!HKWTextView.enableMentionsPluginV2 && self.state != HKWMentionsCreationStateQuiescent) {
        return;
    }
    self.state = HKWMentionsCreationStateCreatingMention;
    self.searchType = usingControlCharacter ? HKWMentionsSearchTypeExplicit : HKWMentionsSearchTypeImplicit;
    self.explicitSearchControlCharacter = usingControlCharacter ? character : 0;

    self.stringBuffer = [prefix mutableCopy];
    NSAssert(location != NSNotFound, @"Cannot start mentions creation with NSNotFound as starting location.");
    self.startingLocation = location;

    // Prepare state
    self.resultsState = HKWMentionsCreationResultsStateAwaitingFirstResult;

    if (self.dataProvider) {
        // Start the timer and fire off a request
        [self.dataProvider queryUpdatedWithKeyString:prefix
                                          searchType:self.searchType
                                        isWhitespace:NO
                                    controlCharacter:self.explicitSearchControlCharacter];
    } else {
        // If we do not have a data provider, just pass the updated query directly to the mention plugin
        [self.delegate didUpdateKeyString:prefix
                         controlCharacter:self.explicitSearchControlCharacter];
    }
}

- (void)cancelMentionCreation {
    if (self.state == HKWMentionsCreationStateQuiescent) {
        return;
    }
    self.state = HKWMentionsCreationStateQuiescent;
    [self.delegate cancelMentionFromStartingLocation:0];
}

- (void)resetChooserView {
    self.state = HKWMentionsCreationStateQuiescent;
    self.entityChooserView = nil;
    self.dataProvider = nil;
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

- (void)fetchInitialMentions {
    self.searchType = HKWMentionsSearchTypeInitial;
    if (self.dataProvider) {
        [self.dataProvider queryUpdatedWithKeyString:@""
                                          searchType:self.searchType
                                        isWhitespace:NO
                                    controlCharacter:self.explicitSearchControlCharacter];
    } else {
        // If we do not have a data provider, just pass the updated query directly to the mention plugin
        [self.delegate didUpdateKeyString:@""
                         controlCharacter:self.explicitSearchControlCharacter];
    }
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
    __strong __auto_type delegate = self.delegate;
    CGRect chooserFrame = [delegate boundsForParentEditorView];
    CGFloat viewportHeight = [delegate heightForSingleLineViewport];

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

- (void)setupChooserViewIfNeeded {
    if (self.chooserViewDidSetup) {
        return;
    }
    HKWAccessoryViewMode mode = (self.chooserViewInsideTextView
                                 ? HKWAccessoryViewModeSibling
                                 : HKWAccessoryViewModeFreeFloating);
    [self.delegate attachViewToParentEditor:self.entityChooserView
                                     origin:self.entityChooserView.frame.origin
                                       mode:mode];
    // hide chooser view initially
    self.entityChooserView.hidden = YES;
    self.chooserViewDidSetup = YES;
}

- (void)showChooserView {
    __strong __auto_type delegate = self.delegate;
    [delegate accessoryViewStateWillChange:YES];

    self.chooserState = HKWMentionsCreationChooserStateVisible;
    [self.entityChooserView becomeVisible];
    if ([self.entityChooserView respondsToSelector:@selector(setInsertionPointMarkerEnabled:)]) {
        self.entityChooserView.insertionPointMarkerEnabled = YES;
    }
    [delegate accessoryViewActivated:YES];
    // Force entityChooserView to be laid out before calculating the right cursor position.
    [self.entityChooserView layoutIfNeeded];

    // Move the chooser cursor to the right position
    CGFloat newPosition = [delegate positionForChooserCursorRelativeToView:self.entityChooserView
                                                                atLocation:self.startingLocation];
    if ([self.entityChooserView respondsToSelector:@selector(moveInsertionPointMarkerToXPosition:)]) {
        [self.entityChooserView moveInsertionPointMarkerToXPosition:newPosition];
    }
}

- (void)reloadChooserView {
    [self.entityChooserView reloadData];
}

- (void)hideChooserView {
    __strong __auto_type delegate = self.delegate;
    [delegate accessoryViewStateWillChange:NO];
    [self.entityChooserView resetScrollPositionAndHide];
    [delegate accessoryViewActivated:NO];
}

- (UIView<HKWChooserViewProtocol> *)createNewChooserView {
    HKWMentionsChooserPositionMode mode = [self.delegate chooserPositionMode];
    CGRect chooserFrame = [self frameForMode:mode];
    // Handle the case where the chooser frame is completely custom
    if ([HKWMentionsCreationStateMachine modeRequiresCustomFrame:mode]) {
        // Placeholder frame; used until the constraints are properly applied
        chooserFrame = CGRectZero;
    }
    NSAssert(!CGRectIsNull(chooserFrame), @"Logic error: got a null rect for the chooser view's frame");

    // Instantiate the chooser view
    UIView<HKWChooserViewProtocol> *chooserView = nil;
    if (self.dataProvider) {
        if ([(id)self.chooserViewClass respondsToSelector:@selector(chooserViewWithFrame:delegate:)]) {
            chooserView = [self.chooserViewClass chooserViewWithFrame:chooserFrame
                                                             delegate:self.dataProvider];
        }
        else if ([(id)self.chooserViewClass respondsToSelector:@selector(chooserViewWithFrame:delegate:dataSource:)]) {
            chooserView = [self.chooserViewClass chooserViewWithFrame:chooserFrame
                                                             delegate:self.dataProvider
                                                           dataSource:self.dataProvider];
        }
        else {
            NSAssert(NO, @"If there is a dataprovider, chooser view class must support one or both of the following methods: \
                     chooserViewWithFrame:delegate: or chooserViewWithFrame:delegate:dataSource:");
        }
    } else {
        // If we are not using a data provider, just create the chooser view without one
        if ([(id)self.chooserViewClass respondsToSelector:@selector(chooserViewWithFrame:)]) {
            chooserView = [self.chooserViewClass chooserViewWithFrame:chooserFrame];
        }
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

#pragma mark - Private (data related)

/*!
 Handle updated data received from the data source.
 */
- (void)dataReturnedWithEmptyResults:(BOOL)isEmptyResults
         keystringEndsWithWhiteSpace:(BOOL)keystringEndsWithWhiteSpace {
    if (self.state == HKWMentionsCreationStateQuiescent && self.searchType != HKWMentionsSearchTypeInitial) {
        NSAssert(self.chooserState == HKWMentionsCreationChooserStateHidden,
                 @"Logic error: entity chooser view is active even though state machine is quiescent.");
        return;
    }
    if (isEmptyResults) {
        // No responses
        [self handleFinalizedQueryWithNoResultsWithWhiteSpace:keystringEndsWithWhiteSpace];
        return;
    }
    // We have at least one response
    self.resultsState = HKWMentionsCreationResultsStateCreatingMentionWithResults;
    // If mentions creation is still active or if its for initial search, and we haven't shown the chooser view, show it now.
    if ((self.state != HKWMentionsCreationStateQuiescent || self.searchType == HKWMentionsSearchTypeInitial)
        && self.chooserState == HKWMentionsCreationChooserStateHidden) {
        [self showChooserView];
    }
}

/*!
 Perform all necessary state transitions when the results callback block is called, the query results are finalized, and
 there are no results at all. This may either result in terminating mentions creation, or going into a quiescent mode.
 */
- (void)handleFinalizedQueryWithNoResultsWithWhiteSpace:(BOOL)endsWithWhiteSpace {
    // There are no more results, so mentions creation should stall
    self.chooserState = HKWMentionsCreationChooserStateHidden;

    // However, there are two conditions under which mentions creation should actually end completely:
    // 1. The user's initial query turned up no results and we should not continue searching after empty results
    // 2. There are no results because the last character the user typed was a whitespace or newline (whether or not
    //    the previous request resulted ifn results or not)
    __strong __auto_type delegate = self.delegate;
    BOOL noResultsAndShouldStop = (!delegate.shouldContinueSearchingAfterEmptyResults
                                   && self.resultsState == HKWMentionsCreationResultsStateAwaitingFirstResult);
    BOOL shouldStop = (noResultsAndShouldStop || endsWithWhiteSpace);
    if (shouldStop) {
        [delegate cancelMentionFromStartingLocation:self.startingLocation];
        self.state = HKWMentionsCreationStateQuiescent;
        return;
    }

    // Advance the results state. The user could have been in one of two states formally: results existed, or there were
    //  no results but the user hadn't typed a whitespace character since results stopped coming back, or if the search results are for initial state
    NSAssert((delegate.shouldContinueSearchingAfterEmptyResults && self.resultsState == HKWMentionsCreationResultsStateAwaitingFirstResult)
             || self.resultsState == HKWMentionsCreationResultsStateCreatingMentionWithResults
             || self.resultsState == HKWMentionsCreationResultsStateNoResultsWithoutWhitespace
             || self.searchType == HKWMentionsSearchTypeInitial,
             @"Logic error in dataReturnedForResults:...; resultsState is inconsistent. Got %@, which is invalid.",
             nameForResultsState(self.resultsState));
    self.resultsState = HKWMentionsCreationResultsStateNoResultsWithoutWhitespace;
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
        self.resultsState = HKWMentionsCreationResultsStateQuiescent;
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

// TODO: remove indexPath as it's no longer needed for tracking POST-12576
- (void)handleSelectionForEntity:(id<HKWMentionsEntityProtocol>)entity indexPath:(NSIndexPath *)indexPath {
    HKWMentionsAttribute *mention = [HKWMentionsAttribute mentionWithText:[entity entityName]
                                                               identifier:[entity entityId]];
    mention.metadata = [entity entityMetadata];
    self.state = HKWMentionsCreationStateQuiescent;
    __strong __auto_type delegate = self.delegate;

    [delegate createMention:mention cursorLocation:self.startingLocation];
    [delegate selected:entity atIndexPath:indexPath];
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

@end
