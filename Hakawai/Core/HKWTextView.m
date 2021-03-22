//
//  HKWTextView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWTextView.h"

#import "HKWTextView+Plugins.h"

#import "_HKWLayoutManager.h"

#import "HKWSimplePluginProtocol.h"
#import "HKWControlFlowPluginProtocols.h"

#import "_HKWPrivateConstants.h"

@interface HKWTextView () <UITextViewDelegate, HKWAbstractionLayerDelegate>

@property (nonatomic) NSMutableDictionary *simplePluginsDictionary;

@property (nonatomic, readwrite) BOOL wasPaste;

/**
 Saved @c changeCount from the general pasteboard. We update this every time a change is tracked by our text view, and if it's ever not-equal to  `[UIPasteboard generalPasteboard].changeCount`, then we know that
 a pasteboard change, untracked by our text view, has happened.
 */
@property (nonatomic, readwrite) NSInteger generalPasteboardChangeCount;

/**
 String maintaining the most recently copied attributed string from this text view
 */
@property (nonatomic, copy, nullable, readwrite) NSAttributedString *stringCopiedFromCurrentTextView;

@end

static BOOL enableMentionsPluginV2 = NO;
static BOOL directlyUpdateQueryWithCustomDelegate = NO;
static BOOL enableControlCharactersToPrepend = NO;

@implementation HKWTextView

+ (BOOL)enableMentionsPluginV2 {
    return enableMentionsPluginV2;
}

+ (void)setEnableMentionsPluginV2:(BOOL)enabled {
    enableMentionsPluginV2 = enabled;
}

+ (BOOL)directlyUpdateQueryWithCustomDelegate {
    return directlyUpdateQueryWithCustomDelegate;
}

+ (void)setDirectlyUpdateQueryWithCustomDelegate:(BOOL)enabled {
    directlyUpdateQueryWithCustomDelegate = enabled;
}

+ (BOOL)enableControlCharactersToPrepend {
    return enableControlCharactersToPrepend;
}

+ (void)setEnableControlCharactersToPrepend:(BOOL)enabled {
    enableControlCharactersToPrepend = enabled;
}

#pragma mark - Lifecycle

- (instancetype _Nonnull)initWithFrame:(CGRect)frame textContainer:(nullable __unused NSTextContainer *)textContainer {
    HKWLayoutManager *manager = [HKWLayoutManager new];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(frame.size.width, FLT_MAX)];
    container.widthTracksTextView = YES;
    container.heightTracksTextView = NO;
    [manager addTextContainer:container];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    [storage addLayoutManager:manager];

    self = [super initWithFrame:frame textContainer:container];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype _Nonnull)initWithFrame:(CGRect)frame {
    HKWLayoutManager *manager = [HKWLayoutManager new];
    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(frame.size.width, FLT_MAX)];
    container.widthTracksTextView = YES;
    container.heightTracksTextView = NO;
    [manager addTextContainer:container];
    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    [storage addLayoutManager:manager];

    self = [super initWithFrame:frame textContainer:container];
    if (self) {
        [self setup];
    }
    return self;
}

// Build custom text container if the consumer is using a XIB.
- (id)awakeAfterUsingCoder:(__unused NSCoder *)aDecoder {
    HKWLayoutManager *manager = [HKWLayoutManager new];

    NSTextContainer *container = [[NSTextContainer alloc] initWithSize:self.textContainer.size];
    container.widthTracksTextView = self.textContainer.widthTracksTextView;
    container.heightTracksTextView = self.textContainer.heightTracksTextView;

    [manager addTextContainer:container];

    NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
    [storage addLayoutManager:manager];

    HKWTextView *replacement = [[[self class] alloc] initWithFrame:self.frame textContainer:container];
    replacement.translatesAutoresizingMaskIntoConstraints = NO;

    // Copy over constraints
    NSMutableArray *constraintBuffer = [NSMutableArray array];
    for (NSLayoutConstraint *c in self.constraints) {
        [constraintBuffer addObject:[replacement translatedConstraintFor:c originalObject:self]];
    }
    [self removeConstraints:self.constraints];
    [replacement addConstraints:constraintBuffer];

    replacement.backgroundColor = self.backgroundColor;

    replacement.font = self.font;
    replacement.fontSetByApp = self.font;

    replacement.clearsOnInsertion = NO;
    replacement.selectable = self.selectable;
    replacement.editable = self.editable;

    replacement.textAlignment = self.textAlignment;
    replacement.textColor = self.textColor;
    replacement.textColorSetByApp = self.textColor;
    replacement.autocapitalizationType = self.autocapitalizationType;
    replacement.autocorrectionType = self.autocorrectionType;
    replacement.spellCheckingType = self.spellCheckingType;
    [replacement setup];
    return replacement;
}

