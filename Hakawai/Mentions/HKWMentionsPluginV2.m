//
//  HKWMentionsPluginV2.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWMentionsPluginV2.h"

#import "HKWCustomAttributes.h"
#import "HKWRoundedRectBackgroundAttributeValue.h"

#import "HKWTextView.h"
#import "HKWTextView+TextTransformation.h"
#import "HKWTextView+Extras.h"
#import "HKWTextView+Plugins.h"

#import "HKWMentionsAttribute.h"

#import "_HKWMentionsCreationStateMachine.h"
#import "_HKWMentionsCreationStateMachine.h"

#import "_HKWMentionsPrivateConstants.h"

@interface HKWMentionsPluginV2 () <HKWMentionsCreationStateMachineDelegate>

@property (nonatomic, strong) HKWMentionsCreationStateMachine *creationStateMachine;

@property (nonatomic, strong) NSDictionary *mentionHighlightedAttributes;
@property (nonatomic, strong) NSDictionary *mentionUnhighlightedAttributes;

@property (nonatomic, strong, nullable) NSCharacterSet *controlCharactersToPrepend;

@property (nonatomic, readwrite) HKWMentionsChooserPositionMode chooserPositionMode;

@property (nonatomic, readonly) BOOL viewportLocksToTopUponMentionCreation;
@property (nonatomic, readonly) BOOL viewportLocksToBottomUponMentionCreation;
@property (nonatomic, readonly) BOOL viewportLocksUponMentionCreation;

@property (nonatomic, copy) void(^customModeAttachmentBlock)(UIView *);

/**
 The range of the currently highlighted mention, if it exists.
 */
@property (nonatomic) NSRange currentlyHighlightedMentionRange;

@end

@implementation HKWMentionsPluginV2

static int MAX_MENTION_QUERY_LENGTH = 100;

@synthesize parentTextView = _parentTextView;

@synthesize dictationString;

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode {
    static const NSInteger defaultSearchLength = 3;
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:nil
                                  searchLength:defaultSearchLength];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *_Null_unspecified)controlCharacterSet
                   controlCharactersToPrepend:(NSCharacterSet *_Null_unspecified)controlCharactersToPrepend
                                 searchLength:(NSInteger)searchLength {
    HKWMentionsPluginV2 *mentionsPlugin = [self mentionsPluginWithChooserMode:mode controlCharacters:controlCharacterSet searchLength:searchLength];
    mentionsPlugin.controlCharactersToPrepend = controlCharactersToPrepend;
    return mentionsPlugin;
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength {
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:controlCharacterSet
                                  searchLength:searchLength
                            unhighlightedColor:[UIColor blueColor]
                              highlightedColor:[UIColor whiteColor]
                    highlightedBackgroundColor:[UIColor blackColor]];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                           unhighlightedColor:(UIColor *)unhighlightedColor
                             highlightedColor:(UIColor *)highlightedColor
                   highlightedBackgroundColor:(UIColor *)highlightedBackgroundColor {
    NSDictionary *unhighlightedAttributes = @{NSForegroundColorAttributeName: unhighlightedColor ?: [UIColor blueColor]};
    NSDictionary *highlightedAttributes = @{NSForegroundColorAttributeName: highlightedColor ?: [UIColor whiteColor],
                                            HKWRoundedRectBackgroundAttributeName: [HKWRoundedRectBackgroundAttributeValue valueWithBackgroundColor:highlightedBackgroundColor ?: [UIColor blueColor]]};
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:controlCharacterSet
                                  searchLength:searchLength
                unhighlightedMentionAttributes:unhighlightedAttributes
                  highlightedMentionAttributes:highlightedAttributes];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
               unhighlightedMentionAttributes:(NSDictionary *)unhighlightedAttributes
                 highlightedMentionAttributes:(NSDictionary *)highlightedAttributes {
    return [self mentionsPluginWithChooserMode:mode
                             controlCharacters:controlCharacterSet
                    controlCharactersToPrepend:nil
                                  searchLength:searchLength
                unhighlightedMentionAttributes:unhighlightedAttributes
                  highlightedMentionAttributes:highlightedAttributes];
}

+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *_Null_unspecified)controlCharacterSet
                   controlCharactersToPrepend:(NSCharacterSet *_Null_unspecified)controlCharactersToPrepend
                                 searchLength:(NSInteger)searchLength
               unhighlightedMentionAttributes:(NSDictionary *_Null_unspecified)unhighlightedAttributes
                 highlightedMentionAttributes:(NSDictionary *_Null_unspecified)highlightedAttributes {
    // Make sure iOS version is 7.1 or greater
    if (!HKW_systemVersionIsAtLeast(@"7.1")) {
        NSAssert(NO, @"Mentions plug-in is only supported for iOS 7.1 or later.");
    }

    HKWMentionsPluginV2 *plugin = [[[self class] alloc] init];
    plugin.chooserPositionMode = mode;
    plugin.controlCharacterSet = controlCharacterSet;
    plugin.controlCharactersToPrepend = controlCharactersToPrepend;
    plugin.implicitSearchLength = searchLength;

    // Validate attribute dictionaries
    // (unhighlighted mention attributes)
    NSMutableSet *badAttributes = [NSMutableSet set];
    for (id attribute in unhighlightedAttributes) {
        if (![attribute isKindOfClass:[NSString class]]
            || [attribute isEqualToString:HKWMentionAttributeName]) {
            [badAttributes addObject:attribute];
        }
    }
    NSMutableDictionary *buffer = [unhighlightedAttributes copy] ?: [NSMutableDictionary dictionary];
    for (id badAttribute in badAttributes) {
        [buffer removeObjectForKey:badAttribute];
    }
    plugin.mentionUnhighlightedAttributes = [buffer copy];

    // (highlighted mention attributes)
    [badAttributes removeAllObjects];
    for (id attribute in highlightedAttributes) {
        if (![attribute isKindOfClass:[NSString class]]
            || [attribute isEqualToString:HKWMentionAttributeName]) {
            [badAttributes addObject:attribute];
        }
    }
    buffer = [highlightedAttributes copy] ?: [NSMutableDictionary dictionary];
    for (id badAttribute in badAttributes) {
        [buffer removeObjectForKey:badAttribute];
    }
    plugin.mentionHighlightedAttributes = [buffer copy];

    return plugin;
}

