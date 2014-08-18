//
//  HKWTextView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "_HKWTextView.h"

#import "HKWTextView+Plugins.h"

#import "HKWLayoutManager.h"

#import "HKWSimplePluginProtocol.h"
#import "HKWControlFlowPluginProtocol.h"

#import "_HKWPrivateConstants.h"

@interface HKWTextView () <UITextViewDelegate>

@property (nonatomic, strong) NSMutableDictionary *simplePlugins;
@property (nonatomic, strong) id<HKWControlFlowPluginProtocol>controlFlowPlugin;

@end

@implementation HKWTextView

#pragma mark - Lifecycle

- (instancetype)initWithFrame:(CGRect)frame {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        // iOS 7
        HKWLayoutManager *manager = [HKWLayoutManager new];
        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:CGSizeMake(frame.size.width, FLT_MAX)];
        container.widthTracksTextView = YES;
        container.heightTracksTextView = YES;
        [manager addTextContainer:container];
        NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
        [storage addLayoutManager:manager];

        self = [super initWithFrame:frame textContainer:container];
    }
    else {
        // iOS 6 fallback
        self = [super initWithFrame:frame];
    }
    if (self) {
        [self setup];
    }
    return self;
}

// Build custom text container if the consumer is using a XIB.
- (id)awakeAfterUsingCoder:(NSCoder *)aDecoder {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        // iOS 7
        HKWLayoutManager *manager = [HKWLayoutManager new];

        NSTextContainer *container = [[NSTextContainer alloc] initWithSize:self.textContainer.size];
        container.widthTracksTextView = self.textContainer.widthTracksTextView;
        container.heightTracksTextView = self.textContainer.heightTracksTextView;

        [manager addTextContainer:container];

        NSTextStorage *storage = [[NSTextStorage alloc] initWithAttributedString:self.attributedText];
        [storage addLayoutManager:manager];

        HKWTextView *replacement = [[[self class] alloc] initWithFrame:self.frame textContainer:container];
        replacement.font = self.font;
        replacement.clearsOnInsertion = NO;
        replacement.textAlignment = self.textAlignment;
        replacement.textColor = self.textColor;
        replacement.autocapitalizationType = self.autocapitalizationType;
        replacement.autocorrectionType = self.autocorrectionType;
        replacement.spellCheckingType = self.spellCheckingType;
        [replacement setup];
        return replacement;
    }
    // iOS 6 fallback
    [self setup];
    return self;
}

- (void)setup {
    self.delegate = self;
    self.temporarilyDisableDelegate = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;
}


#pragma mark - Plugin Handling

- (void)addSimplePlugin:(id<HKWSimplePluginProtocol>)plugin {
    if (!plugin) {
        return;
    }
    if ([plugin respondsToSelector:@selector(pluginSupportsSystemVersion:)]) {
        if (![plugin pluginSupportsSystemVersion:NSFoundationVersionNumber]) {
            return;
        }
    }
    else if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        HKWLOG(@"WARNING! Plug-in must opt in in order to support iOS 6.");
        return;
    }
    plugin.parentTextView = self;
    self.simplePlugins[[plugin pluginName]] = plugin;
}

- (void)removeSimplePluginNamed:(NSString *)name {
    if (!name) {
        return;
    }
    id<HKWSimplePluginProtocol>plugin = self.simplePlugins[name];
    plugin.parentTextView = nil;
    [self.simplePlugins removeObjectForKey:name];
}

- (void)registerControlFlowPlugin:(id<HKWControlFlowPluginProtocol>)plugin {
    if (!plugin) {
        self.controlFlowPlugin.parentTextView = nil;
    }
    if ([plugin respondsToSelector:@selector(pluginSupportsSystemVersion:)]) {
        if (![plugin pluginSupportsSystemVersion:NSFoundationVersionNumber]) {
            return;
        }
    }
    else if (NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        HKWLOG(@"WARNING! Plug-in must opt in in order to support iOS 6.");
        return;
    }
    self.controlFlowPlugin = plugin;
    plugin.parentTextView = self;
}


#pragma mark - Miscellaneous

- (void)layoutSubviews {
    [super layoutSubviews];
    // Position the tap view
    if (self.touchCaptureOverlayView.superview != nil) {
        // 'Fix' the tap capture view
        CGRect frame = self.touchCaptureOverlayView.frame;
        frame.origin.x = self.contentOffset.x;
        frame.origin.y = self.contentOffset.y;
        self.touchCaptureOverlayView.frame = frame;
    }
}

