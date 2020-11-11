//
//  HKWTextView+Plugins.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTextView+Plugins.h"
#import "_HKWTextView.h"

#import "_HKWPrivateConstants.h"

typedef NS_ENUM(NSInteger, HKWCycleFirstResponderMode) {
    HKWCycleFirstResponderModeNone,
    HKWCycleFirstResponderModeAutocapitalizationNone,
    HKWCycleFirstResponderModeAutocapitalizationWords,
    HKWCycleFirstResponderModeAutocapitalizationSentences,
    HKWCycleFirstResponderModeAutocapitalizationAllCharacters,
    HKWCycleFirstResponderModeAutocorrectionDefault,
    HKWCycleFirstResponderModeAutocorrectionNo,
    HKWCycleFirstResponderModeAutocorrectionYes,
    HKWCycleFirstResponderModeSpellCheckingDefault,
    HKWCycleFirstResponderModeSpellCheckingNo,
    HKWCycleFirstResponderModeSpellCheckingYes
};

@implementation HKWTextView (Plugins)

#pragma mark - API (viewport)

- (CGRect)enterSingleLineViewportMode:(HKWViewportMode)mode captureTouches:(BOOL)shouldCaptureTouches {
    BOOL needConstraints = NO;
    if (self.inSingleLineViewportMode) {
        return CGRectNull;
    }
    if (shouldCaptureTouches) {
        [self.superview addSubview:self.touchCaptureOverlayView];
        needConstraints = YES;

    }
    self.viewportMode = mode;
    if ([self respondsToSelector:@selector(layoutManager)]) {
        [self.layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [self.attributedText length])];
    }

    self.originalContentOffset = self.contentOffset;
    // Should this be changed?
    self.singleLineViewportShouldFollowInsertionCaret = YES;

    // Cannot enter viewport mode with selected text
    if (self.selectedRange.length > 0) {
        NSUInteger newLocation = self.selectedRange.location + self.selectedRange.length;
        self.selectedRange = NSMakeRange(newLocation, 0);
    }

    UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:(NSInteger)self.selectedRange.location];
    NSAssert(p != nil, @"Text position from %@, offset %ld returned nil. This should never happen.",
             self.beginningOfDocument, (unsigned long)self.selectedRange.location);
    CGRect caretRect = [self caretRectForPosition:p];

    CGFloat offsetY = 0;
    CGRect viewportRect;
    switch (mode) {
        case HKWViewportModeTop:
            offsetY = caretRect.origin.y - self.lineFragmentPadding;
            viewportRect = CGRectMake(0,
                                      0,
                                      self.bounds.size.width,
                                      caretRect.size.height + self.lineFragmentPadding);
            break;
        case HKWViewportModeBottom:
            offsetY = caretRect.origin.y - (self.bounds.size.height - caretRect.size.height) + self.lineFragmentPadding;
            viewportRect = CGRectMake(0,
                                      self.bounds.size.height - (caretRect.size.height + self.lineFragmentPadding),
                                      self.bounds.size.width,
                                      caretRect.size.height + self.lineFragmentPadding);
            break;
    }
    NSAssert(!isnan(offsetY), @"Single viewport content y-offset calculated as NaN. This should never happen.");

    // Move the viewport to show only the relevant line
    self.viewportContentOffset = CGPointMake(self.contentOffset.x, offsetY);
    [self setContentOffset:self.viewportContentOffset animated:NO];

    if (needConstraints) {
        // Add constraints to the touch capture overlay view
        // Constrain the overlay view to be as wide as its enclosing text view
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.touchCaptureOverlayView
                                                                   attribute:NSLayoutAttributeWidth
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeWidth
                                                                  multiplier:1
                                                                    constant:0]];
        // Constrain the overlay view to be the proper height
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.touchCaptureOverlayView
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1
                                                                    constant:caretRect.size.height + self.lineFragmentPadding]];
        // Constrain the overlay view's leading edge to be fixed to the text view's leading edge
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.touchCaptureOverlayView
                                                                   attribute:NSLayoutAttributeLeft
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeLeft
                                                                  multiplier:1
                                                                    constant:0]];
        NSLayoutAttribute attr;
        switch (mode) {
            case HKWViewportModeTop:
                attr = NSLayoutAttributeTop;
                break;
            case HKWViewportModeBottom:
                attr = NSLayoutAttributeBottom;
                break;
        }
        // Constrain the overlay view's top or bottom to be fixed to the text view's top or bottom
        [self.superview addConstraint:[NSLayoutConstraint constraintWithItem:self.touchCaptureOverlayView
                                                                   attribute:attr
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:attr
                                                                  multiplier:1
                                                                    constant:0]];
        [self updateConstraints];
    }

    self.inSingleLineViewportMode = YES;
    self.showsVerticalScrollIndicator = NO;
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidEnterSingleLineViewportMode:)]) {
        [externalDelegate textViewDidEnterSingleLineViewportMode:self];
    }
    return viewportRect;
}

