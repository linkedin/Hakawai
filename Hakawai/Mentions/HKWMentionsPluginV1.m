//
//  HKWMentionsPluginV1.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWMentionsPluginV1.h"

#import "HKWCustomAttributes.h"
#import "HKWRoundedRectBackgroundAttributeValue.h"

#import "HKWTextView.h"
#import "HKWTextView+TextTransformation.h"
#import "HKWTextView+Extras.h"
#import "HKWTextView+Plugins.h"

#import "HKWMentionsAttribute.h"

#import "_HKWMentionsStartDetectionStateMachine.h"
#import "_HKWMentionsCreationStateMachine.h"
#import "_HKWMentionsCreationStateMachine.h"

#import "_HKWMentionsPrivateConstants.h"

@interface HKWMentionsPluginV1 () <HKWMentionsStartDetectionStateMachineProtocol, HKWMentionsCreationStateMachineDelegate>

// State properties
@property (nonatomic) HKWMentionsState state;

/// Whether or not initial setup has been performed. If the text view is the first responder already when the plug-in is
/// set, initial setup should be performed immediately. However, if it's not, setup should be deferred until editing is
/// going to begin, so that the text view doesn't snatch first-responder status from a different control.
@property (nonatomic) BOOL initialSetupPerformed;

/*!
 Indicates that all calls to \c textViewDidChangeSelection: should be ignored. This is used when custom transformations
 on the text view's text are desired, which would result in the text view's selection range temporarily changing, but
 should not actually indicate the cursor being manually moved or text being selected.
 */
@property (nonatomic) BOOL suppressSelectionChangeNotifications;

/*!
 Indicates that the next call to \c textViewDidChangeSelection: should be ignored. This property is a fix for an issue
 where the delegate method is called twice whenever a single character is deleted, each time with a different range,
 screwing up the state machine.

 \warning Do not use this to suppress notifications unless absolutely necessary. Instead, in many cases where text is
 programmatically replaced, it is more correct to update the \c previousSelectionRange and \c previousTextLength
 properties, preventing the spurious selection change detection machinery from getting into a bad state.
 */
@property (nonatomic) BOOL nextSelectionChangeShouldBeIgnored;

/*!
 Indicates that the next call to \c textView:shouldChangeTextInRange:replacementText: should be ignored. This property
 is a fix for an issue where, when a suggestion-based keyboard suggestion is deleted (e.g. for the Chinese keyboard),
 the delegate method is fired requesting the suggestion be deleted, and then immediately again with a spurious
 insertion.
 */
@property (nonatomic) BOOL nextInsertionShouldBeIgnored;

@property (nonatomic, strong) HKWMentionsStartDetectionStateMachine *startDetectionStateMachine;
@property (nonatomic, strong) HKWMentionsCreationStateMachine *creationStateMachine;

/*!
 The point at which the last character typed was inserted.
 */
@property (nonatomic) NSUInteger previousInsertionLocation;

/*!
 The previous distinct value of the parent text view's \c selectedRange value for which the text view was in insertion
 mode.
 */
@property (nonatomic) NSRange previousSelectionRange;
@property (nonatomic) NSUInteger previousTextLength;

/*!
 The mention currently highlighted as the 'selected' mention (due to the cursor being in the right place), or the
 mention which may be selected if the state machine is in the 'about to select mention' state.
 */
@property (nonatomic, strong) HKWMentionsAttribute *currentlySelectedMention;

/*!
 The range of the mention attribute whose value is stored in the \c currentlySelectedMention property. This value is not
 automatically updated; it must be kept in sync by the plug-in if the text is modified.
 */
@property (nonatomic) NSRange currentlySelectedMentionRange;

@property (nonatomic, strong) NSDictionary *mentionSelectedAttributes;
@property (nonatomic, strong) NSDictionary *mentionUnselectedAttributes;

@property (nonatomic, readwrite) HKWMentionsChooserPositionMode chooserPositionMode;

@property (nonatomic, readonly) BOOL viewportLocksToTopUponMentionCreation;
@property (nonatomic, readonly) BOOL viewportLocksToBottomUponMentionCreation;
@property (nonatomic, readonly) BOOL viewportLocksUponMentionCreation;

/*!
 If the state machine is currently executing the \c advanceStateForCharacterInsertion method, this property contains the
 character being inserted. Otherwise, it contains the NULL character, 0.

 This property is intended to allow the data-retrieved callback code to determine whether the callback was called
 synchronously or asynchronously, and therefore determine which character to use to determine whether mentions creation,
 if cancelled, should be allowed to immediately restart.

 (If the callback was made asynchronously, then the text in the text view should be used to determine the last character
 typed. If the callback was made synchronously, then the character in this property should be used to determine whether
 or not to allow immediate restart. However, sometimes the callback will be deferred until the next runloop anyways, so
 this should not be used to determine whether or not the callback is synchronous.)
 */
@property (nonatomic) unichar characterForAdvanceStateForCharacterInsertion;

// Properties for resuming mentions creation
@property (nonatomic) BOOL shouldResumeMentionsCreation;
@property (nonatomic) unichar resumeMentionsControlCharacter;   // 0 if implicit mention
@property (nonatomic) NSUInteger resumeMentionsPriorTextLength;
@property (nonatomic) NSUInteger resumeMentionsPriorPosition;
@property (nonatomic) NSString *resumeMentionsPriorString;

@property (nonatomic, copy) void(^customModeAttachmentBlock)(UIView *);

@end

@implementation HKWMentionsPluginV1

@synthesize parentTextView = _parentTextView;

@synthesize dictationString;

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode {
    static const NSInteger defaultSearchLength = 3;
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:nil
                                  searchLength:defaultSearchLength];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength {
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:controlCharacterSet
                                  searchLength:searchLength
                               unselectedColor:[UIColor blueColor]
                                 selectedColor:[UIColor whiteColor]
                       selectedBackgroundColor:[UIColor blackColor]];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                              unselectedColor:(UIColor *)unselectedColor
                                selectedColor:(UIColor *)selectedColor
                      selectedBackgroundColor:(UIColor *)selectedBackgroundColor {
    NSDictionary *unselectedAttributes = @{NSForegroundColorAttributeName: unselectedColor ?: [UIColor blueColor]};
    NSDictionary *selectedAttributes = @{NSForegroundColorAttributeName: selectedColor ?: [UIColor whiteColor],
                                         HKWRoundedRectBackgroundAttributeName: [HKWRoundedRectBackgroundAttributeValue valueWithBackgroundColor:selectedBackgroundColor ?: [UIColor blueColor]]};
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:controlCharacterSet
                                  searchLength:searchLength
                   unselectedMentionAttributes:unselectedAttributes
                     selectedMentionAttributes:selectedAttributes];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                  unselectedMentionAttributes:(NSDictionary *)unselectedAttributes
                    selectedMentionAttributes:(NSDictionary *)selectedAttributes {
    // Make sure iOS version is 7.1 or greater
    if (!HKW_systemVersionIsAtLeast(@"7.1")) {
        NSAssert(NO, @"Mentions plug-in is only supported for iOS 7.1 or later.");
    }

    HKWMentionsPluginV1 *plugin = [[[self class] alloc] init];
    plugin.chooserPositionMode = mode;
    plugin.controlCharacterSet = controlCharacterSet;
    plugin.implicitSearchLength = searchLength;


    // Validate attribute dictionaries
    // (unselected mention attributes)
    NSMutableSet *badAttributes = [NSMutableSet set];
    for (id attribute in unselectedAttributes) {
        if (![attribute isKindOfClass:[NSString class]]
            || [attribute isEqualToString:HKWMentionAttributeName]) {
            [badAttributes addObject:attribute];
        }
    }
    NSMutableDictionary *buffer = [unselectedAttributes copy] ?: [NSMutableDictionary dictionary];
    for (id badAttribute in badAttributes) {
        [buffer removeObjectForKey:badAttribute];
    }
    plugin.mentionUnselectedAttributes = [buffer copy];

    // (selected mention attributes)
    [badAttributes removeAllObjects];
    for (id attribute in selectedAttributes) {
        if (![attribute isKindOfClass:[NSString class]]
            || [attribute isEqualToString:HKWMentionAttributeName]) {
            [badAttributes addObject:attribute];
        }
    }
    buffer = [selectedAttributes copy] ?: [NSMutableDictionary dictionary];
    for (id badAttribute in badAttributes) {
        [buffer removeObjectForKey:badAttribute];
    }
    plugin.mentionSelectedAttributes = [buffer copy];

    return plugin;
}

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    self.state = HKWMentionsStateQuiescent;
    self.initialSetupPerformed = NO;
    self.previousSelectionRange = NSMakeRange(NSNotFound, 0);
    self.previousTextLength = 0;
    self.characterForAdvanceStateForCharacterInsertion = (unichar)0;

    self.shouldResumeMentionsCreation = NO;
    self.notifyTextViewDelegateOnMentionCreation = NO;
    self.notifyTextViewDelegateOnMentionTrim = NO;
    self.notifyTextViewDelegateOnMentionDeletion = NO;

    return self;
}

// Return an array of mentions objects corresponding to the mentions currently in the text view.
- (NSArray *)mentions {
    NSMutableArray *buffer = [NSMutableArray array];
    __block HKWMentionsAttribute *previousMention;

    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView.attributedText enumerateAttributesInRange:HKW_FULL_RANGE(parentTextView.attributedText)
                                                      options:0 usingBlock:^(NSDictionary *attrs, NSRange range, __unused BOOL *stop) {
                                                          id mentionObject = attrs[HKWMentionAttributeName];
                                                          if (![mentionObject isKindOfClass:[HKWMentionsAttribute class]]) {
                                                              return;
                                                          }

                                                          HKWMentionsAttribute *attr = [mentionObject copy];
                                                          // If two attribute dicts have same mention object and the ranges are touching
                                                          // they are the same mention and should be combined
                                                          BOOL isGap = ((previousMention.range.location + previousMention.range.length) < range.location);
                                                          if ([previousMention isEqual:attr] && !isGap) {
                                                              previousMention.range = NSMakeRange(previousMention.range.location, previousMention.range.length + range.length);
                                                          } else {
                                                              attr.range = range;
                                                              [buffer addObject:attr];
                                                              previousMention = attr;
                                                          }
                                                      }];

    return [buffer copy];
}

// Programmatically add a mention to the text view's text.
- (void)addMention:(HKWMentionsAttribute *)mention {
    __strong __auto_type parentTextView = self.parentTextView;
    if (!mention
        || ![mention isKindOfClass:[HKWMentionsAttribute class]]
        || mention.range.location == NSNotFound
        || mention.range.location > [parentTextView.attributedText length]
        || mention.range.length == 0) {
        // Mention range is invalid
        return;
    }
    // Setup
    switch (self.state) {
        case HKWMentionsStateQuiescent:
            break;
        case HKWMentionsStartDetectionStateCreatingMention:
            // If creating a mention, gracefully terminate mentions creation so we're in a known state
            [self.creationStateMachine cancelMentionCreation];
            NSAssert(self.state == HKWMentionsStateQuiescent,
                     @"Logic error: cancelMentionCreation must always set the state back to quiescent.");
            break;
        case HKWMentionsStateAboutToSelectMention:
        case HKWMentionsStateSelectedMention:
            break;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: addMention cannot possibly be invoked while the state is LosingFocus.");
            return;
    }

    NSUInteger location = parentTextView.selectedRange.location;
    NSRange originalRange = NSMakeRange(location, 0);
    NSDictionary *mentionAttributes = self.mentionUnselectedAttributes;
    // Mentions cannot overlap. In order to avoid inconsistency, destroy any existing mentions that intrude within the
    //  new mention's range.
    [self bleachMentionsWithinRange:mention.range];
    [parentTextView transformTextAtRange:mention.range withTransformer:^NSAttributedString *(NSAttributedString *input) {
        if (![mention.mentionText isEqualToString:input.string]) {
            // In order to perform the transformation, the plaintext must be the same as the mention text
            return input;
        }
        NSMutableAttributedString *buffer = [input mutableCopy];
        [buffer addAttribute:HKWMentionAttributeName value:mention range:HKW_FULL_RANGE(input)];
        for (NSString *attributeName in mentionAttributes) {
            id const attributeValue = mentionAttributes[attributeName];
            if (!attributeValue) {
                NSAssert(NO, @"Internal error");
                continue;
            }
            [buffer addAttribute:attributeName value:attributeValue range:HKW_FULL_RANGE(input)];
        }
        return buffer;
    }];
    parentTextView.selectedRange = originalRange;

    // Update the mentions attributes.
    location = parentTextView.selectedRange.location;
    unichar precedingChar = [parentTextView characterPrecedingLocation:(NSInteger)location];
    // Advance the state, as if the insertion point changed
    [self advanceStateForInsertionChanged:precedingChar location:location];
}