- (instancetype)init {
    self = [super init];
    if (!self) { return nil; }

    self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
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
    [self.creationStateMachine cancelMentionCreation];

    NSUInteger location = parentTextView.selectedRange.location;
    NSRange originalRange = NSMakeRange(location, 0);
    NSDictionary *mentionAttributes = self.mentionUnhighlightedAttributes;
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
    [self stripCustomAttributesFromTypingAttributes];
}

// Programmatically add a number of mentions to the text view's text.
- (void)addMentions:(NSArray *)mentions {
    for (id object in mentions) {
        if ([object isKindOfClass:[HKWMentionsAttribute class]]) {
            [self addMention:(HKWMentionsAttribute *)object];
        }
    }
}

- (void)performInitialSetup {
    __strong __auto_type parentTextView = self.parentTextView;
    NSAssert(parentTextView != nil, @"Internal error: parent text view is nil; it should have been set already");
    // Disable spell checking since we do not want it under mentions text, and there's no way to have it under normal text and not have it under mention text
    [parentTextView overrideSpellCheckingWith:UITextSpellCheckingTypeNo];
}

// Delegate method called when the plug-in is unregistered from a text view. Cleans up the state of the text view.
- (void)performFinalCleanup {
    // Cancel mentions creation, if it's happening
    [self.creationStateMachine cancelMentionCreation];

    // Remove the accessory view from the parent text view's view hierarchy
    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView detachAccessoryView:self.chooserView];
    [self.creationStateMachine resetChooserView];

    // Restore the parent text view's spell checking
    [parentTextView restoreOriginalSpellChecking:NO];
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

+ (nullable NSString *)wordAfterLocation:(NSUInteger)location text:(nonnull NSString *)text {
    NSMutableString *const word = [[NSMutableString alloc] init];
    for(NSUInteger i = location; i < text.length ; i++) {
        const unichar character = [text characterAtIndex:i];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character]) {
            break;
        }
        [word appendString:[NSString stringWithCharacters:&character length:1]];
    }
    if (word.length == 0) {
        return nil;
    }
    return [word copy];
}

#pragma mark - UI

- (void)singleLineViewportChanged {
    [self.creationStateMachine hideChooserArrow];
}

