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

@implementation HKWTextView (Plugins)

#pragma mark - API (text)

- (void)transformSelectedTextWithTransformer:(NSAttributedString *(^)(NSAttributedString *))transformer {
    NSRange selectedRange = self.selectedRange;
    if (!transformer || selectedRange.location == NSNotFound) {
        return;
    }
    [self transformTextAtRange:selectedRange withTransformer:transformer];
}

- (void)transformTextAtRange:(NSRange)range
             withTransformer:(NSAttributedString *(^)(NSAttributedString *))transformer {
    if (transformer && [self.attributedText length] == 0 && range.location == 0) {
        // Special case: text view text is empty; beginning is valid
        self.attributedText = transformer(nil);
        return;
    }
    if (!transformer
        || range.location == NSNotFound
        || range.location > [self.attributedText length]) {
        return;
    }

    BOOL shouldRestore = self.selectedRange.length == 0 && self.selectedRange.location != NSNotFound;
    NSRange originalSelectedRange = self.selectedRange;
    self.transformInProgress = YES;
    NSUInteger end = range.length + range.location;
    if (end > [self.attributedText length]) {
        // Trim the range if it extends past the end of the string.
        end = [self.attributedText length];
        range.length = [self.attributedText length] - range.location;
    }
    NSAttributedString *originalInfix = [self.attributedText attributedSubstringFromRange:range];
    NSAttributedString *prefixString = [self.attributedText attributedSubstringFromRange:NSMakeRange(0, range.location)];
    NSAttributedString *infixString = transformer(originalInfix);
    NSAttributedString *postfixString = [self.attributedText attributedSubstringFromRange:NSMakeRange(end, [self.attributedText length] - end)];
    NSMutableAttributedString *buffer = [[NSMutableAttributedString alloc] initWithAttributedString:prefixString];
    if (infixString) [buffer appendAttributedString:infixString];
    if (postfixString) [buffer appendAttributedString:postfixString];
    self.attributedText = buffer;
    if (shouldRestore && range.length == [infixString length]) {
        // If the replacement text and the original text are the same length, restore the insertion cursor to its
        //  original position.
        self.selectedRange = originalSelectedRange;
    }
    self.transformInProgress = NO;
    if ([self.externalDelegate respondsToSelector:@selector(textView:didChangeAttributedTextTo:originalText:originalRange:)]) {
        [self.externalDelegate textView:self didChangeAttributedTextTo:infixString originalText:originalInfix originalRange:range];
    }
}

- (void)insertPlainText:(NSString *)text location:(NSUInteger)location {
    [self insertAttributedText:[[NSAttributedString alloc] initWithString:text attributes:self.typingAttributes]
                      location:location];
}

- (void)insertAttributedText:(NSAttributedString *)text location:(NSUInteger)location {
    if ([text length] == 0) return;
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(NSAttributedString *input) {
        return text;
    };
    [self transformTextAtRange:NSMakeRange(location, 0) withTransformer:transformer];
}

- (void)insertTextAttachment:(NSTextAttachment *)attachment location:(NSUInteger)location {
    if (!attachment) return;
    if ([self.attributedText length] == 0) {
        // Special case: text view text is empty; index is valid
        if (location == 0) self.attributedText = [NSAttributedString attributedStringWithAttachment:attachment];
        return;
    }
    if (location >= [self.attributedText length]) {
        location = [self.attributedText length] - 1;
    }
    [self insertAttributedText:[NSAttributedString attributedStringWithAttachment:attachment] location:location];
    if ([self.externalDelegate respondsToSelector:@selector(textView:didReceiveNewTextAttachment:)]) {
        [self.externalDelegate textView:self didReceiveNewTextAttachment:attachment];
    }
}

- (void)removeTextForRange:(NSRange)range {
    if ([self.attributedText length] == 0
        || range.location == NSNotFound
        || range.location >= [self.attributedText length]
        || range.length == 0) {
        return;
    }
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(NSAttributedString *input) {
        return (NSAttributedString *)nil;
    };
    [self transformTextAtRange:range withTransformer:transformer];
}


#pragma mark - API (attributes)

- (void)activateCustomAttributeWithName:(NSString *)name value:(id)value {
    if ([name length] == 0 || !value) {
        return;
    }
    self.customTypingAttributes[name] = value;
}

- (void)deactivateCustomAttributeWithName:(NSString *)name {
    if ([name length] == 0) {
        return;
    }
    [self.customTypingAttributes removeObjectForKey:name];
}

- (void)deactivateAllCustomAttributes {
    [self.customTypingAttributes removeAllObjects];
}

- (void)stripAttributeFromTextAtRange:(NSRange)range attributeName:(NSString *)attributeName {
    if (range.length == 0 || range.location == NSNotFound || [attributeName length] == 0) {
        return;
    }
    NSAttributedString *(^transformer)(NSAttributedString *) = ^(NSAttributedString *input) {
        NSMutableAttributedString *buffer = [input mutableCopy];
        [buffer removeAttribute:attributeName range:NSMakeRange(0, [input length])];
        return [buffer copy];
    };
    [self transformTextAtRange:range withTransformer:transformer];
}

- (void)transformTypingAttributesWithTransformer:(NSDictionary *(^)(NSDictionary *currentAttributes))transformer {
    if (!transformer) return;
    self.typingAttributes = transformer(self.typingAttributes);
}


#pragma mark - API (viewport)

- (CGRect)enterSingleLineViewportMode:(HKWViewportMode)mode captureTouches:(BOOL)shouldCaptureTouches {
    if (self.inSingleLineViewportMode) {
        return CGRectNull;
    }
    if (shouldCaptureTouches) {
        [self addSubview:self.touchCaptureOverlayView];
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

    UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:self.selectedRange.location];
    CGRect caretRect = [self caretRectForPosition:p];

    CGFloat offsetY;
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

    // Move the viewport to show only the relevant line
    self.viewportContentOffset = CGPointMake(self.contentOffset.x, offsetY);

    [self setContentOffset:self.viewportContentOffset animated:NO];

    self.inSingleLineViewportMode = YES;
    self.showsVerticalScrollIndicator = NO;
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidEnterSingleLineViewportMode:)]) {
        [self.externalDelegate textViewDidEnterSingleLineViewportMode:self];
    }
    return viewportRect;
}

- (CGRect)rectForSingleLineViewportInMode:(HKWViewportMode)mode {
    UITextPosition *p = [self positionFromPosition:self.beginningOfDocument offset:self.selectedRange.location];
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
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidExitSingleLineViewportMode:)]) {
        [self.externalDelegate textViewDidExitSingleLineViewportMode:self];
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
            NSAssert(count < 5000, @"Internal error: could not find superview of editor text view after maximum \
                     levels.");
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
}

- (void)detachAccessoryView:(UIView *)view {
    if (view != self.attachedAccessoryView) {
        return;
    }
    HKWLOG(@"Detaching accessory view...");
    self.attachedAccessoryView = nil;
    [view removeFromSuperview];
}

- (void)setTopLevelViewForAccessoryViewPositioning:(UIView *)view {
    self.customTopLevelView = view;
}

@end