// Programmatically add a number of mentions to the text view's text.
- (void)addMentions:(NSArray *)mentions {
    for (id object in mentions) {
        if ([object isKindOfClass:[HKWMentionsAttribute class]]) {
            [self addMention:(HKWMentionsAttribute *)object];
        }
    }
}

// Delegate method called when the plug-in is registered to a text view. Actual setup takes place in 'initialSetup'.
- (void)performInitialSetup {
    __strong __auto_type parentTextView = self.parentTextView;
    NSAssert(parentTextView != nil, @"Internal error: parent text view is nil; it should have been set already");
    if (parentTextView.isFirstResponder) {
        [self initialSetup];
    }
}

/// Perform initial setup and put the mentions plug-in into a known good state. This setup takes place the first time
/// the text view becomes the first responder, or immediately if the text view already is the first responder.
- (void)initialSetup {
    self.initialSetupPerformed = YES;
    __strong __auto_type parentTextView = self.parentTextView;

    // Disable 'undo'; it doesn't work right with mentions yet
    self.shouldEnableUndoUponUnregistration = [parentTextView.undoManager isUndoRegistrationEnabled];
    [parentTextView.undoManager disableUndoRegistration];

    // Disable spell checking
    [parentTextView overrideSpellCheckingWith:UITextSpellCheckingTypeNo];

    // Initialize the state (as if the insertion point changed)
    NSUInteger location = parentTextView.selectedRange.location;
    unichar precedingChar = [parentTextView characterPrecedingLocation:(NSInteger)location];
    [self advanceStateForInsertionChanged:precedingChar location:location];
    [self.creationStateMachine fetchInitialMentions];
}

// Delegate method called when the plug-in is unregistered from a text view. Cleans up the state of the text view.
- (void)performFinalCleanup {
    // Cancel mentions creation, if it's happening
    if (self.state == HKWMentionsStartDetectionStateCreatingMention) {
        [self.creationStateMachine cancelMentionCreation];
    }

    // Remove the accessory view from the parent text view's view hierarchy
    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView detachAccessoryView:self.chooserView];
    [self.creationStateMachine resetChooserView];

    // Enable 'undo' if this plug-in is being unregistered
    if (self.shouldEnableUndoUponUnregistration) {
        [parentTextView.undoManager enableUndoRegistration];
    }
    // Restore the parent text view's spell checking
    [parentTextView restoreOriginalSpellChecking:NO];

    self.initialSetupPerformed = NO;
}


#pragma mark - Utility

+ (NSArray *)mentionsAttributesInAttributedString:(NSAttributedString *)attributedString {
    if (!attributedString || [attributedString length] == 0) {
        return nil;
    }
    NSMutableArray *buffer = [NSMutableArray array];
    [attributedString enumerateAttributesInRange:HKW_FULL_RANGE(attributedString)
                                         options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                      usingBlock:^(NSDictionary *attrs, NSRange range, __unused BOOL *stop) {
                                          for (NSString *attributeName in attrs) {
                                              if (attributeName != HKWMentionAttributeName) {
                                                  continue;
                                              }
                                              id object = attrs[attributeName];
                                              if (![object isKindOfClass:[HKWMentionsAttribute class]]) {
                                                  // This won't ever happen if the proper library methods are used to
                                                  //  work with mentions.
                                                  HKWLOG(@"WARNING: mentionsAttributesInAttributedString found \
                                                         invalid data attached to a mentions attribute. Only use the \
                                                         methods provided to work with mentions attributes.");
                                                  continue;
                                              }
                                              HKWMentionsAttribute *attributeData = (HKWMentionsAttribute *)object;
                                              attributeData.range = range;
                                              [buffer addObject:attributeData];
                                          }
                                      }];
    return [buffer copy];
}


#pragma mark - UI

- (void)singleLineViewportChanged {
    [self.creationStateMachine hideChooserArrow];
}

- (void)singleLineViewportTapped {
    if (self.state == HKWMentionsStartDetectionStateCreatingMention) {
        // If user taps on the text view, cancel mentions creation.
        [self.creationStateMachine cancelMentionCreation];
        NSAssert(self.state == HKWMentionsStateQuiescent,
                 @"Logic error: cancelMentionCreation must always set the state back to quiescent.");
    }
}

- (void)setChooserTopLevelView:(UIView *)topLevelView attachmentBlock:(void(^)(UIView *))block {
    self.customModeAttachmentBlock = block;
    [self.parentTextView setTopLevelViewForAccessoryViewPositioning:topLevelView];
}

- (CGRect)chooserViewFrame {
    return [self.creationStateMachine chooserViewFrame];
}

- (CGRect)calculatedChooserFrameForMode:(HKWMentionsChooserPositionMode)mode
                             edgeInsets:(UIEdgeInsets)edgeInsets {
    if (!self.parentTextView) {
        HKWLOG(@"WARNING! No parent text view set. Don't call calculatedChooserViewFrameForMode until the mentions \
               plug-in has been registered to an editor text view.");
    }
    CGRect frame = [self.creationStateMachine frameForMode:mode];
    if (!CGRectIsNull(frame)) {
        frame.origin.x += edgeInsets.left;
        frame.origin.y += edgeInsets.top;
        frame.size.width -= (edgeInsets.left + edgeInsets.right);
        frame.size.height -= (edgeInsets.top + edgeInsets.bottom);
    }
    return frame;
}


#pragma mark - Private

/*!
 Return whether or not a given string is eligible to be appended to the start detection state machine's buffer.
 Minimum requirements include not containing any whitespace or newline characters or in case of dication string input.
 */
- (BOOL)stringValidForMentionsCreation:(NSString *)string {
    if ([string length] == 0) {
        return NO;
    }

    if ([self.dictationString isEqualToString:string]) {
        return YES;
    }

    NSCharacterSet *invalidChars = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSUInteger i=0; i<[string length]; i++) {
        unichar c = [string characterAtIndex:i];
        if ([invalidChars characterIsMember:c]) { return NO; }
        if (self.controlCharacterSet && [self.controlCharacterSet characterIsMember:c]) {
            return NO;
        }
    }
    return YES;
}

/*!
 Build a new typing attributes dictionary by stripping mentions-specific attributes from an original attributes
 dictionary and, if applicable, restoring default attributes from the parent text view.
 */
- (NSDictionary *)typingAttributesByStrippingMentionAttributes:(NSDictionary *)originalAttributes {
    NSMutableDictionary *d = [originalAttributes mutableCopy];
    for (NSString *key in self.mentionUnselectedAttributes) {
        [d removeObjectForKey:key];
    }
    // Restore the font and/or text color, if the app set either explicitly at any point.
    __strong __auto_type parentTextView = self.parentTextView;
    if (parentTextView.fontSetByApp) {
        d[NSFontAttributeName] = parentTextView.fontSetByApp;
    }
    if (parentTextView.textColorSetByApp) {
        d[NSForegroundColorAttributeName] = parentTextView.textColorSetByApp;
    }
    return d;
}

/*!
 Remove the mentions-specific attributes from the parent text view's \c typingAttributes dictionary. This is necessary
 to prevent the color used to denote attributes from 'bleeding' over into newly typed text.
 */
- (void)stripCustomAttributesFromTypingAttributes {
    __strong __auto_type parentTextView = self.parentTextView;
    NSDictionary *oldAttrs = parentTextView.typingAttributes;
    parentTextView.typingAttributes = [self typingAttributesByStrippingMentionAttributes:oldAttrs];
}

/*!
 Toggle mentions-related formatting for a given portion of text. Mentions can either be 'selected' (annotation
 background, light text color), or 'unselected' (no background, dark text color)
 */
- (void)toggleMentionsFormattingAtRange:(NSRange)range
                               selected:(BOOL)selected {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    __strong __auto_type parentTextView = self.parentTextView;
#ifdef DEBUG
    // For development: assert that a mention actually exists
    NSRange dataRange;
    NSAttributedString *parentText = parentTextView.attributedText;
    id mentionData = [parentText attribute:HKWMentionAttributeName
                                   atIndex:range.location
                     longestEffectiveRange:&dataRange
                                   inRange:HKW_FULL_RANGE(parentText)];
    NSAssert(mentionData, @"There must be a mention at this location. There was no mention attribute found.");
    NSAssert([mentionData isKindOfClass:[HKWMentionsAttribute class]],
             @"The mention attribe was found, but its value was of an unexpected type: '%@'",
             NSStringFromClass([mentionData class]));
    NSAssert(NSEqualRanges(range, dataRange), @"There must be a mention at this location. Mentions range was {%ld, \
             %ld}, but effective range was {%ld, %ld}",
             (unsigned long)range.location, (unsigned long)range.length,
             (unsigned long)dataRange.location, (unsigned long)dataRange.length);
#endif

    NSDictionary *unselectedAttributes = self.mentionUnselectedAttributes;
    NSDictionary *selectedAttributes = self.mentionSelectedAttributes;
    // Save the range so the cursor doesn't move.
    [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        NSDictionary *attributesToRemove = (selected ? unselectedAttributes : selectedAttributes);
        NSDictionary *attributesToAdd = (selected ? selectedAttributes : unselectedAttributes);
        for (NSString *key in attributesToRemove) {
            [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
        }
        for (NSString *key in attributesToAdd) {
            id const attributeValue = attributesToAdd[key];
            if (!attributeValue) {
                NSAssert(NO, @"Internal error");
                continue;
            }
            [buffer addAttribute:key value:attributeValue range:HKW_FULL_RANGE(input)];
        }
        return [buffer copy];
    }];
    if (!selected) {
        [self stripCustomAttributesFromTypingAttributes];
    }
}

/*!
 'Bleach' all mentions that fall within a certain range. This is used when multiple characters' worth of text must be
 deleted; mentions formatting is stripped if part or all of a mention is part of the excised text. This method returns
 the number of mentions that were bleached.
 */