- (void)singleLineViewportTapped {
    // If user taps on the text view, cancel mentions creation.
    [self.creationStateMachine cancelMentionCreation];
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

- (NSDictionary *)defaultTextAttributes {
    __strong __auto_type parentTextView = self.parentTextView;
    NSMutableDictionary *returnDict = [[NSMutableDictionary alloc] init];
    UIFont *parentFont = parentTextView.fontSetByApp;
    UIColor *parentColor = parentTextView.textColorSetByApp;
    if (parentFont) {
        returnDict[NSFontAttributeName] = parentFont;
    }
    if (parentColor) {
        returnDict[NSForegroundColorAttributeName] = parentColor;
    }
    return returnDict;
}
/*!
 Build a new typing attributes dictionary by stripping mentions-specific attributes from an original attributes
 dictionary and, if applicable, restoring default attributes from the parent text view.
 */
- (NSDictionary *)typingAttributesByStrippingMentionAttributes:(NSDictionary *)originalAttributes {
    NSMutableDictionary *d = [originalAttributes mutableCopy];
    for (NSString *key in self.mentionUnhighlightedAttributes) {
        [d removeObjectForKey:key];
    }
    // Restore the default typing attributes, if the app set either explicitly at any point.
    [d addEntriesFromDictionary:self.defaultTextAttributes];
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
 Toggle mentions-related formatting for a given portion of text. Mentions can either be 'highlighted' (annotation
 background, light text color), or 'unhighlighted' (no background, dark text color)
 */
- (void)toggleMentionsFormattingIfNeededAtRange:(NSRange)range
                                    highlighted:(BOOL)highlighted {
    if (range.location == NSNotFound || range.length == 0) {
        return;
    }
    __strong __auto_type parentTextView = self.parentTextView;
    // Save cursor selection range before toggling, so we can restore it afterwards, because transformTextAtRange reset it
    NSRange previousSelectedRange = parentTextView.selectedRange;
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

    NSDictionary *unhighlightedAttributes = self.mentionUnhighlightedAttributes;
    NSDictionary *highlightedAttributes = self.mentionHighlightedAttributes;
    // Save the range so the cursor doesn't move.
    [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        NSDictionary *attributesToRemove = (highlighted ? unhighlightedAttributes : highlightedAttributes);
        NSDictionary *attributesToAdd = (highlighted ? highlightedAttributes : unhighlightedAttributes);
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
    if (!highlighted) {
        [self stripCustomAttributesFromTypingAttributes];
    }
    // Restore previously selected cursor range
    parentTextView.selectedRange = previousSelectedRange;
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
    // Save cursor selection range before bleaching, so we can restore it afterwards, because transformTextAtRange reset it
    NSRange previousSelectedRange = parentTextView.selectedRange;
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
    for (NSValue *v in ranges) {
        [self stripMentionAttributesAtRange:[v rangeValue]];
    }
    // Restore previously selected cursor range
    parentTextView.selectedRange = previousSelectedRange;
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
    // Save cursor selection range before bleaching, so we can restore it afterwards, because transformTextAtRange reset it
    NSRange previousSelectedRange = parentTextView.selectedRange;
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
    [self stripMentionAttributesAtRange:range];
    // Restore previously selected cursor range
    parentTextView.selectedRange = previousSelectedRange;
}

- (void)stripMentionAttributesAtRange:(NSRange)range {
    __strong __auto_type parentTextView = self.parentTextView;
    NSDictionary *unhighlightedAttributes = self.mentionUnhighlightedAttributes;
    NSDictionary *highlightedAttributes = self.mentionHighlightedAttributes;
    [parentTextView transformTextAtRange:range withTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        [buffer removeAttribute:HKWMentionAttributeName range:HKW_FULL_RANGE(input)];
        // NOTE: We may need to add support for capturing and restoring any attributes overwritten by applying the
        //  special mentions attributes in the future.
        for (NSString *key in highlightedAttributes) {
            [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
        }
        for (NSString *key in unhighlightedAttributes) {
            [buffer removeAttribute:key range:HKW_FULL_RANGE(input)];
        }
        // Restore default attributes to text
        for (NSString *key in self.defaultTextAttributes) {
            __strong id attributeValue = self.defaultTextAttributes[key];
            [buffer addAttribute:key value:attributeValue range:HKW_FULL_RANGE(input)];
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
    __strong __auto_type strongDefaultChooserViewDelegate = self.defaultChooserViewDelegate;
    __strong __auto_type strongCustomChooserViewDelegate = self.customChooserViewDelegate;
    BOOL delegateImplementsCustomTrimming = [strongDefaultChooserViewDelegate respondsToSelector:@selector(trimmedNameForEntity:)];
    BOOL delegateAllowsTrimming = NO;
    if ([strongCustomChooserViewDelegate respondsToSelector:@selector(entityCanBeTrimmed:)]) {
        delegateAllowsTrimming = [strongCustomChooserViewDelegate entityCanBeTrimmed:mention];
    } else if ([strongDefaultChooserViewDelegate respondsToSelector:@selector(entityCanBeTrimmed:)]) {
        delegateAllowsTrimming = [strongDefaultChooserViewDelegate entityCanBeTrimmed:mention];
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
                          ? [strongDefaultChooserViewDelegate trimmedNameForEntity:mention]
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
    if (location == [parentTextView.attributedText length]) {
        return nil;
    } else if (location > [parentTextView.attributedText length]) {
        NSAssert(NO, @"Can't have a location beyond bounds of parent view");
        return nil;
    }
    NSAttributedString *parentText = parentTextView.attributedText;
    id value = [parentText attribute:HKWMentionAttributeName
                             atIndex:location
               longestEffectiveRange:range
                             inRange:HKW_FULL_RANGE(parentText)];
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

// TODO: Make all utils static
// JIRA: POST-13757
#pragma mark - Mention Query Utils

/**
 Find the mentionas query connected to the given location

 @param text the text to search within
 @param location the cursor location from which to search for a mention
 @return The mention query connected to the cursor at @c location
 */
- (NSString *)mentionsQueryInText:(NSString *)text location:(NSUInteger)location {
    if (text.length <= 0) {
        return nil;
    }
    // Search starting from the given location, and return first control character
    NSUInteger mostRecentValidControlCharacterLocation = [self mostRecentValidControlCharacterLocation:text beforeLocation:location];
    if (mostRecentValidControlCharacterLocation != NSNotFound) {
        // Query until end of word in which cursor is present (or until cursor if it is at end of word)
        NSUInteger endOfValidWordAfterLocation = [self endOfValidWordInText:text afterLocation:location];
        if (endOfValidWordAfterLocation != NSNotFound) {
            NSString *substringUntilEndOfWord = [text substringToIndex:endOfValidWordAfterLocation];
            // Return the string, including the control char as the query
            return [substringUntilEndOfWord substringFromIndex:mostRecentValidControlCharacterLocation];
        }
    }
    return nil;
}

/**
 Find the location for the end of the next word, starting at the given location.

 If we ever encounter a mention character, this word is invalid, and we return @c NSNotFound

 @param location location to begin search from
 @param text text to search
 @return location of end of next word, start at @c location
 */
- (NSUInteger)endOfValidWordInText:(nonnull NSString *)text afterLocation:(NSUInteger)location {
    NSUInteger i;
    for(i = location; i < text.length ; i++) {
        // If there is a mentions character before there is a whitespace, then this is not a valid word for querying
        HKWMentionsAttribute *mentionAttribute = [self mentionAttributeAtLocation:i range:nil];
        if (mentionAttribute) {
            return NSNotFound;
        }
        const unichar character = [text characterAtIndex:i];
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:character]) {
            return i;
        }
    }
    return i;
}

/**
 Search backwards in a string for a character in the control character set

 @param text The text in which to perform a backwards search for a control character
 @returns Location for most recent control character in a string
 */
- (NSUInteger)mostRecentControlCharacterLocationInText:(NSString *)text {
    if (text.length == 0) {
        return NSNotFound;
    }
    int endOfTextIndex = (int)text.length - 1;
    for (int index = endOfTextIndex; index >= 0; index--) {
        NSUInteger unsignedIndex = (unsigned long)index;
        unichar character = [text characterAtIndex:unsignedIndex];
        if ([self.controlCharacterSet characterIsMember:character]) {
            // If the most recent control character has mention attribute, return NSNotFound
            if (HKWTextView.enableControlCharactersToPrepend
                && [self.controlCharactersToPrepend characterIsMember:character]
                && [self mentionAttributeAtLocation:unsignedIndex range:nil]) {
                return NSNotFound;
            }
            return unsignedIndex;
        }
    }
    return NSNotFound;
}

/**
 Returns the location for the most recently valid control character before the cursor. Valid includes: not having an alphanumeric before it, not having an existing entity between the character and the cursor, etc.

 @param text the text to search for the control character within
 @param location the location to start your backwards search for a control character
 @returns The location, if any, for the control character
 */
- (NSUInteger)mostRecentValidControlCharacterLocation:(NSString *)text beforeLocation:(NSUInteger)location {
    NSString *substringUntilLocation = [text substringToIndex:location];
    // Search back MAX_MENTION_QUERY_LENGTH for a control character
    NSUInteger maximumSearchIndex = (NSUInteger)MAX((int)location-MAX_MENTION_QUERY_LENGTH, 0);
    NSString *substringToSearchForControlChar = [substringUntilLocation substringFromIndex:maximumSearchIndex];
    // Find control character location
    NSUInteger controlCharLocation = [self mostRecentControlCharacterLocationInText:substringToSearchForControlChar];
    if (controlCharLocation != NSNotFound) {
        // If it exists, offset it by the search index to get actual location in the parent text view
        controlCharLocation = controlCharLocation + maximumSearchIndex;
    }

    // If there's a non-mentions alphanumeric before the control char, then it's invalid
    unichar charPrecidingControlChar = [self.parentTextView characterPrecedingLocation:(NSInteger)controlCharLocation];
    if (charPrecidingControlChar
        && [[NSCharacterSet alphanumericCharacterSet] characterIsMember:charPrecidingControlChar]
        && ![self mentionAttributeAtLocation:controlCharLocation-1
                                       range:nil]) {
        return NSNotFound;
    }

    // If there's an entity in between the current location and the previous control character, then it's invalid
    NSRange mentionRange;
    HKWMentionsAttribute __unused *mention = [self mentionAttributePrecedingLocation:location
                                                                               range:&mentionRange];
    if (mention && (mentionRange.location + mentionRange.length >= controlCharLocation)) {
        return NSNotFound;
    }

    return controlCharLocation;
}

#pragma mark - Deletion

/**
 Return whether or not to allow text view to process the deletion.

 If it is a mention, do not allow the text view to process the deletion, and handle the deletion ourselves, either personalizing or removing it

 @param location current location of cursor
 @return whether or not to allow the text view to process the deletion
 */
- (BOOL)shouldAllowCharacterDeletionAtLocation:(NSUInteger)location {
    __strong __auto_type parentTextView = self.parentTextView;
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    NSRange mentionRange;
    HKWMentionsAttribute *mentionAtDeleteLocation = [self mentionAttributeAtLocation:location
                                                                               range:&mentionRange];
    // If the deleted character was not part of a mention, just allow the text view to handle it
    if (!mentionAtDeleteLocation) {
        return YES;
    }

    // Otherwise trim or delete the mention
    NSString *trimmedString = nil;
    BOOL canTrim = [self mentionCanBeTrimmed:mentionAtDeleteLocation trimmedString:&trimmedString];
    if (canTrim) {
        // Trim mention to first word only
        NSAssert([trimmedString length] > 0,
                 @"Cannot trim a mention to zero length");
        mentionAtDeleteLocation.mentionText = trimmedString;
        [parentTextView transformTextAtRange:mentionRange
                             withTransformer:^NSAttributedString *(NSAttributedString *input) {
            return [input attributedSubstringFromRange:NSMakeRange(0, [trimmedString length])];
        }];
        // Move the cursor into position.
        parentTextView.selectedRange = NSMakeRange(mentionRange.location + [trimmedString length],
                                                   0);
        // Notify the parent text view's external delegate that the text changed, since a mention was trimmed.
        if (self.notifyTextViewDelegateOnMentionTrim
            && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
            [externalDelegate textViewDidChange:parentTextView];
        }
    } else {
        // Delete mention entirely
        NSUInteger locationAfterDeletion = mentionRange.location;
        [parentTextView transformTextAtRange:mentionRange
                             withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
            return (NSAttributedString *)nil;
        }];
        [self stripCustomAttributesFromTypingAttributes];
        parentTextView.selectedRange = NSMakeRange(locationAfterDeletion, 0);

        // Notify the parent text view's external delegate that the text changed, since a mention was deleted.
        if (self.notifyTextViewDelegateOnMentionDeletion
            && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
            [externalDelegate textViewDidChange:parentTextView];
        }
    }
    return NO;
}

/**
 Return whether or not to allow text view to process a multi-character deletion.

 Handle deletion manually only when the selection range's start or end location intersects with a mention. i.e:

 | NonMentionWord FirstName Last|Name
 FirstNa|me lastName NonMentionWord|
 FirstName1 LastN|ame1 NonMentionWord FirstNa|me2 LastName2

 When the selection range doesn't intersect with a mention, or there is a mention but it is contained fully within the range, we directly let text view handle it as a simple deletion.

 @param range Range of multicharacter deletion
 @return whether or not to allow the text view to process the deletion
 */
- (BOOL)shouldAllowDeletionAtRange:(NSRange)range {
    __strong __auto_type parentTextView = self.parentTextView;
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    NSRange mentionRangeAtStartOfRange;
    HKWMentionsAttribute *mentionAtStartOfRange = [self mentionAttributeAtLocation:range.location
                                                                             range:&mentionRangeAtStartOfRange];

    NSRange mentionRangeAtEndOfRange;
    HKWMentionsAttribute *mentionAtEndOfRange = [self mentionAttributePrecedingLocation:range.location+range.length
                                                                                  range:&mentionRangeAtEndOfRange];

    // no special handling needed if the cursor is at the beginning of the mention,
    BOOL doesStartOfRangeIntersectWithMention = mentionAtStartOfRange && mentionRangeAtStartOfRange.location != range.location;
    // no special handling needed if the range extends fully to the end of the mention
    BOOL doesEndOfRangeIntersectWithMention = mentionAtEndOfRange
    && mentionRangeAtEndOfRange.location + mentionRangeAtEndOfRange.length != range.location + range.length;

    // If there is no mention intersecting the start or the end of the range, allow the text view to handle it
    if (!doesStartOfRangeIntersectWithMention && !doesEndOfRangeIntersectWithMention) {
        return YES;
    }

    NSRange deletionRange = range;
    NSString *trimmedMentionAtStartOfRange = nil;
    if (doesStartOfRangeIntersectWithMention) {
        // If start of range intersects with a mention, expand the deletion range to encompass that mention
        deletionRange = NSMakeRange(mentionRangeAtStartOfRange.location, range.location-mentionRangeAtStartOfRange.location+range.length);
        [self mentionCanBeTrimmed:mentionAtStartOfRange trimmedString:&trimmedMentionAtStartOfRange];
    }
    NSString *trimmedMentionAtEndOfRange = nil;
    if (doesEndOfRangeIntersectWithMention) {
        // If end of range intersects with a mention, expand the deletion range to encompass that mention
        deletionRange = NSMakeRange(deletionRange.location, mentionRangeAtEndOfRange.location-deletionRange.location + mentionRangeAtEndOfRange.length);
        [self mentionCanBeTrimmed:mentionAtEndOfRange trimmedString:&trimmedMentionAtEndOfRange];
    }

    [parentTextView transformTextAtRange:deletionRange
                         withTransformer:^NSAttributedString *(NSAttributedString *input) {
        NSMutableAttributedString *returnString = nil;
        if (trimmedMentionAtStartOfRange) {
            mentionAtStartOfRange.mentionText = trimmedMentionAtStartOfRange;
            // If there's a trimmed mention at the start of a range, maintain it through the deletion
            returnString = [[input attributedSubstringFromRange:NSMakeRange(0, [trimmedMentionAtStartOfRange length])] mutableCopy];
        }

        if (mentionAtStartOfRange != mentionAtEndOfRange) {
            if (trimmedMentionAtEndOfRange) {
                // If there's a trimmed mention at the end of a range, maintain it through the deletion
                mentionAtEndOfRange.mentionText = trimmedMentionAtEndOfRange;
                NSAttributedString *attributedTrimmedMentionAtEndOfRange = [parentTextView.attributedText attributedSubstringFromRange:NSMakeRange(mentionRangeAtEndOfRange.location, trimmedMentionAtEndOfRange.length)];
                if (returnString) {
                    [returnString appendAttributedString:attributedTrimmedMentionAtEndOfRange];
                } else {
                    returnString = [attributedTrimmedMentionAtEndOfRange mutableCopy];
                }
            }
        }
        return returnString;
    }];

    // Update the cursor to be at the beginning of the deletion range, or after the trimmed mention at the start if there was one
    parentTextView.selectedRange = NSMakeRange(deletionRange.location + [trimmedMentionAtStartOfRange length],
                                               0);

    [self stripCustomAttributesFromTypingAttributes];
    // Notify the parent text view's external delegate that the text changed, since a mention was trimmed.
    if (self.notifyTextViewDelegateOnMentionTrim
        && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [externalDelegate textViewDidChange:parentTextView];
    }
    return NO;
}

#pragma mark - Plug-in protocol

- (void)dataReturnedWithEmptyResults:(BOOL)isEmptyResults
         keystringEndsWithWhiteSpace:(BOOL)keystringEndsWithWhiteSpace {
    [self.creationStateMachine dataReturnedWithEmptyResults:isEmptyResults keystringEndsWithWhiteSpace:keystringEndsWithWhiteSpace];
}

- (void)highlightMentionIfNeededForCursorLocation:(NSUInteger)cursorLocation {
    __strong __auto_type parentTextView = self.parentTextView;
    const NSRange textFullRange = HKW_FULL_RANGE(parentTextView.attributedText);

    // If cursor falls out of attributed range, it cannot be in a mention
    if (!(NSLocationInRange(cursorLocation, textFullRange))) {
        [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
        self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
        return;
    }

    NSRange range;
    id attribute = [parentTextView.attributedText attribute:HKWMentionAttributeName
                                                    atIndex:cursorLocation
                                      longestEffectiveRange:&range
                                                    inRange:HKW_FULL_RANGE(parentTextView.attributedText)];;

    // If there is a mention at the given location, highlight it
    // - unless the cursor is right at the beginning of the mention. We only want to highlight if the cursor is within it
    if ([attribute isKindOfClass:[HKWMentionsAttribute class]] && range.location != cursorLocation) {
        // We don't need to update if we're already in the currently highlighted range
        if (!(NSEqualRanges(range, self.currentlyHighlightedMentionRange))) {
            [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
            [self toggleMentionsFormattingIfNeededAtRange:range highlighted:YES];
            self.currentlyHighlightedMentionRange = range;
        }
    } else {
        // If we are not in a mention, unhighlight the currently highlighted mention
        [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
        self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
    }
}

// TODO: Remove text view from call
// JIRA: POST-14031
- (BOOL)textView:(__unused UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    BOOL returnValue = YES;
    // In simple refactor, we only focus on insertions and deletions in order to allow for personalization/deletions/bleaching of mentions

    // Deletion
    if (text.length == 0) {
        // Single-char
        if (range.length == 1) {
            // Handle deletion of mentions characters
            [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
            self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
            returnValue = [self shouldAllowCharacterDeletionAtLocation:range.location];
        // Multi-char
        } else {
            // Handle when a multi-character deletion overlaps a mention
            returnValue = [self shouldAllowDeletionAtRange:range];
        }
    // Insertion
    } else {
        //  If a character is inserted within a mention then bleach the mention.
        if (range.length == 0 && self.currentlyHighlightedMentionRange.location != NSNotFound) {
            const NSRange highlightedMentionInternalTextRange = NSMakeRange(self.currentlyHighlightedMentionRange.location + 1,
                                                                            self.currentlyHighlightedMentionRange.length - 1);
            if (NSLocationInRange(range.location, highlightedMentionInternalTextRange)) {
                [self bleachExistingMentionAtRange:self.currentlyHighlightedMentionRange];
            }
            self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
        // If at least one character is inserted while the user is selecting a range
        } else if (range.length > 0) {
            // Remove any current highlightings
            [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
            self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);

            // Bleach a mention if the insertion intersects with it, either at the beginning or the end
            // This is also needed if a user autocorrects a mention name from the black pop up menu over a piece of text
            [self bleachMentionsIntersectingWithRange:range];
        }
    }
    [self stripCustomAttributesFromTypingAttributes];
    return returnValue;
}

- (void)bleachMentionsIntersectingWithRange:(NSRange)range {
    NSRange mentionRangeAtStartOfRange;
    HKWMentionsAttribute *mentionAtStartOfRange = [self mentionAttributeAtLocation:range.location range:&mentionRangeAtStartOfRange];
    BOOL doesStartOfRangeIntersectWithMention = mentionAtStartOfRange && mentionRangeAtStartOfRange.location != range.location;
    if (doesStartOfRangeIntersectWithMention) {
        [self bleachExistingMentionAtRange:mentionRangeAtStartOfRange];
    }

    NSRange mentionRangeAtEndOfRange;
    HKWMentionsAttribute *mentionAtEndOfRange = [self mentionAttributePrecedingLocation:range.location+range.length range:&mentionRangeAtEndOfRange];
    BOOL doesEndOfRangeIntersectWithMention = mentionAtEndOfRange
    && mentionRangeAtEndOfRange.location + mentionRangeAtEndOfRange.length != range.location + range.length;
    if (doesEndOfRangeIntersectWithMention) {
        [self bleachExistingMentionAtRange:mentionRangeAtEndOfRange];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    NSRange range = textView.selectedRange;
    if (range.length > 0) {
        // If there is a multicharacter range, we unhighlight any mentions currently highlighted
        [self toggleMentionsFormattingIfNeededAtRange:self.currentlyHighlightedMentionRange highlighted:NO];
        self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
        return;
    }

    NSUInteger cursorLocation = range.location;

    // Highlight mention if needed
    [self highlightMentionIfNeededForCursorLocation:cursorLocation];

    // If we are not currently long pressing, handle mentions creation. This to avoid querying for mentions when the selection change is due to a long press
    if (![self.parentTextView isCurrentlyLongPressing]) {
        [self handleMentionsCreationInText:textView.text atLocation:cursorLocation];
    }
}

- (void)handleMentionsCreationInText:(NSString *)text atLocation:(NSUInteger)location {
    // Find a mentions query from the last control char if there is one
    NSString *query = [self mentionsQueryInText:text location:location];
    if (query) {
        // first character is control character,rest of string is query
        [self fetchMentionWithPrefix:[query substringFromIndex:1]
                          atLocation:location
               usingControlCharacter:YES
                    controlCharacter:[query characterAtIndex:0]];
    } else {
        // if there isn't a query, cancel entity creation
        [self.creationStateMachine cancelMentionCreation];
    }
}

/**
 We have to update mentions formatting after a programmatic custom paste because we just manually inserted a string, and @c shouldChangeTextInRange is not going to be called
 */
- (void)textView:(__unused UITextView *)textView willCustomPasteTextInRange:(NSRange)range {
    // If it was a programmatic paste, we just have to update the mention formatting
    if (self.currentlyHighlightedMentionRange.location != NSNotFound) {
        [self bleachExistingMentionAtRange:self.currentlyHighlightedMentionRange];
        self.currentlyHighlightedMentionRange = NSMakeRange(NSNotFound, 0);
    } else {
        // If this paste is happening over a range that intersects with a mention, bleach that mention
        [self bleachMentionsIntersectingWithRange:range];
    }
}

- (void)textViewDidEndEditing:(__unused UITextView *)textView {
    [self.creationStateMachine cancelMentionCreation];
    if (self.viewportLocksUponMentionCreation) {
        [self.parentTextView exitSingleLineViewportMode];
    }
}

#pragma mark - Fetch Mentions

- (void)fetchMentionWithPrefix:(NSString *)prefix
                    atLocation:(NSUInteger)location
         usingControlCharacter:(BOOL)usingControlCharacter
              controlCharacter:(unichar)character {
    NSAssert(self.parentTextView.selectedRange.length == 0,
             @"Cannot start a mention unless the cursor is in insertion mode.");
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
    // Remove this after directlyUpdateQueryWithCustomDelegate is ramped, because async vs. didUpdate should be totally separate
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

- (void)didUpdateKeyString:(nonnull NSString *)keyString
          controlCharacter:(unichar)character {
    // set up the chooser view prior to data request in order to support fully customized view
    [self.creationStateMachine setupChooserViewIfNeeded];
    __strong __auto_type strongCustomChooserViewDelegate = self.customChooserViewDelegate;
    NSAssert(strongCustomChooserViewDelegate != nil, @"Must have a custom chooser view if the query is being updated directly via this method");
    [strongCustomChooserViewDelegate didUpdateKeyString:keyString
                                       controlCharacter:character];
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
    __strong __auto_type strongDefaultChooserViewDelegate = self.defaultChooserViewDelegate;
    NSAssert([strongDefaultChooserViewDelegate respondsToSelector:@selector(loadingCellForTableView:)],
             @"The delegate does not implement the loading cell functionality. This probably means the property wasn't checked properly.");
    return [strongDefaultChooserViewDelegate loadingCellForTableView:tableView];
}

- (CGFloat)heightForLoadingCellInTableView:(UITableView *)tableView {
    __strong __auto_type strongDefaultChooserViewDelegate = self.defaultChooserViewDelegate;
    NSAssert([strongDefaultChooserViewDelegate respondsToSelector:@selector(heightForLoadingCellInTableView:)],
             @"The delegate does not implement the loading cell functionality. This probably means the property wasn't checked properly.");
    return [strongDefaultChooserViewDelegate heightForLoadingCellInTableView:tableView];
}

/*!
 Perform shared cleanup once a mention is created or mentions creation is cancelled (as signaled by the mentions
 creation state machine).
 */
- (void)performMentionCreationEndCleanup {
    __strong __auto_type parentTextView = self.parentTextView;
    if (self.viewportLocksUponMentionCreation) {
        [parentTextView exitSingleLineViewportMode];
    }
}

- (void)cancelMentionFromStartingLocation:(__unused NSUInteger)location {
    __strong __auto_type parentTextView = self.parentTextView;
    parentTextView.shouldRejectAutocorrectInsertions = NO;
}

- (void)selected:(id<HKWMentionsEntityProtocol>)entity atIndexPath:(NSIndexPath *)indexPath {
    // Inform the delegate (if appropriate)
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if ([strongStateChangeDelegate respondsToSelector:@selector(selected:atIndexPath:)]) {
        [strongStateChangeDelegate selected:entity atIndexPath:indexPath];
    }
}

- (void)createMention:(HKWMentionsAttribute *)mention cursorLocation:(NSUInteger)cursorLocation {
    if (!mention) {
        return;
    }
    [self performMentionCreationEndCleanup];

    // Actually create the mention
    __strong __auto_type parentTextView = self.parentTextView;
    NSAssert(parentTextView.selectedRange.length == 0,
             @"Cannot create a mention unless cursor is in insertion mode.");
    UIFont *parentFont = parentTextView.fontSetByApp;
    UIColor *parentColor = parentTextView.textColorSetByApp;
    NSAssert(self.mentionHighlightedAttributes != nil, @"Error! Mention attribute dictionaries should never be nil.");
    NSDictionary *unhighlightedAttributes = self.mentionUnhighlightedAttributes;

    NSRange rangeToTransform;
    // Find where previous control character was, and replace mention at that point
    NSString *substringUntilCursor = [parentTextView.text substringToIndex:cursorLocation];
    NSUInteger controlCharLocation = [self mostRecentControlCharacterLocationInText:substringUntilCursor];
    // Prepend control character to mentionText if needed
    if (HKWTextView.enableControlCharactersToPrepend && controlCharLocation != NSNotFound) {
        unichar controlCharacter = [parentTextView.text characterAtIndex:controlCharLocation];
        BOOL shouldPrependControlCharacter = [self.controlCharactersToPrepend characterIsMember:controlCharacter];
        if (shouldPrependControlCharacter) {
            // Use %C instead of %c for unichar
            mention.mentionText = [NSString stringWithFormat:@"%C%@", controlCharacter, mention.mentionText];
        }
    }
    NSString *mentionText = mention.mentionText;
    // Replace until the end of the word at the current cursor location
    NSUInteger endOfWordToReplace = [self endOfValidWordInText:parentTextView.text afterLocation:cursorLocation];
    rangeToTransform = NSMakeRange(controlCharLocation, endOfWordToReplace - controlCharLocation);

    [parentTextView transformTextAtRange:rangeToTransform
                         withTransformer:^NSAttributedString *(__unused NSAttributedString *input) {
        NSMutableDictionary *attributes = [unhighlightedAttributes mutableCopy];
        attributes[HKWMentionAttributeName] = mention;
        // If the 'unhighlighted attributes' dictionary doesn't contain information on the font
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
    parentTextView.selectedRange = NSMakeRange(controlCharLocation + [mentionText length], 0);
    parentTextView.shouldRejectAutocorrectInsertions = NO;

    // Inform the delegate (if appropriate)
    __strong __auto_type strongStateChangeDelegate = self.stateChangeDelegate;
    if ([strongStateChangeDelegate respondsToSelector:@selector(mentionsPlugin:createdMention:atLocation:)]) {
        [strongStateChangeDelegate mentionsPlugin:self createdMention:mention atLocation:controlCharLocation];
    }
    // Invoke the parent text view's delegate if appropriate, since a mention was added and the text changed.
    __strong __auto_type externalDelegate = parentTextView.externalDelegate;
    if (self.notifyTextViewDelegateOnMentionCreation && [externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [externalDelegate textViewDidChange:parentTextView];
    }

    [self stripCustomAttributesFromTypingAttributes];
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
    __strong __auto_type parentTextView = self.parentTextView;
    if (activated) {
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
        [parentTextView restoreOriginalAutocorrection:YES];
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

- (BOOL)loadingCellSupported {
    __strong __auto_type strongDefaultChooserViewDelegate = self.defaultChooserViewDelegate;
    return ([strongDefaultChooserViewDelegate respondsToSelector:@selector(loadingCellForTableView:)]
            && [strongDefaultChooserViewDelegate respondsToSelector:@selector(heightForLoadingCellInTableView:)]);
}

- (UIView<HKWChooserViewProtocol> *)chooserView {
    return [self.creationStateMachine getEntityChooserView];
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

// TODO: Remove this call
// JIRA: POST-14031
- (void)textViewDidProgrammaticallyUpdate:(UITextView * _Null_unspecified __unused)textView {
    return;
}

#pragma mark - Developer

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
