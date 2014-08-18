//
//  HKWTextView+Extras.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWTextView+Extras.h"

#import "_HKWTextView.h"

typedef enum {
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
} HKWCycleFirstResponderMode;

@implementation HKWTextView (Extras)

- (void)dismissAutocorrectSuggestion {
    [self cycleFirstResponderStatusWithMode:HKWCycleFirstResponderModeNone
                            cancelAnimation:YES];
}

- (void)overrideAutocapitalizationWith:(UITextAutocapitalizationType)override {
    if (self.overridingAutocapitalization) {
        return;
    }
    self.overridingAutocapitalization = YES;
    self.originalAutocapitalization = self.autocapitalizationType;
    [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocapitalization:override]
                            cancelAnimation:YES];
}

- (void)restoreOriginalAutocapitalization:(BOOL)shouldCycle {
    if (!self.overridingAutocapitalization) {
        return;
    }
    if (shouldCycle) {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocapitalization:self.originalAutocapitalization]
                                cancelAnimation:YES];
    }
    else {
        self.autocapitalizationType = self.originalAutocapitalization;
    }
    self.overridingSpellChecking = NO;
}

- (void)overrideAutocorrectionWith:(UITextAutocorrectionType)override {
    if (self.overridingAutocorrection) {
        return;
    }
    self.overridingAutocorrection = YES;
    self.originalAutocorrection = self.autocorrectionType;
    [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocorrection:override]
                            cancelAnimation:YES];
}

- (void)restoreOriginalAutocorrection:(BOOL)shouldCycle {
    if (!self.overridingAutocorrection) {
        return;
    }
    if (shouldCycle) {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForAutocorrection:self.originalAutocorrection]
                                cancelAnimation:YES];
    }
    else {
        self.autocorrectionType = self.originalAutocorrection;
    }
    self.overridingAutocorrection = NO;
}

- (void)overrideSpellCheckingWith:(UITextSpellCheckingType)override {
    if (self.overridingSpellChecking) {
        return;
    }
    self.overridingSpellChecking = YES;
    self.originalSpellChecking = self.spellCheckingType;
    [self cycleFirstResponderStatusWithMode:[HKWTextView modeForSpellChecking:override]
                            cancelAnimation:YES];
}

- (void)restoreOriginalSpellChecking:(BOOL)shouldCycle {
    if (!self.overridingSpellChecking) {
        return;
    }
    if (shouldCycle) {
        [self cycleFirstResponderStatusWithMode:[HKWTextView modeForSpellChecking:self.originalSpellChecking]
                                cancelAnimation:YES];
    }
    else {
        self.spellCheckingType = self.originalSpellChecking;
    }
    self.overridingSpellChecking = NO;
}


#pragma mark - Private

- (void)cycleFirstResponderStatusWithMode:(HKWCycleFirstResponderMode)mode cancelAnimation:(BOOL)cancelAnimation {
    NSRange originalRange = self.selectedRange;
    NSAttributedString *originalText = [self.attributedText copy];

    self.temporarilyDisableDelegate = YES;
    [self resignFirstResponder];

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
    self.attributedText = originalText;
    self.selectedRange = originalRange;
    self.temporarilyDisableDelegate = NO;
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