- (NSUInteger)bleachMentionsWithinRange:(NSRange)bleachRange {
    if (bleachRange.location == NSNotFound || bleachRange.length == 0) {
        return 0;
    }
    NSMutableArray *ranges = [NSMutableArray array];
    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView.attributedText enumerateAttributesInRange:HKW_FULL_RANGE(parentTextView.attributedText)
                                                      options:0
                                                   usingBlock:^(NSDictionary *attrs, NSRange range, __unused BOOL *stop) {
                                                       // Find all attributes in the string subsection.
                                                       if (NSIntersectionRange(range, bleachRange).length == 0) {
                                                           // We only care about attributes whose effective ranges
                                                           //  lie within bleachRange
                                                           return;
                                                       }
                                                       HKWMentionsAttribute *value = attrs[HKWMentionAttributeName];
                                                       if (value) {
                                                           [ranges addObject:[NSValue valueWithRange:range]];
                                                       }
                                                   }];
    NSDictionary *selectedAttributes = self.mentionSelectedAttributes;
    NSDictionary *unselectedAttributes = self.mentionUnselectedAttributes;
    for (NSValue *v in ranges) {
        [parentTextView transformTextAtRange:[v rangeValue]
                             withTransformer:^NSAttributedString *(NSAttributedString *input) {
                                 NSMutableAttributedString *buffer = [input mutableCopy];
                                 [buffer removeAttribute:HKWMentionAttributeName range:HKW_FULL_RANGE(input)];
                                 // NOTE: We may need to add support for capturing and restoring any attributes
                                 //  overwritten by applying the special mentions attributes in the future.
                                 for (NSString *key in unselectedAttributes) {
                                     [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
                                 }
                                 for (NSString *key in selectedAttributes) {
                                     [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
                                 }
                                 return [buffer copy];
                             }];
    }
    return [ranges count];
}

/*!
 'Bleach' a mention by removing the mention attribute and all mentions-specific formatting for the mention at the given
 range. This destroys the mention but leaves the plain text intact.
 */
- (void)bleachExistingMentionAtRange:(NSRange)range {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    __strong __auto_type parentTextView = self.parentTextView;
#ifdef DEBUG
    // For development: assert that a mention actually exists
    NSRange dataRange;
    NSAttributedString *parentText = parentTextView.attributedText;
    id mentionData = [parentText attribute:HKWMentionAttributeName
                                   atIndex:range.location
                     longestEffectiveRange:&dataRange
                                   inRange:HKW_FULL_RANGE(parentText)];
    NSAssert([mentionData isKindOfClass:[HKWMentionsAttribute class]]
             && dataRange.length == range.length
             && dataRange.location == range.location,
             @"There must be a mention at this location. Mentions range was {%ld, %ld}, but effective range was \
             {%ld, %ld}",
             (unsigned long)range.location, (unsigned long)range.length, (unsigned long)dataRange.location,
             (unsigned long)dataRange.length);
#endif

    NSDictionary *unselectedAttributes = self.mentionUnselectedAttributes;
    NSDictionary *selectedAttributes = self.mentionSelectedAttributes;
    [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        [buffer removeAttribute:HKWMentionAttributeName range:HKW_FULL_RANGE(input)];
        // NOTE: We may need to add support for capturing and restoring any attributes overwritten by applying the
        //  special mentions attributes in the future.
        for (NSString *key in selectedAttributes) {
            [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
        }
        for (NSString *key in unselectedAttributes) {
            [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
        }
        return [buffer copy];
    }];
}

/*!
 Return whether or not a mention can be trimmed.

 \param mention          a \c HKWMentionsAttribute object representing the candidate mention
 \param stringPointer    an optional pointer to an NSString reference which will be populated with the trimmed version
                         of the name; if this method returns NO the value of the passed-back string is undefined
 */
- (BOOL)mentionCanBeTrimmed:(HKWMentionsAttribute *)mention
              trimmedString:(NSString * __autoreleasing *)stringPointer {
    // See if the mention is valid
    if (!mention) { return NO; }
    // See if the delegate will allow the mention to be trimmed
    __strong __auto_type delegate = self.defaultChooserViewDelegate;
    __strong __auto_type strongCustomChooserViewDelegate = self.customChooserViewDelegate;
    BOOL delegateImplementsCustomTrimming = [delegate respondsToSelector:@selector(trimmedNameForEntity:)];
    BOOL delegateAllowsTrimming = NO;
    if ([strongCustomChooserViewDelegate respondsToSelector:@selector(entityCanBeTrimmed:)]) {
        delegateAllowsTrimming = [strongCustomChooserViewDelegate entityCanBeTrimmed:mention];
    } else if ([delegate respondsToSelector:@selector(entityCanBeTrimmed:)]) {
        delegateAllowsTrimming = [delegate entityCanBeTrimmed:mention];
    }
    if (!delegateAllowsTrimming) { return NO; }
    // See if the mention is actually eligible for trimming
    NSString *text = [mention mentionText];
    NSRange whitespaceRange = [text rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (whitespaceRange.location == NSNotFound && !delegateImplementsCustomTrimming) {
        return NO;
    }
    // Return the trimmed string to the caller
    if (stringPointer != NULL) {
        *stringPointer = (delegateImplementsCustomTrimming
                          ? [delegate trimmedNameForEntity:mention]
                          : [text substringWithRange:NSMakeRange(0, whitespaceRange.location)]);
        if ([(*stringPointer) length] == 0 || [(*stringPointer) isEqualToString:text]) {
            // It's not valid to trim a mention to itself, or to return an empty string
            return NO;
        }
    }
    return delegateImplementsCustomTrimming || (whitespaceRange.length > 0);
}

- (HKWMentionsAttribute *)mentionAttributeAtLocation:(NSUInteger)location
                                               range:(NSRangePointer)range {
    __strong __auto_type parentTextView = self.parentTextView;
    if (location > [parentTextView.attributedText length]) {
        NSAssert(NO, @"Can't have a location beyond bounds of parent view");
        return nil;
    }
    NSAttributedString *parentText = parentTextView.attributedText;
    id value = [parentText attribute:HKWMentionAttributeName
                             atIndex:location
                           effectiveRange:range];
    if ([value isKindOfClass:[HKWMentionsAttribute class]]) {
        // Typechecking
        return (HKWMentionsAttribute *)value;
    }
    return nil;
}

- (HKWMentionsAttribute *)mentionAttributePrecedingLocation:(NSUInteger)location
                                                      range:(NSRangePointer)range {
    __strong __auto_type parentTextView = self.parentTextView;
    if (location < 1 || location > [parentTextView.attributedText length]) {
        // No mention can precede the beginning of the text view.
        return nil;
    }
    NSAttributedString *parentText = parentTextView.attributedText;
    id value = [parentText attribute:HKWMentionAttributeName
                             atIndex:location - 1
               longestEffectiveRange:range
                             inRange:HKW_FULL_RANGE(parentText)];
    if ([value isKindOfClass:[HKWMentionsAttribute class]]) {
        // Typechecking
        return (HKWMentionsAttribute *)value;
    }
    NSAssert(value == nil, @"The value for a LIMentionAttribute must be an HKWMentionsAttribute object.");
    return nil;
}

/*!
 Return YES if the given range touches at least one mention attribute.
 */
- (BOOL)rangeTouchesMentions:(NSRange)range {
    // EXAMPLES: (| = insertion point; { } = selection range)
    // |Mention1 --> YES
    // Ment|ion1 --> YES
    // Mention1| --> YES
    // NotAMention| Mention1 --> NO
    // Mention1{ some text} --> YES
    // {Mention1 some text} --> YES
    // Ment{ion1 some text} --> YES
    // {some text}Mention1 --> YES
    // {some text} Mention1 --> NO

    if (range.location == NSNotFound) {
        return NO;
    }
    __strong __auto_type parentTextView = self.parentTextView;
    // CASE 1: zero-length range (e.g. insertion point)
    if (range.length == 0) {
        if ([self mentionAttributePrecedingLocation:range.location range:NULL]
            || ((range.location + 1) <= [parentTextView.text length] && [self mentionAttributePrecedingLocation:(range.location + 1) range:NULL])) {
            // Mention exists either before the location, or right after the location
            return YES;
        }
        return NO;
    }
    // CASE 2: selection range
    for (NSUInteger i = 0; i < range.length + 1; i++) {
        NSUInteger currentLocation = range.location + i;
        if (currentLocation > [parentTextView.text length]) {
            // Out of bounds
            return NO;
        }
        if ([self mentionAttributePrecedingLocation:currentLocation range:NULL] != nil) {
            return YES;
        }
    }
    return NO;
}

- (void)assertMentionsDataExists {
    NSAssert(self.currentlySelectedMention != nil, @"Currently selected mention was nil. This is unexpected.");
    NSAssert(self.currentlySelectedMentionRange.location != NSNotFound
             && self.currentlySelectedMentionRange.length != 0,
             @"Currently selected mention range was nil. This is unexpected.");
}

/*!
 Manually perform a character insertion. This is useful in order to avoid certain built-in \c UITextView side effects.
 */
- (void)manuallyInsertCharacter:(unichar)character
                     atLocation:(NSUInteger)location
                     inTextView:(HKWTextView *)textView {
    unichar stackC = character;
    [textView insertPlainText:[NSString stringWithCharacters:&stackC length:1] location:location];
    textView.selectedRange = NSMakeRange(location + 1, 0);
}

- (void)resetCurrentMentionsData {
    self.currentlySelectedMention = nil;
    self.currentlySelectedMentionRange = NSMakeRange(NSNotFound, 0);
}

- (void)resetAuxiliaryState {
    self.suppressSelectionChangeNotifications = NO;
    self.nextSelectionChangeShouldBeIgnored = NO;
    self.previousInsertionLocation = NSNotFound;
    self.previousSelectionRange = NSMakeRange(NSNotFound, 0);
    self.previousTextLength = 0;
    [self resetCurrentMentionsData];
}

- (void)toggleAutocorrectAsRequiredForRange:(NSRange)range {
    // PROVISIONAL FIX: Determine whether or not a mention exists, and disable or enable autocorrect
    if (self.state == HKWMentionsPluginStateCreatingMention) {
        return;
    }
    __strong __auto_type parentTextView = self.parentTextView;
    BOOL shouldDisable = [self rangeTouchesMentions:range] || [self rangeTouchesMentions:parentTextView.selectedRange];
    if (shouldDisable) {
        [parentTextView overrideAutocorrectionWith:UITextAutocorrectionTypeNo];
    }
    else {
        [parentTextView restoreOriginalAutocorrection:YES];
    }
}

#pragma mark - State machine

/*!
 Advance the state machine when a single character is typed by the user or otherwise inserted.

 \returns if the method that called this was the text view delegate method to determine whether or not to allow the text
          view to insert the typed character, YES if the text view should, or NO otherwise (e.g. if the mentions plug-in
          programmatically updated the text instead)
 */
- (BOOL)advanceStateForCharacterInsertion:(unichar)newChar
                       precedingCharacter:(unichar)precedingChar
                                 location:(NSUInteger)location {
    BOOL returnValue = YES;
    self.characterForAdvanceStateForCharacterInsertion = newChar;
    __strong __auto_type parentTextView = self.parentTextView;
    // In certain situations, the double space --> period behavior is suppressed in order to prevent undesired behavior
    BOOL isSecondSpace = (location > 1) && (precedingChar == ' ' && newChar == ' ');
    switch (self.state) {
        case HKWMentionsStateQuiescent: {
            // Word following typed character would be used to trigger matching mentions menu when possible.
            NSString *wordFollowingTypedCharacter;
            wordFollowingTypedCharacter = [HKWMentionsStartDetectionStateMachine wordAfterLocation:location text:parentTextView.text];
            // Inform the start detection state machine that a character was inserted. Also, override the double space
            //  to period auto-substitution if the substitution would place a period right after a preceding mention.
            [self.startDetectionStateMachine characterTyped:newChar
                                        asInsertedCharacter:NO
                                          previousCharacter:precedingChar
                                wordFollowingTypedCharacter:wordFollowingTypedCharacter];
            NSRange r;
            id mentionTwoPreceding = [self mentionAttributePrecedingLocation:(location-1) range:&r];
            BOOL shouldSuppress = (mentionTwoPreceding != nil) && (r.location + r.length == location-1);
            if (isSecondSpace && shouldSuppress) {
                [self manuallyInsertCharacter:newChar atLocation:location inTextView:parentTextView];
                self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
                returnValue = NO;
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention:
            // Inform the mentions creation state machine that a character was typed. Do not allow the double space to
            //  period auto-substitution while the user is creating a mention.
            [self.creationStateMachine characterTyped:newChar];
            if (isSecondSpace) {
                [self manuallyInsertCharacter:newChar atLocation:location inTextView:parentTextView];
                self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
                returnValue = NO;
            }
            break;
        case HKWMentionsStateAboutToSelectMention:
            // If the user's cursor was at the end of a mention and they tap 'delete', select the mention. Otherwise,
            //  insert a new character and continue in the quiescent state. Do not allow auto-substitution.
            self.state = HKWMentionsStateQuiescent;
            [self resetCurrentMentionsData];
            [self.startDetectionStateMachine characterTyped:newChar
                                        asInsertedCharacter:NO
                                          previousCharacter:precedingChar
                                wordFollowingTypedCharacter:nil];
            if (isSecondSpace) {
                [self manuallyInsertCharacter:newChar atLocation:location inTextView:parentTextView];
                self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
                returnValue = NO;
            }
            break;
        case HKWMentionsStateSelectedMention:
            // If the user's cursor was at the end of a mention, deselect the mention and insert the character. If the
            //  character is being inserted in the middle of a mention, bleach the mention instead.
            if (location == self.currentlySelectedMentionRange.location + self.currentlySelectedMentionRange.length) {
                // At the end of the range, so deselect the mention
                [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
            }
            else {
                // Bleach the current mention and move back to the 'quiescent' state.
                [self bleachExistingMentionAtRange:self.currentlySelectedMentionRange];
            }
            [self manuallyInsertCharacter:newChar atLocation:location inTextView:parentTextView];
            [self resetCurrentMentionsData];
            self.state = HKWMentionsStateQuiescent;
            self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
            [self.startDetectionStateMachine characterTyped:newChar asInsertedCharacter:YES previousCharacter:precedingChar wordFollowingTypedCharacter:nil];
            returnValue = NO;
            break;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            break;
    }
    if (returnValue) {
        self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
    }
    NSRange searchRange = [parentTextView rangeForWordPrecedingLocation:location searchToEnd:NO];
    if (searchRange.location == NSNotFound) {
        searchRange = NSMakeRange(location, 0);
    }
    [self toggleAutocorrectAsRequiredForRange:searchRange];
    return returnValue;
}

/*!
 Advance the state machine when a single character is deleted.
 */
- (BOOL)advanceStateForCharacterDeletion:(unichar)precedingChar
                        deletedCharacter:(unichar)deletedChar
                                location:(NSUInteger)location {
    BOOL returnValue = YES;
    __strong __auto_type parentTextView = self.parentTextView;
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    switch (self.state) {
        case HKWMentionsStateQuiescent: {
            [self.startDetectionStateMachine deleteTypedCharacter:deletedChar
                                  withCharacterNowPrecedingCursor:precedingChar
                                                         location:location
                                                     textViewText:parentTextView.text];
            self.nextSelectionChangeShouldBeIgnored = YES;

            // Look for a mention
            if (location > 0) {
                NSRange mentionRange;
                HKWMentionsAttribute *precedingMention = [self mentionAttributePrecedingLocation:location
                                                                                           range:&mentionRange];
                if (precedingMention) {
                    // There is a mention right before the cursor's current position.
                    // If the user taps 'delete' again, they will actually select the mention.
                    self.currentlySelectedMention = precedingMention;
                    self.currentlySelectedMentionRange = mentionRange;
                    self.state = HKWMentionsStateAboutToSelectMention;
                }
                else {
                    // Enter mention creation mode when a whitespace character is deleted which puts the cursor
                    // to the right of a word
                    NSCharacterSet *whitespaceSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
                    if ([whitespaceSet characterIsMember:deletedChar] && ![whitespaceSet characterIsMember:precedingChar]) {
                        // Capture the previous word that the cursor has encountered. Start by grabbing the left side of
                        // the string starting from 0 to the deleted character's index
                        NSString *leftString = [parentTextView.text substringToIndex:location];
                        if ([leftString length] > 0) {
                            NSInteger index = (NSInteger)[leftString length] - 1;
                            // Grab the start index of word to the left of the cursor by walking backwards through the string
                            // until a whitespace char is hit or the beginning of the string
                            for (; index >= 0; index--) {
                                unichar c = [leftString characterAtIndex:(NSUInteger)index];
                                if ([whitespaceSet characterIsMember:c]) {
                                    break;
                                }
                            }
                            index++; // Advance the index to avoid capturing the space or -1 when hitting the lower bound

                            // it is safe to convert the signed integer to unsigned at this point since it is now non-negative
                            const NSUInteger stringIndex = (NSUInteger)index;
                            NSString *adjacentWord = [leftString substringFromIndex:stringIndex];
                            if ([adjacentWord length] > 0) {
                                unichar firstChar = [adjacentWord characterAtIndex:0];
                                BOOL usesControlChar = [self.controlCharacterSet characterIsMember:firstChar];
                                if (usesControlChar) {
                                    adjacentWord = [adjacentWord substringFromIndex:1];
                                }
                                if ([adjacentWord length] > 0) {
                                    [self.startDetectionStateMachine validStringInserted:adjacentWord
                                                                              atLocation:stringIndex
                                                                   usingControlCharacter:usesControlChar
                                                                        controlCharacter:(usesControlChar ? firstChar : 0)];
                                }
                            }
                        }
                    }
                }
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // Look for a mention
            // NOTE: There should be no mention immediately preceding the creation start point. This can never happen
            //  at present, since mentions creation cannot be started unless at the beginning of the text view or there
            //  is a space/newline preceding, but if this is changed then the state machine must be primed in case there
            //  is a mention right before the mention creation point.
            unichar stackC = deletedChar;
            [self.creationStateMachine stringDeleted:[NSString stringWithCharacters:&stackC length:1]];
            // Get prior character to properly prime start detection state machine
            if (self.state == HKWMentionsStateQuiescent) {
                // If we're in here, the mention creation ended (and by extension, we moved back to Quiescent)
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingChar];
            }
            self.nextSelectionChangeShouldBeIgnored = YES;
            break;
        }
        case HKWMentionsStateAboutToSelectMention: {
            // Select the mention; no text should actually be added or deleted
            [self assertMentionsDataExists];
            [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:YES];
            self.state = HKWMentionsStateSelectedMention;
            returnValue = NO;
            break;
        }
        case HKWMentionsStateSelectedMention: {
            // Trim or delete the currently selected mention
            [self assertMentionsDataExists];
            NSString *trimmedString = nil;
            BOOL canTrim = [self mentionCanBeTrimmed:self.currentlySelectedMention trimmedString:&trimmedString];
            if (canTrim) {
                // Trim mention to first word only
                NSAssert([trimmedString length] > 0,
                         @"Cannot trim a mention to zero length");
                self.currentlySelectedMention.mentionText = trimmedString;
                [parentTextView transformTextAtRange:self.currentlySelectedMentionRange
                                     withTransformer:^NSAttributedString *(NSAttributedString *input) {
                                         return [input attributedSubstringFromRange:NSMakeRange(0, [trimmedString length])];
                                     }];
                self.currentlySelectedMentionRange = NSMakeRange(self.currentlySelectedMentionRange.location,
                                                                 [trimmedString length]);
                // Move the cursor into position.
                parentTextView.selectedRange = NSMakeRange(self.currentlySelectedMentionRange.location + [trimmedString length],
                                                           0);
                location = parentTextView.selectedRange.location;

                // Notify the plugin's state change delegate that a mention was trimmed.
                if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPlugin:trimmedMention:atLocation:)]) {
                    [strongStateChangeDelegate mentionsPlugin:self trimmedMention:self.currentlySelectedMention atLocation:location];
                }
                // Notify the parent text view's external delegate that the text changed, since a mention was trimmed.
                if (self.notifyTextViewDelegateOnMentionTrim
                    && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
                    [externalDelegate textViewDidChange:parentTextView];
                }
            }
            else {
                // Delete mention entirely
                NSAssert(self.currentlySelectedMentionRange.location != NSNotFound,
                         @"Logic error: preparing to delete a mention, but the currently selected mention range is invalid");
                NSUInteger locationAfterDeletion = self.currentlySelectedMentionRange.location;
                unichar newPrecedingChar = [parentTextView characterPrecedingLocation:(NSInteger)locationAfterDeletion];
                [self bleachExistingMentionAtRange:self.currentlySelectedMentionRange];
                [parentTextView transformTextAtRange:self.currentlySelectedMentionRange
                                     withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
                                         return (NSAttributedString *)nil;
                                     }];
                [self stripCustomAttributesFromTypingAttributes];
                parentTextView.selectedRange = NSMakeRange(locationAfterDeletion, 0);

                // Store current mention before reset
                HKWMentionsAttribute *currentMention = self.currentlySelectedMention;
                [self resetCurrentMentionsData];
                self.state = HKWMentionsStateQuiescent;
                // Update selection state
                self.previousSelectionRange = parentTextView.selectedRange;
                self.previousTextLength = [parentTextView.text length];
                // Prime mentions detection state machine
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:newPrecedingChar];
                // Look for another mention. If there is a mention immediately preceding the just-deleted mention, the
                //  state machine needs to be immediately primed to 'AboutToSelectMention'.
                if (locationAfterDeletion > 0) {
                    NSRange mentionRange;
                    HKWMentionsAttribute *precedingMention = [self mentionAttributePrecedingLocation:locationAfterDeletion
                                                                                               range:&mentionRange];
                    if (precedingMention) {
                        // There is a mention right before the cursor's current position.
                        // If the user taps 'delete' again, they will actually select the mention.
                        self.currentlySelectedMention = precedingMention;
                        self.currentlySelectedMentionRange = mentionRange;
                        self.state = HKWMentionsStateAboutToSelectMention;
                    }
                }
                location = locationAfterDeletion;
                // Notify the plugin's state change delegate that a mention was deleted.
                if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPlugin:deletedMention:atLocation:)]) {
                    [strongStateChangeDelegate mentionsPlugin:self deletedMention:currentMention atLocation:location];
                }

                // Notify the parent text view's external delegate that the text changed, since a mention was deleted.
                if (self.notifyTextViewDelegateOnMentionDeletion
                    && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
                    [externalDelegate textViewDidChange:parentTextView];
                }
            }
            returnValue = NO;
            break;
        }
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            break;
    }
    NSRange searchRange = [parentTextView rangeForWordPrecedingLocation:location searchToEnd:NO];
    if (searchRange.location == NSNotFound) {
        searchRange = NSMakeRange(location, 0);
    }
    [self toggleAutocorrectAsRequiredForRange:searchRange];
    return returnValue;
}