- (void)dealloc {
    if (enableMentionsPluginV2) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:UIPasteboardChangedNotification object:[UIPasteboard generalPasteboard]];
    }
}

- (void)setup {
    self.delegate = self;
    self.firstResponderIsCycling = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.abstractionLayer = [HKWAbstractionLayer instanceWithTextView:self changeRejection:YES];
    if (enableMentionsPluginV2) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pasteboardChanged) name:UIPasteboardChangedNotification object:[UIPasteboard generalPasteboard]];
    }
}

- (NSLayoutConstraint *)translatedConstraintFor:(NSLayoutConstraint *)constraint originalObject:(id)original {
    if (constraint.firstItem == original) {
        return [NSLayoutConstraint constraintWithItem:self
                                            attribute:constraint.firstAttribute
                                            relatedBy:constraint.relation
                                               toItem:constraint.secondItem
                                            attribute:constraint.secondAttribute
                                           multiplier:constraint.multiplier
                                             constant:constraint.constant];
    }
    else if (constraint.secondItem == original) {
        id const constraintFirstItem = constraint.firstItem;
        if (!constraintFirstItem) {
            NSAssert(NO, @"constraint's first item should not be nil");
            return constraint;
        }
        return [NSLayoutConstraint constraintWithItem:constraintFirstItem
                                            attribute:constraint.firstAttribute
                                            relatedBy:constraint.relation
                                               toItem:self
                                            attribute:constraint.secondAttribute
                                           multiplier:constraint.multiplier
                                             constant:constraint.constant];
    }
    else {
        return constraint;
    }
}

#pragma mark - UIResponder

- (void)copy:(id)sender {
    // Copy first, since we clear copyString each time the pasteboard is updated
    [super copy:sender];
    if (enableMentionsPluginV2) {
        // In order to maintain mentions styling, save the attributed string for the current copy action
        self.stringCopiedFromCurrentTextView = [self.attributedText attributedSubstringFromRange:self.selectedRange];
    }
}

- (void)cut:(id)sender {
    // Cut first, since we clear copyString each time the pasteboard is updated
    // Save the text before the cut happens, because afterwords it will be gone
    NSAttributedString *preCutText = [self.attributedText attributedSubstringFromRange:self.selectedRange];
    [super cut:sender];
    if (enableMentionsPluginV2) {
        // In order to maintain mentions styling, save the attributed string for the current cut action
        self.stringCopiedFromCurrentTextView = preCutText;
    }
}

- (void)clearCopyStringIfNeeded {
    // If the change count has been updated in the general pasteboard, clear the copy string, because it means that a copy was performed in another app.
    if (self.generalPasteboardChangeCount != [UIPasteboard generalPasteboard].changeCount) {
        self.stringCopiedFromCurrentTextView = nil;
        self.generalPasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
    }
}

