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
@property (nonatomic, strong) NSMutableDictionary *simplePluginsDictionary;
@end

@implementation HKWTextView

#pragma mark - Lifecycle

- (instancetype _Nonnull)initWithFrame:(CGRect)frame textContainer:(nullable NSTextContainer *)textContainer {
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
- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
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

- (void)setup {
    self.delegate = self;
    self.firstResponderIsCycling = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;

    self.abstractionLayer = [HKWAbstractionLayer instanceWithTextView:self changeRejection:YES];
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
        return [NSLayoutConstraint constraintWithItem:constraint.firstItem
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

- (void)paste:(id)sender {
    [super paste:sender];
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidHaveTextPastedIn:)]) {
        [self.externalDelegate textViewDidHaveTextPastedIn:self];
    }
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewWasTappedInSingleLineViewportMode:)]) {
        [self.externalDelegate textViewWasTappedInSingleLineViewportMode:self];
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

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    BOOL shouldBeginEditing = YES;
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
    else if ([self.externalDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        shouldBeginEditing = [self.externalDelegate textViewShouldBeginEditing:textView];
    }

    // Let external-delegate know about begin editing.
    if ([self.externalDelegate respondsToSelector:@selector(textView:willBeginEditing:)]) {
        [self.externalDelegate textView:self willBeginEditing:shouldBeginEditing];
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.externalDelegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    BOOL shouldEndEditing = YES;
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
    else if ([self.externalDelegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        shouldEndEditing = [self.externalDelegate textViewShouldEndEditing:textView];
    }


    // Let external-delegate know about end editing.
    if ([self.externalDelegate respondsToSelector:@selector(textView:willEndEditing:)]) {
        [self.externalDelegate textView:self willEndEditing:shouldEndEditing];
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.externalDelegate textViewDidEndEditing:textView];
    }
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText {
    // Note that the abstraction layer overrides all other behavior
    if (self.abstractionLayerEnabled) {
        return [self.abstractionLayer textViewShouldChangeTextInRange:range replacementText:replacementText];
    }

    if (self.shouldRejectAutocorrectInsertions
        && [replacementText length] > 1
        && ![replacementText isEqualToString:[[UIPasteboard generalPasteboard] string]]) {
        // PROVISIONAL FIX
        // We need some way to distinguish autocorrect insertions from pasting in text. Since currently the only way
        //  that multiple characters can be inserted at a time is through pasting text from the pasteboard, we can check
        //  the text in the pasteboard against the string to be inserted to determine whether or not the request is
        //  coming from the autocorrect module
        return NO;
    }
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
    if ((!shouldUseCustomValue || customValue)
        && [self.externalDelegate respondsToSelector:@selector(textView:shouldChangeTextInRange:replacementText:)]) {
        shouldUseCustomValue = YES;
        customValue = [self.externalDelegate textView:textView
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidChange:)]) {
        [self.externalDelegate textViewDidChange:textView];
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidChangeSelection:)]) {
        [self.externalDelegate textViewDidChangeSelection:textView];
    }

    // If applicable, and the text view is in single line viewport mode, adjust the visible portion so it matches the
    //  current insertion position.
    if (self.inSingleLineViewportMode
        && self.singleLineViewportShouldFollowInsertionCaret
        && self.selectedRange.length == 0
        && !self.transformInProgress) {
        // Get the new y-offset, based on the current insertion position
        UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:self.selectedRange.location];
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
        if (!isnan(oldX) && !isnan(newOffsetY) && newOffsetY != oldY) {
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

- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange {
    if (self.firstResponderIsCycling) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.controlFlowPlugin textView:textView
               shouldInteractWithTextAttachment:textAttachment
                                        inRange:characterRange];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.abstractionControlFlowPlugin textView:textView
               shouldInteractWithTextAttachment:textAttachment
                                        inRange:characterRange];
    }

    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.externalDelegate textView:textView
              shouldInteractWithTextAttachment:textAttachment
                                       inRange:characterRange];
    }
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (self.firstResponderIsCycling) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.controlFlowPlugin textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    else if ([self.abstractionControlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.abstractionControlFlowPlugin textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.externalDelegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
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