- (void)touchOverlayViewTapped:(UITapGestureRecognizer *)gestureRecognizer {
    // First, give the plug-in a chance to do something
    if ([self.controlFlowPlugin respondsToSelector:@selector(singleLineViewportTapped)]) {
        [self.controlFlowPlugin singleLineViewportTapped];
    }
    // Next, inform the delegate
    if ([self.externalDelegate respondsToSelector:@selector(textViewWasTappedInSingleLineViewportMode:)]) {
        [self.externalDelegate textViewWasTappedInSingleLineViewportMode:self];
    }
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (self.temporarilyDisableDelegate) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.controlFlowPlugin textViewShouldBeginEditing:textView];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textViewShouldBeginEditing:)]) {
        return [self.externalDelegate textViewShouldBeginEditing:textView];
    }
    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if (self.temporarilyDisableDelegate) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.controlFlowPlugin textViewDidBeginEditing:textView];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidBeginEditing:)]) {
        [self.externalDelegate textViewDidBeginEditing:textView];
    }
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    if (self.temporarilyDisableDelegate) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.controlFlowPlugin textViewShouldEndEditing:textView];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textViewShouldEndEditing:)]) {
        return [self.externalDelegate textViewShouldEndEditing:textView];
    }
    return YES;
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    if (self.temporarilyDisableDelegate) {
        return;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.controlFlowPlugin textViewDidEndEditing:textView];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textViewDidEndEditing:)]) {
        [self.externalDelegate textViewDidEndEditing:textView];
    }
}

- (BOOL)textView:(UITextView *)textView
shouldChangeTextInRange:(NSRange)range
 replacementText:(NSString *)replacementText {
    if (self.temporarilyDisableDelegate) {
        return YES;
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
    // Forward to external delegate
    if (!shouldUseCustomValue
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
    if (self.temporarilyDisableDelegate) {
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
    if (self.temporarilyDisableDelegate) {
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
        CGFloat newOffsetY;
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
        if (newOffsetY != self.viewportContentOffset.y) {
            self.viewportContentOffset = CGPointMake(self.viewportContentOffset.x, newOffsetY);
            [self setContentOffset:self.viewportContentOffset animated:NO];
            if ([self.controlFlowPlugin respondsToSelector:@selector(singleLineViewportChanged)]) {
                [self.controlFlowPlugin singleLineViewportChanged];
            }
        }
    }
}

- (BOOL)textView:(UITextView *)textView
shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment
         inRange:(NSRange)characterRange {
    if (self.temporarilyDisableDelegate) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithTextAttachment:inRange:)]) {
        return [self.controlFlowPlugin textView:textView
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
    if (self.temporarilyDisableDelegate) {
        return YES;
    }
    if ([self.controlFlowPlugin respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.controlFlowPlugin textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    // Forward to external delegate
    if ([self.externalDelegate respondsToSelector:@selector(textView:shouldInteractWithURL:inRange:)]) {
        return [self.externalDelegate textView:textView shouldInteractWithURL:URL inRange:characterRange];
    }
    return YES;
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

- (NSMutableDictionary *)simplePlugins {
    if (!_simplePlugins) {
        _simplePlugins = [NSMutableDictionary dictionary];
    }
    return _simplePlugins;
}

- (NSMutableDictionary *)customTypingAttributes {
    if (!_customTypingAttributes) {
        _customTypingAttributes = [NSMutableDictionary dictionary];
    }
    return _customTypingAttributes;
}

- (CGFloat)lineFragmentPadding {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
        // iOS 7
        return self.textContainer.lineFragmentPadding;
    }
    else {
        // iOS 6
        return self.contentInset.left;
    }
}

- (void)setFrame:(CGRect)frame {
    // Fix the size of the touch capture overlay view
    CGRect overlayFrame = self.touchCaptureOverlayView.frame;
    overlayFrame.size.width = frame.size.width;
    overlayFrame.size.height = frame.size.height;
    self.touchCaptureOverlayView.frame = overlayFrame;

    [super setFrame:frame];
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
        // Unfortunately, using a UIView and adding a gesture recognizer doesn't seem to work.
        UIControl *control = [[UIControl alloc] initWithFrame:self.bounds];
        control.backgroundColor = [UIColor clearColor];
        control.userInteractionEnabled = YES;
        [control addTarget:self action:@selector(touchOverlayViewTapped:) forControlEvents:UIControlEventTouchUpInside];
        _touchCaptureOverlayView = control;
    }
    return _touchCaptureOverlayView;
}

@end