- (void)paste:(id)sender {
    if (enableMentionsPluginV2) {
        // Paste the most recently copied string from the current text view, saved in stringCopiedFromCurrentTextView, so that we maintain mentions-styling
        // while pasting
        [self clearCopyStringIfNeeded];
        BOOL implementsWillCustomPasteTextInRange = [self.controlFlowPlugin respondsToSelector:@selector(textView:willCustomPasteTextInRange:)];
        // If stringCopiedFromCurrentTextView is set and the proper callback exists to handle the update in the control flow plugin, insert the copied string
        // programmatically
        if ([self.stringCopiedFromCurrentTextView length] > 0 && implementsWillCustomPasteTextInRange) {
            __strong __auto_type copyString = self.stringCopiedFromCurrentTextView;
            // In order to maintain mentions styling, insert the saved copyString into the attributed text
            NSUInteger cursorLocationAfterPaste = self.selectedRange.location+self.stringCopiedFromCurrentTextView.length;
            NSRange selectionRangeBeforePaste = self.selectedRange;
            // Let control plugin know that text will be pasted, so it can remove any existing mentions attributes at that point
            [self.controlFlowPlugin textView:self willCustomPasteTextInRange:self.selectedRange];
            NSMutableAttributedString *string = [self.attributedText mutableCopy];
            [string replaceCharactersInRange:selectionRangeBeforePaste withAttributedString:copyString];
            [self setAttributedText:string];
            self.selectedRange = NSMakeRange(cursorLocationAfterPaste, 0);
            // Inform delegate that text view has changed since we are overriding the normal paste behavior that would do so automatically
            [self.delegate textViewDidChange:self];
        } else {
            [super paste:sender];
        }
    } else {
        [super paste:sender];
    }
    self.wasPaste = YES;
}

- (void)pasteboardChanged {
    // Every time the pasteboard is changed, clear the copy string so we can actually paste in from other sources
    self.stringCopiedFromCurrentTextView = nil;
    // Keep track of the change count in the pasteboard from this app while it's in the foreground, so we know if it's ever changed while the app is in the
    // background
    self.generalPasteboardChangeCount = [UIPasteboard generalPasteboard].changeCount;
}

#pragma mark - Plugin Handling

- (void)addSimplePlugin:(id<HKWSimplePluginProtocol>)plugin {
    if (!plugin || [self.simplePluginsDictionary objectForKey:[plugin pluginName]]) {
        // Don't allow registration of nil or duplicate plug-ins
        return;
    }
    plugin.parentTextView = self;
    [plugin performInitialSetup];
    self.simplePluginsDictionary[[plugin pluginName]] = plugin;
}

- (void)removeSimplePluginNamed:(NSString *)name {
    if (!name) {
        return;
    }
    id<HKWSimplePluginProtocol>plugin = self.simplePluginsDictionary[name];
    [plugin performFinalCleanup];
    plugin.parentTextView = nil;
    [self.simplePluginsDictionary removeObjectForKey:name];
}

- (void)setControlFlowPlugin:(id<HKWDirectControlFlowPluginProtocol>)controlFlowPlugin {
    if (_controlFlowPlugin) {
        // There's an existing plug-in. Unregister it.
        [_controlFlowPlugin performFinalCleanup];
        _controlFlowPlugin.parentTextView = nil;
    }
    else if (controlFlowPlugin != nil && self.abstractionControlFlowPlugin != nil) {
        // There's an abstraction layer control flow plug-in.
        [self.abstractionControlFlowPlugin performFinalCleanup];
        self.abstractionControlFlowPlugin.parentTextView = nil;
        self.abstractionControlFlowPlugin = nil;
    }
    if (controlFlowPlugin) {
        // Now, register the new plug-in (if it's not nil)
        controlFlowPlugin.parentTextView = self;
        [controlFlowPlugin performInitialSetup];
    }
    // Set the backing var
    _controlFlowPlugin = controlFlowPlugin;
}

- (void)setAbstractionControlFlowPlugin:(id<HKWAbstractionLayerControlFlowPluginProtocol>)abstractionControlFlowPlugin {
    if (_abstractionControlFlowPlugin) {
        // There's an existing plug-in. Unregister it.
        [_abstractionControlFlowPlugin performFinalCleanup];
        _abstractionControlFlowPlugin.parentTextView = nil;
        self.abstractionLayer.delegate = nil;
    }
    else if (abstractionControlFlowPlugin != nil && self.controlFlowPlugin != nil) {
        // There's a direct control flow plug-in.
        [self.controlFlowPlugin performFinalCleanup];
        self.controlFlowPlugin.parentTextView = nil;
        self.controlFlowPlugin = nil;
    }
    // Reset the abstraction layer
    [self.abstractionLayer textViewDidProgrammaticallyUpdate];
    self.abstractionLayer.delegate = abstractionControlFlowPlugin;
    _abstractionControlFlowPlugin = abstractionControlFlowPlugin;
}

