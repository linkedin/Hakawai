//
//  HKWTextViewSingleLineViewportModeTests.m
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

#import "HKWTextView+Plugins.h"

SpecBegin(singleLineViewport)

describe(@"single line viewport API", ^{
    // Note: changing either the base string or the size of the text view will require the tests to be updated.
    NSString *baseString = @"This is a very long piece of text. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long. \
    It is very long. It is very long. It is very long. It is very long. It is very long. It is very long.";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.text = baseString;
    });

    it(@"should properly register entering and exiting single viewport mode", ^{
        expect(textView.inSingleLineViewportMode).to.beFalsy;
        [textView enterSingleLineViewportMode:HKWViewportModeTop captureTouches:NO];
        expect(textView.inSingleLineViewportMode).to.beTruthy;
        [textView exitSingleLineViewportMode];
        expect(textView.inSingleLineViewportMode).to.beFalsy;
    });

    it(@"should properly move the viewport in top mode", ^{
        textView.contentOffset = CGPointMake(0, 30);
        expect(textView.contentOffset.x).to.equal(0);
        expect(textView.contentOffset.y).to.equal(30);
        [textView enterSingleLineViewportMode:HKWViewportModeTop captureTouches:NO];
        expect(textView.contentOffset.x).to.equal(0);
        expect(round(textView.contentOffset.y)).to.equal(3300);
        [textView exitSingleLineViewportMode];
        expect(textView.contentOffset.x).to.equal(0);
        expect(textView.contentOffset.y).to.equal(30);
    });

    it(@"should properly move the viewport in bottom mode", ^{
        textView.contentOffset = CGPointMake(0, 30);
        expect(textView.contentOffset.x).to.equal(0);
        expect(textView.contentOffset.y).to.equal(30);
        [textView enterSingleLineViewportMode:HKWViewportModeBottom captureTouches:NO];
        expect(textView.contentOffset.x).to.equal(0);
        expect(textView.contentOffset.y).to.equal(3226);
        [textView exitSingleLineViewportMode];
        expect(textView.contentOffset.x).to.equal(0);
        expect(textView.contentOffset.y).to.equal(30);
    });
});

SpecEnd