/*!
 Advance the state machine when a multi-character string is inserted (due to copy-paste).
 */
- (BOOL)advanceStateForStringInsertionAtRange:(NSRange)range text:(NSString *)text {
    __strong HKWTextView *parentTextView = self.parentTextView;
    NSRange originalSelectedRange = parentTextView.selectedRange;
    unichar precedingChar = [text characterAtIndex:[text length] - 1];
    unichar originalPrecedingChar = [parentTextView characterPrecedingLocation:(NSInteger)range.location];
    if (parentTextView.selectedRange.length > 0) {
        // Multiple characters are selected. Bleach everything in the selection range before continuing.
        [self bleachMentionsWithinRange:parentTextView.selectedRange];
        parentTextView.selectedRange = originalSelectedRange;
    }

    // Strip the mentions-specific typing attributes.
    NSDictionary *parentTypingAttrs = parentTextView.typingAttributes;
    NSDictionary *typingAttrs = [self typingAttributesByStrippingMentionAttributes:parentTypingAttrs];

    switch (self.state) {
        case HKWMentionsStateQuiescent: {
            if ([text length] == 1) {
                // Special handling: treat the inserted character as a typed-in character
                // Manually replace the text
                [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
                    return [[NSAttributedString alloc] initWithString:text
                                                           attributes:typingAttrs];
                }];
                NSRange newSelectionRange = NSMakeRange(range.location + 1, 0);
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:originalPrecedingChar];

                // Fix the range selection and insertion/deletion detection state
                parentTextView.selectedRange = newSelectionRange;
                self.previousSelectionRange = newSelectionRange;
                self.previousTextLength = [[parentTextView text] length];

                [self.startDetectionStateMachine characterTyped:[text characterAtIndex:0]
                                            asInsertedCharacter:YES
                                              previousCharacter:precedingChar
                                    wordFollowingTypedCharacter:nil];
                // Manually notify external delegate that the textView changed
                id<HKWTextViewDelegate> externalDelegate = parentTextView.externalDelegate;
                if ([externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
                    [externalDelegate textViewDidChange:parentTextView];
                }
                return NO;
            }
            else if ([self stringValidForMentionsCreation:text]) {
                // Special handling: this string is valid for wholesale insertion
                // Manually replace the text
                [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
                    return [[NSAttributedString alloc] initWithString:text
                                                           attributes:typingAttrs];
                }];
                NSRange newSelectionRange = NSMakeRange(range.location + [text length], 0);
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:originalPrecedingChar];

                // Fix the range selection and insertion/deletion detection state
                parentTextView.selectedRange = newSelectionRange;
                self.previousSelectionRange = newSelectionRange;
                self.previousTextLength = [[parentTextView text] length];

                NSUInteger location = parentTextView.selectedRange.location - [text length];
                [self.startDetectionStateMachine validStringInserted:text
                                                          atLocation:location
                                               usingControlCharacter:NO
                                                    controlCharacter:0];

                // Manually notify external delegate that the textView changed
                id<HKWTextViewDelegate> externalDelegate = parentTextView.externalDelegate;
                if ([externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
                    [externalDelegate textViewDidChange:parentTextView];
                }
                return NO;
            }
            else {
                // Resume scanning; use the end of the pasted-in text as the beginning of the buffer
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingChar];
            }
            break;
        }
        case HKWMentionsStartDetectionStateCreatingMention: {
            // If one or more characters are inserted automatically (e.g. pasting in text, certain types of keyboards),
            // insert the text, but only if it's valid.
            if ([self stringValidForMentionsCreation:text]) {
                self.characterForAdvanceStateForCharacterInsertion = [text characterAtIndex:[text length] - 1];
                [self.creationStateMachine validStringInserted:text];
                self.characterForAdvanceStateForCharacterInsertion = (unichar)0;
                break;
            }
            else {
                [self.creationStateMachine cursorMoved];
                self.state = HKWMentionsStateQuiescent;
            }
            break;
        }
        case HKWMentionsStateAboutToSelectMention:
            // Leave the 'about to select' state and resume scanning
            self.state = HKWMentionsStateQuiescent;
            [self resetCurrentMentionsData];
            [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingChar];
            break;
        case HKWMentionsStateSelectedMention:
            // Either add the text to the end of the mention, or bleach the mention and add the text to the middle
            if (parentTextView.selectedRange.length == 0) {
                if (range.location == self.currentlySelectedMentionRange.location + self.currentlySelectedMentionRange.length) {
                    // At the end of the range, so deselect the mention
                    [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
                }
                else {
                    // Bleach the current mention and move back to the 'quiescent' state.
                    [self bleachExistingMentionAtRange:self.currentlySelectedMentionRange];
                }
            }
            [parentTextView insertPlainText:text location:range.location];
            // Manually move the cursor to the 'expected' position, otherwise the cursor will jump to the end.
            parentTextView.selectedRange = NSMakeRange(range.location + [text length], 0);
            [self resetCurrentMentionsData];
            self.state = HKWMentionsStateQuiescent;
            return NO;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            break;
    }
    [self toggleAutocorrectAsRequiredForRange:range];
    return YES;
}