- (BOOL)abstractionLayerEnabled {
    return self.abstractionControlFlowPlugin != nil;
}


#pragma mark - Miscellaneous

- (void)touchOverlayViewTapped:(UITapGestureRecognizer *)gestureRecognizer {
    // First, give the plug-in a chance to do something
    if ([self.controlFlowPlugin respondsToSelector:@selector(singleLineViewportTapped)]) {
        [self.controlFlowPlugin singleLineViewportTapped];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(singleLineViewportTapped)]) {
        [self.abstractionControlFlowPlugin singleLineViewportTapped];
    }
    // Next, inform the delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewWasTappedInSingleLineViewportMode:)]) {
        [externalDelegate textViewWasTappedInSingleLineViewportMode:self];
    }

    // Move the cursor to tapped location
    CGPoint tapLocation = [gestureRecognizer locationInView:self];

    NSUInteger characterIndex = [self.layoutManager characterIndexForPoint:tapLocation
                                                           inTextContainer:self.textContainer
                                  fractionOfDistanceBetweenInsertionPoints:NULL];

    if (characterIndex < self.textStorage.length) {
        self.selectedRange = NSMakeRange(characterIndex, 0);
    }
}

-(void) textViewDidProgrammaticallyUpdate {

    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidProgrammaticallyUpdate:)]) {
        [self.controlFlowPlugin textViewDidProgrammaticallyUpdate:self];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textViewDidProgrammaticallyUpdate:)]) {
        [self.abstractionControlFlowPlugin textViewDidProgrammaticallyUpdate:self];
    }
}

- (void)handleDictationString:(NSString *)dictationString {
    if ([self.controlFlowPlugin respondsToSelector:@selector(setDictationString:)]) {
        [self.controlFlowPlugin setDictationString:dictationString];
    }

    // Used selected range to get the cursor position. So that text will be replaced after the cursor.
    if ([self shouldChangeTextInRange:self.selectedRange replacementText:dictationString isDictationText:YES textView:self]) {
        [self insertText:dictationString];
    }
}

