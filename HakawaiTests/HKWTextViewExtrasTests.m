//
//  HKWTextViewExtrasTests.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView+Extras.h"

SpecBegin(overrideAutocapitalization)

describe(@"autocapitalization overriding", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should override autocapitalization correctly", ^{
        textView.autocapitalizationType = UITextAutocapitalizationTypeSentences;
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeSentences);
        [textView overrideAutocapitalizationWith:UITextAutocapitalizationTypeAllCharacters];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeAllCharacters);
        [textView restoreOriginalAutocapitalization:NO];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeSentences);
    });

    it(@"should override autocapitalization correctly when the modes are the same", ^{
        textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeNone);
        [textView overrideAutocapitalizationWith:UITextAutocapitalizationTypeNone];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeNone);
        [textView restoreOriginalAutocapitalization:NO];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeNone);
    });

    it(@"should gracefully ignore spurious override calls", ^{
        textView.autocapitalizationType = UITextAutocapitalizationTypeWords;
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeWords);
        [textView overrideAutocapitalizationWith:UITextAutocapitalizationTypeAllCharacters];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeAllCharacters);
        [textView overrideAutocapitalizationWith:UITextAutocapitalizationTypeNone];
        // Prior call should be ignored
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeAllCharacters);
        [textView restoreOriginalAutocapitalization:NO];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeWords);
    });

    it(@"should gracefully ignore spurious restore calls", ^{
        textView.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeAllCharacters);
        [textView restoreOriginalAutocapitalization:NO];
        expect(textView.autocapitalizationType).to.equal(UITextAutocapitalizationTypeAllCharacters);
    });
});

SpecEnd

SpecBegin(overrideAutocorrection)

describe(@"autocorrection overriding", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should override autocorrection correctly", ^{
        textView.autocorrectionType = UITextAutocorrectionTypeDefault;
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
        [textView overrideAutocorrectionWith:UITextAutocorrectionTypeNo];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView restoreOriginalAutocorrection:NO];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
    });

    it(@"should override autocorrection correctly when the modes are the same", ^{
        textView.autocorrectionType = UITextAutocorrectionTypeNo;
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView overrideAutocorrectionWith:UITextAutocorrectionTypeNo];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView restoreOriginalAutocorrection:NO];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
    });

    it(@"should gracefully ignore spurious override calls", ^{
        textView.autocorrectionType = UITextAutocorrectionTypeYes;
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeYes);
        [textView overrideAutocorrectionWith:UITextAutocorrectionTypeDefault];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
        [textView overrideAutocorrectionWith:UITextAutocorrectionTypeNo];
        // Prior call should be ignored
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
        [textView restoreOriginalAutocorrection:NO];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeYes);
    });

    it(@"should gracefully ignore spurious restore calls", ^{
        textView.autocorrectionType = UITextAutocorrectionTypeYes;
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeYes);
        [textView restoreOriginalAutocorrection:NO];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeYes);
    });
});

SpecEnd

SpecBegin(overrideSpellCheck)

describe(@"spell check overriding", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should override spell check correctly", ^{
        textView.spellCheckingType = UITextSpellCheckingTypeDefault;
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeDefault);
        [textView overrideSpellCheckingWith:UITextSpellCheckingTypeNo];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeNo);
        [textView restoreOriginalSpellChecking:NO];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeDefault);
    });

    it(@"should override spell check correctly when the modes are the same", ^{
        textView.spellCheckingType = UITextSpellCheckingTypeNo;
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeNo);
        [textView overrideSpellCheckingWith:UITextSpellCheckingTypeNo];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeNo);
        [textView restoreOriginalSpellChecking:NO];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeNo);
    });

    it(@"should gracefully ignore spurious override calls", ^{
        textView.spellCheckingType = UITextSpellCheckingTypeYes;
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeYes);
        [textView overrideSpellCheckingWith:UITextSpellCheckingTypeDefault];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeDefault);
        [textView overrideSpellCheckingWith:UITextSpellCheckingTypeNo];
        // Prior call should be ignored
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeDefault);
        [textView restoreOriginalSpellChecking:NO];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeYes);
    });

    it(@"should gracefully ignore spurious restore calls", ^{
        textView.spellCheckingType = UITextSpellCheckingTypeYes;
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeYes);
        [textView restoreOriginalSpellChecking:NO];
        expect(textView.spellCheckingType).to.equal(UITextSpellCheckingTypeYes);
    });
});

SpecEnd