/*!
 Advance the state machine when multiple characters are deleted (due to copy-paste or selection delete).
 */
- (BOOL)advanceStateForStringDeletionAtRange:(NSRange)range
                               deletedString:(NSString *)deletedString
                          precedingCharacter:(unichar)precedingCharacter {
    // Remove all mentions within the selection range before continuing
    NSUInteger numberOfMentionsDestroyed = [self bleachMentionsWithinRange:range];
    switch (self.state) {
        case HKWMentionsStateQuiescent:
            [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingCharacter];
            [self resetCurrentMentionsData];
            self.state = HKWMentionsStateQuiescent;
            break;
        case HKWMentionsStartDetectionStateCreatingMention:
            [self.creationStateMachine stringDeleted:deletedString];
            self.nextSelectionChangeShouldBeIgnored = YES;
            self.nextInsertionShouldBeIgnored = YES;
            break;
        case HKWMentionsStateAboutToSelectMention:
        case HKWMentionsStateSelectedMention:
            [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingCharacter];
            [self resetCurrentMentionsData];
            self.state = HKWMentionsStateQuiescent;
            break;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            break;
    }

    // If mentions were deleted, notify the text view's external delegate as appropriate.
    __strong __auto_type parentTextView = self.parentTextView;
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    if (self.notifyTextViewDelegateOnMentionDeletion
        && numberOfMentionsDestroyed > 0
        && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [externalDelegate textViewDidChange:parentTextView];
    }

    return YES;
}

/**
 Advance the state machine when the selection changes, or when the text view changes from insertion mode to selection
 mode. If this is occuring because text is being replaced, handle the replacement text
 */