- (BOOL)shouldChangeTextInRange:(NSRange)range
                replacementText:(NSString *)replacementText
                isDictationText:(BOOL)isDictationText
                       textView:(UITextView *)textView {
    // Note that the abstraction layer overrides all other behavior
    if (self.abstractionLayerEnabled) {
        return [self.abstractionLayer textViewShouldChangeTextInRange:range replacementText:replacementText wasPaste:self.wasPaste];
    }

    // TODO: Remove shouldRejectAutocorrectInsertions and wasPaste as they are hacks, not needed with cursor-based mention refactor
    // JIRA: POST-14031
    if (!enableMentionsPluginV2 && !isDictationText && self.shouldRejectAutocorrectInsertions && [replacementText length] > 1 && !self.wasPaste) {
        return NO;
    }
    self.wasPaste = NO;
    if (self.firstResponderIsCycling) {
        return NO;
    }
    // Inform plug-in
    BOOL customValue = YES;
    BOOL shouldUseCustomValue = NO;

    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldUseCustomValue = YES;
        customValue = [self.controlFlowPlugin textView:textView
                               shouldChangeTextInRange:range
                                       replacementText:replacementText];
    }
    // Forward to external delegate if:
    // 1) There is no control flow plugin registered OR
    // 2) Control flow plugin doesn't implement this delegate method OR
    // 2) Control flow plugin has approved the replacement
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ((!shouldUseCustomValue || customValue)
        && [externalDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldUseCustomValue = YES;
        customValue = [externalDelegate textView:textView
                         shouldChangeTextInRange:range
                                 replacementText:replacementText];
    }

    // Update the typing attributes dictionary to support custom attributes
    if (range.location != NSNotFound) {
        NSMutableDictionary *newTypingAttributes = [self.typingAttributes mutableCopy];
        for (NSString *attribute in self.customTypingAttributes) {
            newTypingAttributes[attribute] = self.customTypingAttributes[attribute];
        }
        self.typingAttributes = [newTypingAttributes copy];
    }

    return shouldUseCustomValue ? customValue : YES;
}

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    BOOL shouldBeginEditing = YES;
    __strong __auto_type externalDelegate = self.externalDelegate;
    if (self.firstResponderIsCycling) {
        shouldBeginEditing = YES;
    }
    else if ([self.controlFlowPlugin respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBeginEditing = [self.controlFlowPlugin textViewShouldBeginEditing:textView];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBeginEditing = [self.abstractionControlFlowPlugin textViewShouldBeginEditing:textView];
    }
    // Forward to external delegate
    else if ([externalDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBeginEditing = [externalDelegate textViewShouldBeginEditing:textView];
    }

    // Let external-delegate know about begin editing.
    if ([externalDelegate respondsToSelector:@selector(textView:willBeginEditing:)]) {
        [externalDelegate textView:self willBeginEditing:shouldBeginEditing];
    }
    return shouldBeginEditing;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.firstResponderIsCycling) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.controlFlowPlugin textViewDidBeginEditing:textView];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.abstractionControlFlowPlugin textViewDidBeginEditing:textView];
    }
    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [externalDelegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    BOOL shouldEndEditing = YES;
    __strong __auto_type externalDelegate = self.externalDelegate;
    if (self.firstResponderIsCycling) {
        shouldEndEditing = YES;
    }
    else if ([self.controlFlowPlugin respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEndEditing = [self.controlFlowPlugin textViewShouldEndEditing:textView];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEndEditing = [self.abstractionControlFlowPlugin textViewShouldEndEditing:textView];
    }
    // Forward to external delegate
    else if ([externalDelegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEndEditing = [externalDelegate textViewShouldEndEditing:textView];
    }

    // Let external-delegate know about end editing.
    if ([externalDelegate respondsToSelector:@selector(textView:willEndEditing:)]) {
        [externalDelegate textView:self willEndEditing:shouldEndEditing];
    }
    return shouldEndEditing;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.firstResponderIsCycling) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.controlFlowPlugin textViewDidEndEditing:textView];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.abstractionControlFlowPlugin textViewDidEndEditing:textView];
    }
    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [externalDelegate textViewDidEndEditing:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText {
    return [self shouldChangeTextInRange:range replacementText:replacementText isDictationText:NO textView:textView];
}

- (void)textViewDidChange:(UITextView *)textView {
    if (self.abstractionLayerEnabled) {
        [self.abstractionLayer textViewDidChange];
        return;
    }
    if (self.firstResponderIsCycling) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidChange:)]) {
        [self.controlFlowPlugin textViewDidChange:textView];
    }
    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [externalDelegate textViewDidChange:textView];
    }
}

