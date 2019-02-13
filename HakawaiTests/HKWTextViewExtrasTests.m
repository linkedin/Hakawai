//
//  HKWTextViewExtrasTests.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView+Extras.h"

SpecBegin(rangeForWordPrecedingCursor)

describe(@"rangeForWordPrecedingCursor", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly return ranges for a valid word ('The') preceding the cursor", ^{
        textView.selectedRange = NSMakeRange(3, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(3);
        expect(r.location).to.equal(0);
    });

    it(@"should properly return ranges for a valid word ('brown') preceding the cursor", ^{
        textView.selectedRange = NSMakeRange(15, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(5);
        expect(r.location).to.equal(10);
    });

    it(@"should properly return ranges for a valid word ('dog') preceding the cursor", ^{
        textView.selectedRange = NSMakeRange(43, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(3);
        expect(r.location).to.equal(40);
    });

    it(@"should properly return ranges when the cursor is in the middle of a word at the beginning of the text view", ^{
        textView.selectedRange = NSMakeRange(1, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(3);
        expect(r.location).to.equal(0);
    });

    it(@"should properly return ranges when the cursor is in the middle of a word in the middle of the text view", ^{
        textView.selectedRange = NSMakeRange(6, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(5);
        expect(r.location).to.equal(4);
    });

    it(@"should properly return ranges when the cursor is in the middle of a word at the end of the text view", ^{
        textView.selectedRange = NSMakeRange(41, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.length).to.equal(3);
        expect(r.location).to.equal(40);
    });

    it(@"should properly return NSNotFound when the cursor is at the beginning", ^{
        textView.selectedRange = NSMakeRange(0, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.location).to.equal(NSNotFound);
    });

    it(@"should properly return NSNotFound when there are no words preceding the cursor (1)", ^{
        textView.text = @"     ";
        textView.selectedRange = NSMakeRange(0, 3);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.location).to.equal(NSNotFound);
    });

    it(@"should properly return NSNotFound when there are no words preceding the cursor (2)", ^{
        textView.text = @"     ";
        textView.selectedRange = NSMakeRange(0, 3);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.location).to.equal(NSNotFound);
    });

    it(@"should properly return NSNotFound when the cursor is before a whitespace", ^{
        textView.selectedRange = NSMakeRange(4, 0);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.location).to.equal(NSNotFound);
    });

    it(@"should properly return NSNotFound when the cursor is not in insertion mode", ^{
        textView.selectedRange = NSMakeRange(3, 10);
        NSRange r = [textView rangeForWordPrecedingCursor];
        expect(r.location).to.equal(NSNotFound);
    });
});

SpecEnd

SpecBegin(characterPrecedingLocation)

describe(@"characterPrecedingLocation", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly return the character preceding a location", ^{
        unichar character = [textView characterPrecedingLocation:7];
        expect(character).to.equal('i');
    });

    it(@"should properly return 0 when location = 0", ^{
        unichar character = [textView characterPrecedingLocation:0];
        expect(character).to.equal((unichar)0);
    });

    it(@"should properly return 0 when location is negative", ^{
        unichar character = [textView characterPrecedingLocation:-10];
        expect(character).to.equal((unichar)0);
    });

    it(@"should properly return 0 when location is just out of range", ^{
        unichar character = [textView characterPrecedingLocation:(NSInteger)[baseString length] + 1];
        expect(character).to.equal((unichar)0);
    });

    it(@"should properly return 0 when location is out of range", ^{
        unichar character = [textView characterPrecedingLocation:1000];
        expect(character).to.equal((unichar)0);
    });
});

SpecEnd