- (CGRect)rectForSingleLineViewportInMode:(HKWViewportMode)mode {
    UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:(NSInteger)self.selectedRange.location];
    CGRect caretRect = [self caretRectForPosition:p];
    CGRect viewportRect;
    switch (mode) {
        case HKWViewportModeTop:
            viewportRect = CGRectMake(0,
                                      0,
                                      self.bounds.size.width,
                                      caretRect.size.height + self.lineFragmentPadding);
            break;
        case HKWViewportModeBottom:
            viewportRect = CGRectMake(0,
                                      self.bounds.size.height - (caretRect.size.height + self.lineFragmentPadding),
                                      self.bounds.size.width,
                                      caretRect.size.height + self.lineFragmentPadding);
            break;
    }
    return viewportRect;
}

- (void)exitSingleLineViewportMode {
    if (!self.inSingleLineViewportMode) {
        return;
    }
    [self.touchCaptureOverlayView removeFromSuperview];
    if ([self respondsToSelector:@selector(layoutManager)]) {
        [self.layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [self.attributedText length])];
    }
    self.showsVerticalScrollIndicator = YES;
    self.inSingleLineViewportMode = NO;
    // Reset viewport to original value
    __strong __auto_type externalDelegate = self.externalDelegate;
    if ([externalDelegate respondsToSelector:@selector(textViewDidExitSingleLineViewportMode:)]) {
        [externalDelegate textViewDidExitSingleLineViewportMode:self];
    }
    [self setContentOffset:self.originalContentOffset animated:NO];
}


#pragma mark - API (helper views)

- (void)attachSiblingAccessoryView:(UIView *)view position:(CGPoint)position {
    if (!view || self.attachedAccessoryView) {
        return;
    }
    CGRect f = view.frame;
    f.origin.x = position.x + self.frame.origin.x;
    f.origin.y = position.y + self.frame.origin.y;
    view.frame = f;
    self.accessorySiblingViewOrigin = position;
    self.attachedAccessoryView = view;
    self.accessoryViewMode = HKWAccessoryViewModeSibling;
    [self.superview addSubview:view];
    // Setup layout constraints
    if (self.onAccessoryViewAttachmentBlock) {
        self.onAccessoryViewAttachmentBlock(view, NO);
    }
    else {
        // Default constraints
        NSMutableArray *buffer = [NSMutableArray array];
        [buffer addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-X-[v]"
                                                                            options:0
                                                                            metrics:@{@"X": @(f.origin.x)}
                                                                              views:@{@"v": view}]];
        [buffer addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-Y-[v]" options:0
                                                                            metrics:@{@"Y": @(f.origin.y)}
                                                                              views:@{@"v": view}]];
        self.accessoryViewConstraints = buffer;
        [self.superview addConstraints:buffer];
    }
}

- (void)attachFreeFloatingAccessoryView:(UIView *)view absolutePosition:(CGPoint)position {
    if (!view || self.attachedAccessoryView) {
        return;
    }
    CGRect f = view.frame;
    f.origin.x = position.x;
    f.origin.y = position.y;
    view.frame = f;
    self.attachedAccessoryView = view;
    self.accessoryViewMode = HKWAccessoryViewModeFreeFloating;

    // Find the topmost superview
    UIView *nextView = self.customTopLevelView;
    if (!nextView) {
        // No custom top-level view. Find our own.
        nextView = self;
        NSInteger count = 0;
        while (YES) {
            NSAssert(count < 5000,
                     @"Internal error: could not find superview of editor text view after %ld levels",
                     (long) count);
            if (nextView.superview != nil && ![nextView.superview isKindOfClass:[UIWindow class]]) {
                nextView = nextView.superview;
                count++;
                continue;
            }
            // Reached the top level
            break;
        }
    }
    HKWLOG(@"Adding free-floating accessory view as subview of top-level view: (%@)...", nextView);
    [nextView addSubview:view];
    // Add constraints
    if (self.onAccessoryViewAttachmentBlock) {
        self.onAccessoryViewAttachmentBlock(view, YES);
    }
    else {
        NSMutableArray *buffer = [NSMutableArray array];
        [buffer addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"|-X-[v]"
                                                                            options:0
                                                                            metrics:@{@"X": @(position.x)}
                                                                              views:@{@"v": view}]];
        [buffer addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-Y-[v]" options:0
                                                                            metrics:@{@"Y": @(position.y)}
                                                                              views:@{@"v": view}]];
        self.accessoryViewConstraints = buffer;
        [nextView addConstraints:buffer];
    }
}

