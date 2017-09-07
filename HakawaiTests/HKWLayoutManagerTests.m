//
//  HKWMLayoutManagerTests.m
//  Hakawai
//
//  Created by Matthew Schouest on 9/5/17.
//  Copyright (c) 2017 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView.h"
#import "_HKWLayoutManager.h"

@interface HKWLayoutManager ()
- (NSArray *)roundedRectBackgroundAttributeTuplesInTextStorage:(NSTextStorage *)textStorage
                                                   withinRange:(NSRange)range;
@end

SpecBegin(layoutManager)

describe(@"roundedRectBackgroundAttributeTuples method", ^{
    __block HKWTextView *textView;
    __block HKWLayoutManager *layoutManager;
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
        layoutManager = (HKWLayoutManager *)textView.layoutManager;
    });

    it(@"should not crash with with invalid ranges", ^{
        NSRange range = NSMakeRange(0, 100);
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinRange:range];
        expect(result).notTo.beNil();
    });
    

});

SpecEnd