- (void)textViewDidChangeSelection:(UITextView *)textView {
    if (self.abstractionLayerEnabled) {
        [self.abstractionLayer textViewDidChangeSelection];
        return;
    }

    if (self.firstResponderIsCycling) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        if (self.transformInProgress) {
            // Do nothing
        }
        else {
            [self.controlFlowPlugin textViewDidChangeSelection:textView];
        }
    }
    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [externalDelegate textViewDidChangeSelection:textView];
    }

    // If applicable, and the text view is in single line viewport mode, adjust the visible portion so it matches the
    //  current insertion position.
    if (self.inSingleLineViewportMode
        && self.singleLineViewportShouldFollowInsertionCaret
        && self.selectedRange.length == 0
        && !self.transformInProgress) {
        // Get the new y-offset, based on the current insertion position
        UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:(NSInteger)self.selectedRange.location];
        CGRect caretRect = [self caretRectForPosition:p];
        CGFloat newOffsetY = 0;
        switch (self.viewportMode) {
            case HKWViewportModeTop:
                newOffsetY = caretRect.origin.y - self.lineFragmentPadding;
                break;
            case HKWViewportModeBottom:
                newOffsetY = (caretRect.origin.y - (self.bounds.size.height - caretRect.size.height)
                              + self.lineFragmentPadding);
                break;
        }

        // Adjust the y-offset if necessary
        CGFloat oldY = self.viewportContentOffset.y;
        CGFloat oldX = self.viewportContentOffset.x;
        // Check for NaN (e.g. from caretRectForPosition:)
        if (!isnan(oldX) && !isnan(newOffsetY) && !(newOffsetY >= CGFLOAT_MAX) && newOffsetY != oldY) {
            self.viewportContentOffset = CGPointMake(oldX, newOffsetY);
            [self setContentOffset:self.viewportContentOffset animated:NO];
            if ([self.controlFlowPlugin respondsToSelector:@selector(singleLineViewportChanged)]) {
                [self.controlFlowPlugin singleLineViewportChanged];
            }
            else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(singleLineViewportChanged)]) {
                [self.abstractionControlFlowPlugin singleLineViewportChanged];
            }
        }
    }
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if (self.firstResponderIsCycling) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        return [self.controlFlowPlugin textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange interaction:interaction];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.abstractionControlFlowPlugin textView:textView
                          shouldInteractWithTextAttachment:textAttachment
                                                   inRange:characterRange];
    }

    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:interaction:)]) {
        return [externalDelegate textView:textView shouldInteractWithTextAttachment:textAttachment inRange:characterRange interaction:interaction];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange interaction:(UITextItemInteraction)interaction {
    if (self.firstResponderIsCycling) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
        return [self.controlFlowPlugin textView:textView shouldInteractWithURL:URL inRange:characterRange interaction:interaction];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
        return [self.abstractionControlFlowPlugin textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    // Forward to external delegate
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:interaction:)]) {
        return [externalDelegate textView:textView shouldInteractWithURL:URL inRange:characterRange interaction:interaction];
    }
    return YES;
}


#pragma mark - HKWAbstractionViewDelegate

- (BOOL)textView:(UITextView *)textView
    textInserted:(NSString *)text
      atLocation:(NSUInteger)location
     autocorrect:(BOOL)autocorrect {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin
         respondsToSelector:@selector(textView:textInserted:atLocation:autocorrect:)]) {
        [self.abstractionControlFlowPlugin textView:textView
                                       textInserted:text
                                         atLocation:location
                                        autocorrect:autocorrect];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView textDeletedFromLocation:(NSUInteger)location length:(NSUInteger)length {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:textDeletedFromLocation:length:)]) {
        [self.abstractionControlFlowPlugin textView:textView
                            textDeletedFromLocation:location
                                             length:length];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView replacedTextAtRange:(NSRange)replacementRange
         newText:(NSString *)newText
     autocorrect:(BOOL)autocorrect {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin
         respondsToSelector:@selector(textView:replacedTextAtRange:newText:autocorrect:)]) {
        [self.abstractionControlFlowPlugin textView:textView
                                replacedTextAtRange:replacementRange
                                            newText:newText
                                        autocorrect:autocorrect];
    }
    return YES;
}

- (void)textView:(UITextView *)textView cursorChangedToInsertion:(NSUInteger)location {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:cursorChangedToInsertion:)]) {
        [self.abstractionControlFlowPlugin textView:textView cursorChangedToInsertion:location];
    }
}

- (void)textView:(UITextView *)textView cursorChangedToSelection:(NSRange)selectionRange {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:cursorChangedToSelection:)]) {
        [self.abstractionControlFlowPlugin textView:textView cursorChangedToSelection:selectionRange];
    }
}

- (void)textView:(UITextView *)textView characterDeletionWasIgnoredAtLocation:(NSUInteger)location {
    NSAssert(self.abstractionLayerEnabled, @"Internal error");
    if ([self.abstractionControlFlowPlugin
         respondsToSelector:@selector(textView:characterDeletionWasIgnoredAtLocation:)]) {
        [self.abstractionControlFlowPlugin textView:textView characterDeletionWasIgnoredAtLocation:location];
    }
}