- (void)advanceStateForSelectionChanged:(NSRange)range replacementText:(nullable NSString *)replacementText {

    // Determine if current text is being replaced by a mentions string
    unichar firstReplacementTextCharacter = 0;
    BOOL isReplacementTextMention = NO;
    if (replacementText && [replacementText length] > 0) {
        firstReplacementTextCharacter = [replacementText characterAtIndex:0];
        isReplacementTextMention = [self.controlCharacterSet characterIsMember:firstReplacementTextCharacter];
    }

    self.previousSelectionRange = NSMakeRange(NSNotFound, 0);
    switch (self.state) {
        case HKWMentionsStateQuiescent:
            if (isReplacementTextMention) {
                // If we are replacing current text with a mentions string, begin the mention
                [self beginMentionsCreationWithString:replacementText
                                           atLocation:range.location
                                usingControlCharacter:YES
                                     controlCharacter:firstReplacementTextCharacter];
            }
            break;
        case HKWMentionsStartDetectionStateCreatingMention: {
            NSRange currentMentionsRange = NSMakeRange(self.resumeMentionsPriorPosition, self.resumeMentionsPriorTextLength);
            if (isReplacementTextMention && NSEqualRanges(range, currentMentionsRange)) {
                // If we are replacing a mention string with a mentions string, begin the mention
                [self beginMentionsCreationWithString:replacementText
                                           atLocation:range.location
                                usingControlCharacter:YES
                                     controlCharacter:firstReplacementTextCharacter];
            } else if (replacementText) {
                // Else if there's replacement text, treat it like an insertion
                [self advanceStateForStringInsertionAtRange:range text:replacementText];
            } else {
                // Else, cancel the mention
                [self.creationStateMachine cancelMentionCreation];
                NSAssert(self.state == HKWMentionsStateQuiescent,
                         @"Logic error: cancelMentionCreation must always set the state back to quiescent.");
            }
            break;
        }
        case HKWMentionsStateAboutToSelectMention:
            self.state = HKWMentionsStateQuiescent;
            break;
        case HKWMentionsStateSelectedMention:
            [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
            self.parentTextView.selectedRange = range;
            self.state = HKWMentionsStateQuiescent;
            break;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            return;
    }
    // TODO: If we can determine whether this method is being called because the selection was changed by the user, or
    //  because fast delete is happening, we shouldn't toggle autocorrect if fast delete is happening.
    [self toggleAutocorrectAsRequiredForRange:range];
}

/*!
 Advance the state machine when the insertion point changes (not due to characters typed or removed), or when the text
 view changes from selection mode to insertion mode.
 */
- (void)advanceStateForInsertionChanged:(unichar)precedingChar
                               location:(NSUInteger)location {
    switch (self.state) {
        case HKWMentionsStartDetectionStateCreatingMention:
            [self.creationStateMachine cancelMentionCreation];
            NSAssert(self.state == HKWMentionsStateQuiescent,
                     @"Logic error: cancelMentionCreation must always set the state back to quiescent.");
            // Fall through - do NOT break.
            // After cancelling mentions creation, look for a mention at the new insertion location and update state
            //  accordingly
        case HKWMentionsStateAboutToSelectMention:
        case HKWMentionsStateQuiescent: {
            NSRange mentionRange;
            HKWMentionsAttribute *precedingMention = nil;
            // Look for a preceding mention, but only if we're at the beginning of the text range
            precedingMention = [self mentionAttributePrecedingLocation:location
                                                                 range:&mentionRange];
            if (precedingMention) {
                // A mention was found.
                self.currentlySelectedMention = precedingMention;
                self.currentlySelectedMentionRange = mentionRange;
                if (location == mentionRange.location + mentionRange.length) {
                    // User is about to select mention
                    self.state = HKWMentionsStateAboutToSelectMention;
                }
                else {
                    // User is in the middle of the mention, and should select it
                    [self toggleMentionsFormattingAtRange:mentionRange selected:YES];
                    self.state = HKWMentionsStateSelectedMention;
                }
            }
            else {
                // No mention
                [self resetCurrentMentionsData];
                self.state = HKWMentionsStateQuiescent;
            }
            [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingChar];
            break;
        }
        case HKWMentionsStateSelectedMention: {
            [self assertMentionsDataExists];
            NSRange mentionRange;
            HKWMentionsAttribute *precedingMention = [self mentionAttributePrecedingLocation:location
                                                                                       range:&mentionRange];
            if (!precedingMention) {
                // User moved cursor away from the current mention and to a position with no mention
                [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
                [self resetCurrentMentionsData];
                self.state = HKWMentionsStateQuiescent;
                [self.startDetectionStateMachine cursorMovedWithCharacterNowPrecedingCursor:precedingChar];
            }
            else if (precedingMention != self.currentlySelectedMention) {
                // User moved cursor into a different mention.
                [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
                if (location == mentionRange.location + mentionRange.length) {
                    // User is at the end of the new mention, and should be about to select it.
                    self.state = HKWMentionsStateAboutToSelectMention;
                }
                else {
                    // User is in the middle of the new mention, and should select it
                    [self toggleMentionsFormattingAtRange:mentionRange selected:YES];
                    self.state = HKWMentionsStateSelectedMention;
                }
                self.currentlySelectedMention = precedingMention;
                self.currentlySelectedMentionRange = mentionRange;
            }
            else {
                // User moved cursor, but the cursor is still in the same mention. Don't do anything.
            }
            break;
        }
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: state machine cannot be in LosingFocus at this point.");
            break;
    }
    NSRange searchRange = [self.parentTextView rangeForWordPrecedingLocation:location searchToEnd:NO];
    if (searchRange.location == NSNotFound) {
        searchRange = NSMakeRange(location, 0);
    }
}


#pragma mark - Plug-in protocol

- (void)dataReturnedWithEmptyResults:(BOOL)isEmptyResults
         keystringEndsWithWhiteSpace:(BOOL)keystringEndsWithWhiteSpace {
    [self.creationStateMachine dataReturnedWithEmptyResults:isEmptyResults keystringEndsWithWhiteSpace:keystringEndsWithWhiteSpace];
}

-(void) textViewDidProgrammaticallyUpdate:(UITextView *)textView {
    if (self.state == HKWMentionsStartDetectionStateCreatingMention) {
        [self.creationStateMachine cancelMentionCreation];
    } else {
        self.state = HKWMentionsStateQuiescent;
    }

    [self.startDetectionStateMachine resetStateUsingString:[textView.text copy]];
    [self resetAuxiliaryState];
}

/*!
 Returns whether a string is a single control character
 */
- (BOOL)isStringControlCharacter:(NSString *)text {
    return text.length == 1 && [self.controlCharacterSet characterIsMember:[text characterAtIndex:0]];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL returnValue = YES;
    self.suppressSelectionChangeNotifications = YES;
    __strong __auto_type parentTextView = self.parentTextView;
    unichar precedingChar = [parentTextView characterPrecedingLocation:(NSInteger)range.location];

    if (self.nextInsertionShouldBeIgnored) {
        self.nextInsertionShouldBeIgnored = NO;
        self.previousSelectionRange = textView.selectedRange;
        self.previousTextLength = [textView.text length];
        self.suppressSelectionChangeNotifications = NO;
        return NO;
    }

    if (range.length == 0 && [text length] == 1) {
        // Inserting a character
        returnValue = [self advanceStateForCharacterInsertion:[text characterAtIndex:0]
                                           precedingCharacter:precedingChar
                                                     location:range.location];
    }
    else if ([text length] == 0) {
        // Deleting text
        NSString *toDeleteString = [parentTextView.text substringWithRange:range];
        if (range.length == 0) {
            // At the beginning, and delete was tapped
            self.suppressSelectionChangeNotifications = NO;
            return YES;
        }
        else if (range.length == 1) {
            // Deleting a single character
            returnValue = [self advanceStateForCharacterDeletion:precedingChar
                                                deletedCharacter:[toDeleteString characterAtIndex:0]
                                                        location:range.location];
        }
        else {
            // Deleting multiple characters
            returnValue = [self advanceStateForStringDeletionAtRange:range
                                                       deletedString:toDeleteString
                                                  precedingCharacter:precedingChar];
            // Reset the selection range
            textView.selectedRange = range;
        }
    }
    else if (range.length == 0 && [text length] > 1) {
        // Inserting text (e.g. pasting)
        returnValue = [self advanceStateForStringInsertionAtRange:range text:text];
    }
    else {
        // Replacing text (e.g. pasting, autocorrect, etc)
        [self advanceStateForSelectionChanged:NSMakeRange(range.location + ([text length] - range.length), 0) replacementText:text];
    }
    self.previousSelectionRange = textView.selectedRange;
    self.previousTextLength = [textView.text length];
    [self stripCustomAttributesFromTypingAttributes];
    self.suppressSelectionChangeNotifications = NO;
    return returnValue;
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.suppressSelectionChangeNotifications) {
        // Don't run the 'selection change' code as a result of the user entering, deleting, or modifying the text.
        return;
    }
    if (self.nextSelectionChangeShouldBeIgnored) {
        self.nextSelectionChangeShouldBeIgnored = NO;
        return;
    }
    NSRange range = textView.selectedRange;
    if ([textView.attributedText length] == 0 || NSEqualRanges(range, self.previousSelectionRange)) {
        // The selection range didn't move, or the text view is empty. Don't do anything.
        self.previousSelectionRange = textView.selectedRange;
        self.previousTextLength = [textView.text length];
        return;
    }
    else if (range.length > 1) {
        // The user selected multiple characters
        [self advanceStateForSelectionChanged:range replacementText:nil];
    }
    else if (self.previousSelectionRange.location != NSNotFound
             && labs((NSInteger)self.previousSelectionRange.location - (NSInteger)range.location) == 1
             && labs((NSInteger)self.previousTextLength - (NSInteger)[textView.text length]) == 1) {
        // The cursor moved as a result of the user entering or deleting a single character
        self.previousSelectionRange = range;
        self.previousTextLength = [textView.text length];
        self.previousInsertionLocation = range.location;
    }
    else {
        // The user moved the insertion point
        unichar precedingChar = [self.parentTextView characterPrecedingLocation:(NSInteger)range.location];
        [self advanceStateForInsertionChanged:precedingChar location:range.location];
        self.previousSelectionRange = range;
        self.previousTextLength = [textView.text length];
    }
}

- (BOOL)textViewShouldBeginEditing:(__unused UITextView *)textView {
    if (!self.initialSetupPerformed) {
        [self initialSetup];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(__unused UITextView *)textView {
    // Bring the text view back to a known good state
    __strong __auto_type parentTextView = self.parentTextView;
    NSUInteger currentLength = [parentTextView.text length];
    BOOL shouldResume = NO;
    if (self.shouldResumeMentionsCreation && self.resumeMentionsCreationEnabled) {
        self.shouldResumeMentionsCreation = NO;
        shouldResume = YES;
        if (currentLength == self.resumeMentionsPriorTextLength) {
            NSString *prefix = [parentTextView.text substringWithRange:NSMakeRange(self.resumeMentionsPriorPosition,
                                                                                   currentLength - self.resumeMentionsPriorPosition)];
            if ([prefix length] == 0 || ![prefix isEqualToString:self.resumeMentionsPriorString]) {
                // Text changed between when editing stopped, and now
                shouldResume = NO;
            }
            BOOL isExplicitMention = (self.resumeMentionsControlCharacter != 0);
            if (shouldResume && isExplicitMention) {
                if (![self.controlCharacterSet characterIsMember:self.resumeMentionsControlCharacter]) {
                    // Invalid control character specifeid
                    shouldResume = NO;
                }
                else if (self.resumeMentionsControlCharacter != [self.resumeMentionsPriorString characterAtIndex:0]) {
                    // First character of buffer doesn't match the control character
                    shouldResume = NO;
                }
            }
        }
    }
    if (shouldResume) {
        self.state = HKWMentionsStartDetectionStateCreatingMention;
        BOOL isExplicitMention = (self.resumeMentionsControlCharacter != 0);
        NSString *buffer = (isExplicitMention
                            ? [self.resumeMentionsPriorString substringFromIndex:1]
                            : self.resumeMentionsPriorString);

        self.previousSelectionRange = parentTextView.selectedRange;
        self.previousTextLength = [parentTextView.text length];
        self.previousInsertionLocation = parentTextView.selectedRange.location;

        [self.startDetectionStateMachine mentionCreationResumed];
        [self.creationStateMachine mentionCreationStartedWithPrefix:buffer
                                              usingControlCharacter:isExplicitMention
                                                   controlCharacter:self.resumeMentionsControlCharacter
                                                           location:self.resumeMentionsPriorPosition];
        return;
    }

    // Code for fixing state if no resumption is happening
    self.previousSelectionRange = NSMakeRange(0, 0);
    self.previousTextLength = [parentTextView.text length];
    self.state = HKWMentionsStateQuiescent;
    // Advance the state, as if the insertion point changed
    unichar precedingChar = [parentTextView characterPrecedingLocation:(NSInteger)parentTextView.selectedRange.location];
    [self advanceStateForInsertionChanged:precedingChar location:parentTextView.selectedRange.location];
}

- (void)textViewDidEndEditing:(__unused UITextView *)textView {
    // Text view is about to lose focus
    // Perform cleanup
    HKWMentionsState previousState = self.state;
    self.state = HKWMentionsStateLosingFocus;
    switch (previousState) {
        case HKWMentionsStateQuiescent:
            break;
        case HKWMentionsStartDetectionStateCreatingMention: {
            __strong __auto_type parentTextView = self.parentTextView;
            NSUInteger currentLength = [parentTextView.text length];
            self.shouldResumeMentionsCreation = YES;
            self.resumeMentionsPriorTextLength = [parentTextView.text length];
            self.resumeMentionsPriorString = [parentTextView.text substringWithRange:NSMakeRange(self.resumeMentionsPriorPosition,
                                                                                                 currentLength - self.resumeMentionsPriorPosition)];

            [self.creationStateMachine cancelMentionCreation];
            if (self.viewportLocksUponMentionCreation) {
                [parentTextView exitSingleLineViewportMode];
            }

            NSAssert(self.state == HKWMentionsStateQuiescent,
                     @"Logic error: cancelMentionCreation must always set the state back to quiescent.");
            break;
        }
        case HKWMentionsStateAboutToSelectMention:
            break;
        case HKWMentionsStateSelectedMention:
            [self toggleMentionsFormattingAtRange:self.currentlySelectedMentionRange selected:NO];
            break;
        case HKWMentionsStateLosingFocus:
            NSAssert(NO, @"Logic error: textViewDidEndEditing cannot be called when the state is LosingFocus.");
            break;
    }
    // Reset state
    [self resetAuxiliaryState];
    self.state = HKWMentionsStateQuiescent;
}


#pragma mark - Start detection state machine protocol

- (void)beginMentionsCreationWithString:(NSString *)prefix
                        alreadyInserted:(BOOL)alreadyInserted
                  usingControlCharacter:(BOOL)usingControlCharacter
                       controlCharacter:(unichar)character {

    __strong __auto_type parentTextView = self.parentTextView;
    NSUInteger location = parentTextView.selectedRange.location;

    // If a control character is being used, this method assumes that it is next to the cursor
    if (usingControlCharacter) {
        // Beginning an EXPLICIT MENTION by typing a single control character
        if (alreadyInserted) {
            NSAssert(self.controlCharacterSet &&
                     [self.controlCharacterSet characterIsMember:[parentTextView characterPrecedingLocation:(NSInteger)location]],
                     @"Logic error: mention started with control character, but control character was not found");
            // The control character has already been inserted into the text buffer. We need to back up the location by
            //  one in order to ensure that the inserted mention will overwrite the control character.
            location--;
        }
    }
    else {
        // Beginning an IMPLICIT MENTION by typing enough normal characters
        NSUInteger prefixLength = [prefix length] - (alreadyInserted ? 0 : 1);
        NSAssert(prefixLength <= location,
                 @"Logic error: prefixLength would make the location of the mention negative");
        location -= prefixLength;
    }

    [self beginMentionsCreationWithString:prefix
                               atLocation:location
                    usingControlCharacter:usingControlCharacter
                         controlCharacter:character];
}

- (void)beginMentionsCreationWithString:(NSString *)prefix
                             atLocation:(NSUInteger)location
                  usingControlCharacter:(BOOL)usingControlCharacter
                       controlCharacter:(unichar)character {
    // Begin mentions creation
    self.state = HKWMentionsStartDetectionStateCreatingMention;

    NSAssert(self.parentTextView.selectedRange.length == 0,
             @"Cannot start a mention unless the cursor is in insertion mode.");
    self.resumeMentionsPriorPosition = location;
    self.resumeMentionsControlCharacter = usingControlCharacter ? character : (unichar)0;
    [self.creationStateMachine mentionCreationStartedWithPrefix:prefix
                                          usingControlCharacter:usingControlCharacter
                                               controlCharacter:character
                                                       location:location];
}

#pragma mark - Mentions creation state machine protocol

- (CGRect)boundsForParentEditorView {
    return self.parentTextView.bounds;
}

- (CGPoint)originForParentEditorView {
    return self.parentTextView.frame.origin;
}

- (void)asyncRetrieveEntitiesForKeyString:(NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void (^)(NSArray *, BOOL, BOOL))completionBlock {
    // set up the chooser view prior to data request in order to support fully customized view
    [self.creationStateMachine setupChooserViewIfNeeded];
    __strong __auto_type strongCustomChooserViewDelegate = self.customChooserViewDelegate;
    if (strongCustomChooserViewDelegate) {
        [strongCustomChooserViewDelegate didUpdateKeyString:keyString
                                           controlCharacter:character];
    } else {
        [self.defaultChooserViewDelegate asyncRetrieveEntitiesForKeyString:keyString
                                                                searchType:type
                                                          controlCharacter:character
                                                                completion:completionBlock];
    }
}

- (UITableViewCell *)cellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                           withMatchString:(NSString *)matchString
                                 tableView:(UITableView *)tableView
                               atIndexPath:(NSIndexPath *)indexPath {
    return [self.defaultChooserViewDelegate cellForMentionsEntity:entity withMatchString:matchString tableView:tableView atIndexPath:indexPath];
}

- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                                tableView:(UITableView *)tableView {
    return [self.defaultChooserViewDelegate heightForCellForMentionsEntity:entity tableView:tableView];
}

- (UITableViewCell *)loadingCellForTableView:(UITableView *)tableView {
    __strong __auto_type delegate = self.defaultChooserViewDelegate;
    NSAssert([delegate respondsToSelector:@selector(loadingCellForTableView:)],
             @"The delegate does not implement the loading cell functionality. This probably means the property wasn't checked properly.");
    return [delegate loadingCellForTableView:tableView];
}

- (CGFloat)heightForLoadingCellInTableView:(UITableView *)tableView {
    __strong __auto_type delegate = self.defaultChooserViewDelegate;
    NSAssert([delegate respondsToSelector:@selector(heightForLoadingCellInTableView:)],
             @"The delegate does not implement the loading cell functionality. This probably means the property wasn't checked properly.");
    return [delegate heightForLoadingCellInTableView:tableView];
}

/*!
 Perform shared cleanup once a mention is created or mentions creation is cancelled (as signaled by the mentions
 creation state machine).
 */
- (void)performMentionCreationEndCleanup:(BOOL)canImmediatelyRestart {
    if (self.viewportLocksUponMentionCreation) {
        [self.parentTextView exitSingleLineViewportMode];
    }
    self.state = HKWMentionsStateQuiescent;
    [self.startDetectionStateMachine mentionCreationEnded:canImmediatelyRestart];
}

- (void)cancelMentionFromStartingLocation:(__unused NSUInteger)location {
    NSAssert(self.state == HKWMentionsStartDetectionStateCreatingMention || self.state == HKWMentionsStateLosingFocus,
             @"cancelMentionFromStartingLocation was invoked, but the state machine was not creating a mention or \
             performing cleanup.");
    // Note that if the mention was cancelled because the user typed a whitespace and caused no search results to return
    //  as a result, the desired behavior is to allow the start detection state machine to immediately begin searching
    //  (without waiting for a second space).
    __strong __auto_type parentTextView = self.parentTextView;
    parentTextView.shouldRejectAutocorrectInsertions = NO;
    NSUInteger currentLocation = parentTextView.selectedRange.location;
    NSCharacterSet *whitespaces = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    BOOL canRestart = ([whitespaces characterIsMember:[parentTextView characterPrecedingLocation:(NSInteger)currentLocation]]
                       || (self.characterForAdvanceStateForCharacterInsertion != 0
                           && [whitespaces characterIsMember:self.characterForAdvanceStateForCharacterInsertion])
                       || [[NSCharacterSet punctuationCharacterSet]
                           characterIsMember:[parentTextView characterPrecedingLocation:(NSInteger)currentLocation]]);
    [self performMentionCreationEndCleanup:canRestart];
    [parentTextView restoreOriginalAutocorrection:(self.state != HKWMentionsStateLosingFocus)];
}

- (void)selected:(id<HKWMentionsEntityProtocol>)entity atIndexPath:(NSIndexPath *)indexPath {
    // Inform the delegate (if appropriate)
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if ([strongStateChangeDelegate respondsToSelector:@selector(selected:atIndexPath:)]) {
        [strongStateChangeDelegate selected:entity atIndexPath:indexPath];
    }
}

- (void)createMention:(HKWMentionsAttribute *)mention cursorLocation:(NSUInteger)location {
    if (self.state != HKWMentionsStartDetectionStateCreatingMention || !mention) {
        return;
    }
    // If you create a mention, you MUST do something before the next mention can be created.
    [self performMentionCreationEndCleanup:NO];

    // Actually create the mention
    NSString *mentionText = mention.mentionText;
    __strong __auto_type parentTextView = self.parentTextView;
    NSUInteger currentLocation = parentTextView.selectedRange.location;
    NSAssert(parentTextView.selectedRange.length == 0,
             @"Cannot create a mention unless cursor is in insertion mode.");
    UIFont *parentFont = parentTextView.fontSetByApp;
    UIColor *parentColor = parentTextView.textColorSetByApp;
    NSAssert(self.mentionUnselectedAttributes != nil, @"Error! Mention attribute dictionaries should never be nil.");
    NSDictionary *unselectedAttributes = self.mentionUnselectedAttributes;

    NSRange rangeToTransform;
    // When control character is inserted before word and user selects mention for that word,
    // we want to replace word after control character with mention text.
    // e.g "hey @|john" will be replaced as "hey John Doe". '|' indicates cursor.
    NSString *const wordAfterCurrentLocation = [HKWMentionsStartDetectionStateMachine wordAfterLocation:currentLocation text:parentTextView.text];
    rangeToTransform = NSMakeRange(location, currentLocation + wordAfterCurrentLocation.length - location);

    /*
     When the textview text that matches the mention text is not the first part of the mention text,
     we must check the text preceding the current cursor location
     to see if it matches the first part of the mention text
     and change the range of text to be transformed accordingly
     e.g. mention text is "Bruce Wayne" & the matched part is "wayn"
     textview text is "... bruce wayn| ..."
     here the rangeToTransform will only replace "wayn"
     and the textview text will become "... bruce Bruce Wayne ..."
     The following code checks for & prevents this from happening
     */
    // Get the text from the textview that was matched for the mention & trim white spaces

    NSAssert(parentTextView.text, @"Text of parent textview should not be nil.");
    NSString *matchedText = [parentTextView.text substringWithRange:NSMakeRange(location, currentLocation - location)];
    matchedText = [matchedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    // If the matched text is the first part of the mention text, we don't need any further calculation
    // e.g. matched text is "bruc"
    BOOL hasPrefix = matchedText && [mentionText rangeOfString:matchedText options:NSCaseInsensitiveSearch | NSAnchoredSearch].location != NSNotFound;

    if (!hasPrefix) {
        // Add white space to the start of the mention & get range for the text in mention
        matchedText = [NSString stringWithFormat:@" %@", matchedText];
        NSRange matchedTextRange = [mentionText rangeOfString:matchedText options:NSCaseInsensitiveSearch];
        if (matchedTextRange.location != NSNotFound
            && matchedTextRange.location + 1 < mentionText.length) {
            // Get the first part of mention text (preceding the matched text)
            NSString *excessStringToReplace = [mentionText substringWithRange:NSMakeRange(0, matchedTextRange.location + 1)];
            NSUInteger excessLength = excessStringToReplace.length;
            if (location >= excessLength) {
                // Get similar length string from the text view preceding location
                NSString *stringFromTextView = [parentTextView.text substringWithRange:NSMakeRange(location - excessLength, excessLength)];
                // If the first part of mention text matches the string from textview preceding the cursor,
                // we adjust the range of text to transform to include the excess string as well
                if (stringFromTextView && [stringFromTextView caseInsensitiveCompare:excessStringToReplace] == NSOrderedSame) {
                    rangeToTransform = NSMakeRange(rangeToTransform.location - excessLength, rangeToTransform.length + excessLength);
                    location = rangeToTransform.location;
                }
            }
        }
    }

    [parentTextView transformTextAtRange:rangeToTransform
                         withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
                             NSMutableDictionary *attributes = [unselectedAttributes mutableCopy];
                             attributes[HKWMentionAttributeName] = mention;
                             // If the 'unselected attributes' dictionary doesn't contain information on the font
                             //  or text color, and the text view has a custom font or text color, use those.
                             if (!attributes[NSFontAttributeName] && parentFont) {
                                 attributes[NSFontAttributeName] = parentFont;
                             }
                             if (!attributes[NSForegroundColorAttributeName] && parentColor) {
                                 attributes[NSForegroundColorAttributeName] = parentColor;
                             }
                             return [[NSAttributedString alloc] initWithString:mentionText
                                                                    attributes:attributes];
                         }];
    // Remove the color formatting for subsequently typed characters.
    [parentTextView transformTypingAttributesWithTransformer:^NSDictionary *(NSDictionary *currentAttributes) {
        return [self typingAttributesByStrippingMentionAttributes:currentAttributes];
    }];
    // Move the cursor
    parentTextView.selectedRange = NSMakeRange(location + [mentionText length], 0);
    // Since the cursor is right after the mention, set the state to 'about to select'
    self.currentlySelectedMention = mention;
    self.currentlySelectedMentionRange = NSMakeRange(location, [mentionText length]);
    self.state = HKWMentionsStateAboutToSelectMention;
    // Toggle autocorrect. This is because we don't want the user to be able to alter the mention text using autocorrect
    //  (since the cursor will be located immediately after the location of the mention once it's created)
    [self toggleAutocorrectAsRequiredForRange:NSMakeRange(location, 0)];
    parentTextView.shouldRejectAutocorrectInsertions = NO;

    // Inform the delegate (if appropriate)
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPlugin:createdMention:atLocation:)]) {
        [strongStateChangeDelegate mentionsPlugin:self createdMention:mention atLocation:location];
    }
    // Invoke the parent text view's delegate if appropriate, since a mention was added and the text changed.
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    if (self.notifyTextViewDelegateOnMentionCreation && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [externalDelegate textViewDidChange:parentTextView];
    }
}

/// A private method that handles attaching the chooser view when it's enclosed within the text view.
- (void)attachEnclosedChooserView:(UIView *)accessoryView origin:(CGPoint)origin {
    // The chooser view is attached to the text view. Add constraints appropriately.
    UIEdgeInsets insets = self.chooserViewEdgeInsets;
    __weak typeof(self) __self = self;
    __strong __auto_type parentTextView = self.parentTextView;
    CGFloat gapHeight = [parentTextView rectForSingleLineViewportInMode:HKWViewportModeTop].size.height;
    parentTextView.onAccessoryViewAttachmentBlock = ^(__unused UIView *view, __unused BOOL isFreeFloating) {
        typeof(self) strongSelf = __self;
        if (!strongSelf) {
            return;
        }
        typeof(parentTextView) strongParentTextView = strongSelf.parentTextView;
        // Attach side constraints
        [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                   attribute:NSLayoutAttributeLeft
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:strongParentTextView
                                                                                   attribute:NSLayoutAttributeLeft
                                                                                  multiplier:1.0
                                                                                    constant:insets.left]];
        [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                   attribute:NSLayoutAttributeRight
                                                                                   relatedBy:NSLayoutRelationEqual
                                                                                      toItem:strongParentTextView
                                                                                   attribute:NSLayoutAttributeRight
                                                                                  multiplier:1.0
                                                                                    constant:-insets.right]];

        // Attach top/bottom constraints
        switch (strongSelf.chooserPositionMode) {
            case HKWMentionsChooserPositionModeEnclosedTop: {
                // Gap is at top
                [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                           attribute:NSLayoutAttributeTop
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:strongParentTextView
                                                                                           attribute:NSLayoutAttributeTop
                                                                                          multiplier:1.0
                                                                                            constant:gapHeight + insets.top]];
                [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:strongParentTextView
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                          multiplier:1.0
                                                                                            constant:-insets.bottom]];
                break;
            }
            case HKWMentionsChooserPositionModeEnclosedBottom: {
                // Gap is at bottom
                [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                           attribute:NSLayoutAttributeTop
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:strongParentTextView
                                                                                           attribute:NSLayoutAttributeTop
                                                                                          multiplier:1.0
                                                                                            constant:insets.top]];
                [strongParentTextView.superview addConstraint:[NSLayoutConstraint constraintWithItem:accessoryView
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                           relatedBy:NSLayoutRelationEqual
                                                                                              toItem:strongParentTextView
                                                                                           attribute:NSLayoutAttributeBottom
                                                                                          multiplier:1.0
                                                                                            constant:-gapHeight - insets.bottom]];
                break;
            }
            case HKWMentionsChooserPositionModeCustomLockBottomArrowPointingDown:
            case HKWMentionsChooserPositionModeCustomLockBottomArrowPointingUp:
            case HKWMentionsChooserPositionModeCustomLockBottomNoArrow:
            case HKWMentionsChooserPositionModeCustomLockTopArrowPointingDown:
            case HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp:
            case HKWMentionsChooserPositionModeCustomLockTopNoArrow:
            case HKWMentionsChooserPositionModeCustomNoLockArrowPointingDown:
            case HKWMentionsChooserPositionModeCustomNoLockArrowPointingUp:
            case HKWMentionsChooserPositionModeCustomNoLockNoArrow:
                NSAssert(NO, @"Internal error");
        }

    };
    [parentTextView attachSiblingAccessoryView:accessoryView position:origin];
}