- (void)detachAccessoryView:(UIView *)view {
    if (view != self.attachedAccessoryView) {
        return;
    }
    HKWLOG(@"Detaching accessory view...");
    self.attachedAccessoryView = nil;
    self.onAccessoryViewAttachmentBlock = nil;
    // Remove constraints
    // TODO: Not sure if this is actually necessary. Destroying the view should destroy its constraints automatically.
    [view removeConstraints:self.accessoryViewConstraints];
    [self.accessoryViewConstraints removeAllObjects];
    [view removeFromSuperview];
}

- (void)setTopLevelViewForAccessoryViewPositioning:(UIView *)view {
    self.customTopLevelView = view;
}


#pragma mark - API (autocorrect)

- (void)dismissAutocorrectSuggestion {
    [self cycleFirstResponderStatusWithMode:HKWCycleFirstResponderModeNone
                            cancelAnimation:YES
                disableResignFirstResponder:NO];
}

- (void)overrideAutocapitalizationWith:(UITextAutocapitalizationType)override {
    if (self.overridingAutocapitalization) {
        return;
    }
    self.overridingAutocapitalization = YES;
    self.originalAutocapitalization = self.autocapitalizationType;
    if (HKWTextView.enableMentionsPluginV2) {
        self.autocapitalizationType = override;
        [self reloadInputViews];
    } else {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocapitalization:override]
                                cancelAnimation:YES
                    disableResignFirstResponder:NO];
    }
}

- (void)restoreOriginalAutocapitalization:(BOOL)shouldCycle {
    if (!self.overridingAutocapitalization) {
        return;
    }
    if (HKWTextView.enableMentionsPluginV2) {
        self.autocapitalizationType = self.originalAutocapitalization;
        [self reloadInputViews];
    } else {
        if (shouldCycle) {
            [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocapitalization:self.originalAutocapitalization]
                                    cancelAnimation:YES
                        disableResignFirstResponder:NO];
        }
        else {
            self.autocapitalizationType = self.originalAutocapitalization;
        }
    }
    self.overridingAutocapitalization = NO;
}

- (void)overrideAutocorrectionWith:(UITextAutocorrectionType)override {
    if (self.overridingAutocorrection) {
        return;
    }
    self.overridingAutocorrection = YES;
    self.originalAutocorrection = self.autocorrectionType;
    if (HKWTextView.enableMentionsPluginV2) {
        self.autocorrectionType = override;
        [self reloadInputViews];
    } else {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocorrection:override]
                                cancelAnimation:YES
                    disableResignFirstResponder:YES];
    }
}

- (void)restoreOriginalAutocorrection:(BOOL)shouldCycle {
    if (!self.overridingAutocorrection) {
        return;
    }
    if (HKWTextView.enableMentionsPluginV2) {
        self.autocorrectionType = self.originalAutocorrection;
        [self reloadInputViews];
    } else {
        if (shouldCycle) {
            [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocorrection:self.originalAutocorrection]
                                    cancelAnimation:YES
                        disableResignFirstResponder:YES];
        }
        else {
            self.autocorrectionType = self.originalAutocorrection;
        }
    }
    self.overridingAutocorrection = NO;
}

- (void)overrideSpellCheckingWith:(UITextSpellCheckingType)override {
    if (self.overridingSpellChecking) {
        return;
    }
    self.overridingSpellChecking = YES;
    self.originalSpellChecking = self.spellCheckingType;
    if (HKWTextView.enableMentionsPluginV2) {
        self.spellCheckingType = override;
        [self reloadInputViews];
    } else {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForSpellChecking:override]
                                cancelAnimation:YES
                    disableResignFirstResponder:NO];
    }
}

- (void)restoreOriginalSpellChecking:(BOOL)shouldCycle {
    if (!self.overridingSpellChecking) {
        return;
    }
    if (HKWTextView.enableMentionsPluginV2) {
        self.spellCheckingType = self.originalSpellChecking;
        [self reloadInputViews];
    } else {
        if (shouldCycle) {
            [self cycleFirstResponderStatusWithMode:[HKWTextView modeForSpellChecking:self.originalSpellChecking]
                                    cancelAnimation:YES
                        disableResignFirstResponder:NO];
        }
        else {
            self.spellCheckingType = self.originalSpellChecking;
        }
    }
    self.overridingSpellChecking = NO;
}
/*
 disableResignFirstResponder is set to skip calling resignFirstResponder, which will result in crash with 3D touch. Not calling resignFirstResponder in general does not seem to have negative impact.
 However, to limit the scope of the change and the potential impact, we will skill the call only in the code path of 3D touch crashes, which are restoreOriginalAutocorrection and overrideAutocorrectionWith.
 TODO: remove disableResignFirstResponder once we have more data about its impact.
 */