#pragma mark - Scroll view

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGPoint currentOffset = self.contentOffset;
    if (self.inSingleLineViewportMode) {
        // Lock the view to the single line viewport
        [scrollView setContentOffset:self.viewportContentOffset animated:NO];
    }
    else if (self.disableVerticalScrolling) {
        // Lock the view to the top of the content
        [scrollView setContentOffset:CGPointMake(currentOffset.x, 0) animated:NO];
    }
}

#pragma mark - UITextInput

- (void)insertDictationResult:(NSArray<UIDictationPhrase *> *)dictationResults {
    NSMutableString *const dictationString = [[NSMutableString alloc] init];
    for (UIDictationPhrase *dictationResult in dictationResults) {
        [dictationString appendString:dictationResult.text];
    }
    [self handleDictationString:dictationString];
}

#pragma mark - Properties

- (void)setTextColor:(UIColor *)textColor {
    [super setTextColor:textColor];
    if (textColor) {
        self.textColorSetByApp = textColor;
    }
}

- (void)setFont:(UIFont *)font {
    [super setFont:font];
    if (font) {
        self.fontSetByApp = font;
    }
}

- (NSMutableDictionary *)simplePluginsDictionary {
    if (!_simplePluginsDictionary) {
        _simplePluginsDictionary = [NSMutableDictionary dictionary];
    }
    return _simplePluginsDictionary;
}

- (NSAttributedString *)stringCopiedFromCurrentTextView {
    if (!_stringCopiedFromCurrentTextView) {
        _stringCopiedFromCurrentTextView = [[NSAttributedString alloc] init];
    }
    return _stringCopiedFromCurrentTextView;
}

- (NSMutableDictionary *)customTypingAttributes {
    if (!_customTypingAttributes) {
        _customTypingAttributes = [NSMutableDictionary dictionary];
    }
    return _customTypingAttributes;
}

- (NSArray *)simplePlugins {
    return [self.simplePluginsDictionary allValues];
}

- (CGFloat)lineFragmentPadding {
    return self.textContainer.lineFragmentPadding;
}

- (NSMutableArray *)accessoryViewConstraints {
    if (!_accessoryViewConstraints) {
        _accessoryViewConstraints = [NSMutableArray arrayWithCapacity:2];
    }
    return _accessoryViewConstraints;
}

- (id<UITextViewDelegate>)simpleDelegate {
    return (id<UITextViewDelegate>)self.externalDelegate;
}

- (void)setSimpleDelegate:(id<UITextViewDelegate>)simpleDelegate {
    self.externalDelegate = (id<HKWTextViewDelegate>)simpleDelegate;
}

- (void)setDisableVerticalScrolling:(BOOL)disableVerticalScrolling {
    _disableVerticalScrolling = disableVerticalScrolling;
    self.showsVerticalScrollIndicator = !disableVerticalScrolling;
}

- (UIView *)touchCaptureOverlayView {
    if (!_touchCaptureOverlayView) {
        UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(touchOverlayViewTapped:)];
        _touchCaptureOverlayView.userInteractionEnabled = YES;
        _touchCaptureOverlayView = [UIView new];
        _touchCaptureOverlayView.translatesAutoresizingMaskIntoConstraints = NO;
        [_touchCaptureOverlayView addGestureRecognizer:tapGesture];
    }
    return _touchCaptureOverlayView;
}

@end


# pragma mark - Miscellaneous utilities

BOOL HKW_systemVersionIsAtLeast(NSString *version) {
    /*
     let deviceSystemVersion = self.currentDevice().systemVersion
     let osVersionCompareResult = deviceSystemVersion.compare(version, options: .NumericSearch)
     return osVersionCompareResult == .OrderedSame || osVersionCompareResult == .OrderedDescending
     */
    NSString *systemVersion = [UIDevice currentDevice].systemVersion;
    NSComparisonResult result = [systemVersion compare:version options:NSNumericSearch];
    return result == NSOrderedDescending || result == NSOrderedSame;
}