- (void)attachViewToParentEditor:(UIView *)view origin:(CGPoint)origin mode:(HKWAccessoryViewMode)mode {
    switch (mode) {
        case HKWAccessoryViewModeFreeFloating: {
            // The chooser view is attached to the top level view. Add constraints appropriately.
            __strong __auto_type parentTextView = self.parentTextView;
            parentTextView.onAccessoryViewAttachmentBlock = ^(UIView *accessoryView, __unused BOOL ignored) {
                if (self.customModeAttachmentBlock) {
                    self.customModeAttachmentBlock(accessoryView);
                }
            };
            [parentTextView attachFreeFloatingAccessoryView:view absolutePosition:origin];
            break;
        }
        case HKWAccessoryViewModeSibling: {
            // The chooser view's position is slaved to the text view's positioning. Set up appropriately.
            [self attachEnclosedChooserView:view origin:origin];
            break;
        }
    }
}

- (void)accessoryViewStateWillChange:(BOOL)activated {
    if (activated) {
        // Tell state change delegate that the chooser view will open.
        __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
        if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPluginWillActivateChooserView:)]) {
            [strongStateChangeDelegate mentionsPluginWillActivateChooserView:self];
        }
    }
    else {
        if (self.viewportLocksUponMentionCreation) {
            [self.parentTextView exitSingleLineViewportMode];
        }
    }
}