- (void)cycleFirstResponderStatusWithMode:(HKWCycleFirstResponderMode)mode cancelAnimation:(BOOL)cancelAnimation disableResignFirstResponder:(BOOL)disableResignFirstResponder{
    BOOL usingAbstraction = self.abstractionLayerEnabled;
    if (usingAbstraction) {
        [self.abstractionLayer pushIgnore];
    }
    self.firstResponderIsCycling = YES;
    if (!disableResignFirstResponder) {
        [self resignFirstResponder];
    }

    switch (mode) {
        case HKWCycleFirstResponderModeAutocapitalizationNone:
            self.autocapitalizationType = UITextAutocapitalizationTypeNone;
            break;
        case HKWCycleFirstResponderModeAutocapitalizationAllCharacters:
            self.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
            break;
        case HKWCycleFirstResponderModeAutocapitalizationSentences:
            self.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            break;
        case HKWCycleFirstResponderModeAutocapitalizationWords:
            self.autocapitalizationType = UITextAutocapitalizationTypeWords;
            break;
        case HKWCycleFirstResponderModeAutocorrectionDefault:
            self.autocorrectionType = UITextAutocorrectionTypeDefault;
            break;
        case HKWCycleFirstResponderModeAutocorrectionNo:
            self.autocorrectionType = UITextAutocorrectionTypeNo;
            break;
        case HKWCycleFirstResponderModeAutocorrectionYes:
            self.autocorrectionType = UITextAutocorrectionTypeYes;
            break;
        case HKWCycleFirstResponderModeNone:
            break;
        case HKWCycleFirstResponderModeSpellCheckingDefault:
            self.spellCheckingType = UITextSpellCheckingTypeDefault;
            break;
        case HKWCycleFirstResponderModeSpellCheckingNo:
            self.spellCheckingType = UITextSpellCheckingTypeNo;
            break;
        case HKWCycleFirstResponderModeSpellCheckingYes:
            self.spellCheckingType = UITextSpellCheckingTypeYes;
            break;
    }

    [self becomeFirstResponder];
    // The following cancels any animation that is automatically triggered as part of rejecting an autocorrect
    //  suggestion
    if (cancelAnimation) {
        [self setContentOffset:self.contentOffset animated:NO];
    }
    self.firstResponderIsCycling = NO;
    if (usingAbstraction) {
        [self.abstractionLayer popIgnore];
    }
}

+ (HKWCycleFirstResponderMode)modeForAutocapitalization:(UITextAutocapitalizationType)type {
    switch (type) {
        case UITextAutocapitalizationTypeNone:
            return HKWCycleFirstResponderModeAutocapitalizationNone;
        case UITextAutocapitalizationTypeWords:
            return HKWCycleFirstResponderModeAutocapitalizationWords;
        case UITextAutocapitalizationTypeSentences:
            return HKWCycleFirstResponderModeAutocapitalizationSentences;
        case UITextAutocapitalizationTypeAllCharacters:
            return HKWCycleFirstResponderModeAutocapitalizationAllCharacters;
    }
}

+ (HKWCycleFirstResponderMode)modeForAutocorrection:(UITextAutocorrectionType)type {
    switch (type) {
        case UITextAutocorrectionTypeDefault:
            return HKWCycleFirstResponderModeAutocorrectionDefault;
        case UITextAutocorrectionTypeNo:
            return HKWCycleFirstResponderModeAutocorrectionNo;
        case UITextAutocorrectionTypeYes:
            return HKWCycleFirstResponderModeAutocorrectionYes;
    }
}

+ (HKWCycleFirstResponderMode)modeForSpellChecking:(UITextSpellCheckingType)type {
    switch (type) {
        case UITextSpellCheckingTypeDefault:
            return HKWCycleFirstResponderModeSpellCheckingDefault;
        case UITextSpellCheckingTypeNo:
            return HKWCycleFirstResponderModeSpellCheckingNo;
        case UITextSpellCheckingTypeYes:
            return HKWCycleFirstResponderModeSpellCheckingYes;
    }
}

@end
