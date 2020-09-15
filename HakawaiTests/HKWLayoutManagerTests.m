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
                                              withinGlyphRange:(NSRange)glyphRange;
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
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinGlyphRange:range];
        expect(result).notTo.beNil();
    });
});

describe(@"long non-english languages", ^{
    __block HKWTextView *textView;
    __block HKWLayoutManager *layoutManager;
    NSString *baseString = @"«می‌شه منبعش رو هم بگین؟»"
""
"  احتمالا شما هم با این سؤال و سؤالات مشابه‌ش ذیل پست‌های لینکدین برخورد کردین. و خب به نظرم مطلب باید طوری باشه که اصلا این سؤالات پرسیده نشه"
""
 "   دلیل اصلی این پست اینه که می‌بینم بعضی دوستان اینفوگرافیک‌ها و آمارهایی رو به اشتراک می‌ذارن، بدون ذکر منبعش. وقتی هم که از منبع پرسیده می‌شه، یا جواب نمی‌دن و یا با ارجاع به یه منبع مبهم سؤال رو از سر باز می‌کنن"
""
    "ذکر منابع یه رفتار حرفه‌ایه که محدود به زمینه‌ی خاصی هم نیست. طرح، عکس، آمار و هر نوع محتوای دیگه‌ای رو اگر به اشتراک می‌ذاریم، منبعش رو هم باهاش همراه کنیم"
""
    "منبع علاوه بر اینکه کارکرد رعایت حق تولیدکننده محتوا رو داره، برای راستی‌آزمایی اطلاعات بسیار مهمه. اون‌هم در زمانه‌ای که انواع و اقسام اطلاعات جعلی و بی‌پایه پخش می‌شه"
    "آوردن منابع برای کسب اطلاعات بیشتر هم خیلی کاربردیه. مثلا ممکنه کسی به خود آمار و اعداد علاقه‌ای نداشته باشه، ولی کنجکاو باشه که روش تحقیق استفاده‌شده چی بوده"
""
    "پس بیایم بیش از اون‌که به فکر لایک و جذب مخاطب باشیم، حرفه‌ای رفتار کنیم و اطلاعات و محتوا رو با منبعش به اشتراک بذاریم"
""
    "#ذکر_منبع"
""
    "(منبع عکس هم سایت"
         "    9GAG)";

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
        layoutManager = (HKWLayoutManager *)textView.layoutManager;
    });

    it(@"should not crash with glyph range longer than character range", ^{
        NSRange glyphRange = NSMakeRange(1039, 121);
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinGlyphRange:glyphRange];
        expect(result).notTo.beNil();
    });

    it(@"should not crash with glyph range longer than character range 2", ^{
        NSRange glyphRange = NSMakeRange(800, 323);
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinGlyphRange:glyphRange];
        expect(result).notTo.beNil();
    });

    it(@"should not crash with glyph range shorter than character range", ^{
        NSRange glyphRange = NSMakeRange(605, 352);
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinGlyphRange:glyphRange];
        expect(result).notTo.beNil();
    });

    it(@"should not crash with glyph range shorter than character range 2", ^{
        NSRange glyphRange = NSMakeRange(0, 193);
        NSArray *result = [layoutManager roundedRectBackgroundAttributeTuplesInTextStorage:textView.textStorage withinGlyphRange:glyphRange];
        expect(result).notTo.beNil();
    });
});

SpecEnd