- (void)accessoryViewActivated:(BOOL)activated {
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if (activated) {
        __strong __auto_type parentTextView = self.parentTextView;
        parentTextView.shouldRejectAutocorrectInsertions = YES;
        [parentTextView overrideAutocorrectionWith:UITextAutocorrectionTypeNo];
        if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPluginActivatedChooserView:)]) {
            [strongStateChangeDelegate mentionsPluginActivatedChooserView:self];
        }
        if (self.viewportLocksToTopUponMentionCreation) {
            [parentTextView enterSingleLineViewportMode:HKWViewportModeTop captureTouches:YES];
        }
        else if (self.viewportLocksToBottomUponMentionCreation) {
            [parentTextView enterSingleLineViewportMode:HKWViewportModeBottom captureTouches:YES];
        }
    }
    else {
        // Tell state change delegate that the chooser view has been closed.
        if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPluginDeactivatedChooserView:)]) {
            [strongStateChangeDelegate mentionsPluginDeactivatedChooserView:self];
        }
    }
}

- (CGFloat)heightForSingleLineViewport {
    HKWViewportMode mode;
    if (self.viewportLocksToBottomUponMentionCreation) {
        mode = HKWViewportModeBottom;
    }
    else {
        mode = HKWViewportModeTop;
    }
    return [self.parentTextView rectForSingleLineViewportInMode:mode].size.height;
}

- (CGFloat)positionForChooserCursorRelativeToView:(UIView *)view atLocation:(NSUInteger)location {
    __strong __auto_type parentTextView = self.parentTextView;
    UITextView *textView = parentTextView;
    UITextPosition *const position = [textView positionFromPosition:textView.beginningOfDocument offset:(NSInteger)location];
    if (!position) {
        NSAssert(NO, @"Internal error");
        return 0;
    }
    CGRect rect = [textView caretRectForPosition:position];
    CGPoint correctedPoint = [view convertPoint:rect.origin fromView:parentTextView];
    return correctedPoint.x + rect.size.width/2;
}

#pragma mark - Properties

- (void)setState:(HKWMentionsState)state {
    if (state == _state) {
        return;
    }
    HKW_STATE_LOG(@"STATE TRANSITION: %@ --> %@", nameForMentionsState(_state), nameForMentionsState(state));

    // Inform the delegate, if one exists
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPlugin:stateChangedTo:from:)]) {
        if (state == HKWMentionsStartDetectionStateCreatingMention && _state != HKWMentionsStartDetectionStateCreatingMention) {
            [strongStateChangeDelegate mentionsPlugin:self
                                       stateChangedTo:HKWMentionsPluginStateCreatingMention
                                                 from:HKWMentionsPluginStateQuiescent];
        }
        else if (state != HKWMentionsStartDetectionStateCreatingMention && _state == HKWMentionsStartDetectionStateCreatingMention) {
            [strongStateChangeDelegate mentionsPlugin:self
                                       stateChangedTo:HKWMentionsPluginStateQuiescent
                                                 from:HKWMentionsPluginStateCreatingMention];
        }
    }

    _state = state;
}

- (void)setCurrentlySelectedMentionRange:(NSRange)currentlySelectedMentionRange {
    _currentlySelectedMentionRange = currentlySelectedMentionRange;
}

- (BOOL)loadingCellSupported {
    __strong __auto_type delegate = self.defaultChooserViewDelegate;
    return ([delegate respondsToSelector:@selector(loadingCellForTableView:)]
            && [delegate respondsToSelector:@selector(heightForLoadingCellInTableView:)]);
}

- (UIView<HKWChooserViewProtocol> *)chooserView {
    return [self.creationStateMachine getEntityChooserView];
}

- (HKWMentionsStartDetectionStateMachine *)startDetectionStateMachine {
    if (!_startDetectionStateMachine) {
        _startDetectionStateMachine = [HKWMentionsStartDetectionStateMachine stateMachineWithDelegate:self];
    }
    return _startDetectionStateMachine;
}

- (HKWMentionsCreationStateMachine *)creationStateMachine {
    if (!_creationStateMachine) {
        _creationStateMachine = [HKWMentionsCreationStateMachine stateMachineWithDelegate:self isUsingCustomChooserView:(self.customChooserViewDelegate != nil && HKWTextView.directlyUpdateQueryWithCustomDelegate)];
    }
    return _creationStateMachine;
}

- (NSString *)pluginName {
    return @"Mentions Creation";
}

- (BOOL)viewportLocksToTopUponMentionCreation {
    return (self.chooserPositionMode == HKWMentionsChooserPositionModeEnclosedTop
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockTopArrowPointingDown
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockTopNoArrow);
}

- (BOOL)viewportLocksToBottomUponMentionCreation {
    return (self.chooserPositionMode == HKWMentionsChooserPositionModeEnclosedBottom
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockBottomArrowPointingUp
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockBottomArrowPointingDown
            || self.chooserPositionMode == HKWMentionsChooserPositionModeCustomLockBottomNoArrow);
}

- (BOOL)viewportLocksUponMentionCreation {
    return self.viewportLocksToTopUponMentionCreation || self.viewportLocksToBottomUponMentionCreation;
}

// Pass-through properties

- (UIColor *)chooserViewBackgroundColor {
    return self.creationStateMachine.chooserViewBackgroundColor;
}

- (void)setChooserViewBackgroundColor:(UIColor *)chooserViewBackgroundColor {
    self.creationStateMachine.chooserViewBackgroundColor = chooserViewBackgroundColor;
}

- (UIEdgeInsets)chooserViewEdgeInsets {
    return self.creationStateMachine.chooserViewEdgeInsets;
}

- (void)setChooserViewEdgeInsets:(UIEdgeInsets)chooserViewEdgeInsets {
    self.creationStateMachine.chooserViewEdgeInsets = chooserViewEdgeInsets;
}

- (Class<HKWChooserViewProtocol>)chooserViewClass {
    return self.creationStateMachine.chooserViewClass;
}

- (void)setChooserViewClass:(Class<HKWChooserViewProtocol>)chooserViewClass {
    self.creationStateMachine.chooserViewClass = chooserViewClass;
}

/*!
 Shows chooser view.
 Needs to be public for integration between Hakawai and HotPot.
 */
- (void)showChooserView {
    [self.creationStateMachine showChooserView];
}

/*!
 Handles the selection from the user. This is only needed for consumers who use custom chooser view.
 */
- (void)handleSelectionForEntity:(id<HKWMentionsEntityProtocol>)entity {
    [self.creationStateMachine handleSelectionForEntity:entity
                                              indexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
}

/*!
 Gets the input made by the user for both @ mentions or # hashtag.
 Needs to be public for integration between Hakawai and HotPot.
 */
- (unichar)getExplicitSearchControlCharacter {
    return self.creationStateMachine.explicitSearchControlCharacter;
}

- (void)textView:(__unused UITextView *)textView willCustomPasteTextInRange:(__unused NSRange)range {
    return;
}

- (void)didUpdateKeyString:(nonnull NSString *)keyString
          controlCharacter:(unichar)character {
    // set up the chooser view prior to data request in order to support fully customized view
    [self.creationStateMachine setupChooserViewIfNeeded];
    __strong __auto_type strongCustomChooserViewDelegate = self.customChooserViewDelegate;
    NSAssert(strongCustomChooserViewDelegate != nil, @"Must have a custom chooser view if the query is being updated directly via this method");
    [strongCustomChooserViewDelegate didUpdateKeyString:keyString
                                       controlCharacter:character];
}

#pragma mark - Developer

NSString * _Nonnull nameForMentionsState(HKWMentionsState s) {
    switch (s) {
        case HKWMentionsStateQuiescent:
            return @"Quiescent";
        case HKWMentionsStartDetectionStateCreatingMention:
            return @"CreatingMention";
        case HKWMentionsStateAboutToSelectMention:
            return @"AboutToSelectMention";
        case HKWMentionsStateSelectedMention:
            return @"SelectedMention";
        case HKWMentionsStateLosingFocus:
            return @"LosingFocus";
    }
}

@synthesize controlCharacterSet;

@synthesize defaultChooserViewDelegate;

@synthesize customChooserViewDelegate;

@synthesize implicitMentionsEnabled;

@synthesize implicitSearchLength;

@synthesize notifyTextViewDelegateOnMentionCreation;

@synthesize notifyTextViewDelegateOnMentionDeletion;

@synthesize notifyTextViewDelegateOnMentionTrim;

@synthesize resumeMentionsCreationEnabled;

@synthesize shouldContinueSearchingAfterEmptyResults;

@synthesize shouldEnableUndoUponUnregistration;

@synthesize stateChangeDelegate;

@end
