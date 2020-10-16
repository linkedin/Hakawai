//
//  HKWTextViewTextTransformerTests.m
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

#import "HKWTextView+TextTransformation.h"

SpecBegin(transformTextAtRange)

describe(@"transformTextAtRange with plain text", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly transform text at beginning", ^{
        [textView transformTextAtRange:NSMakeRange(0, 3) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"#### TEST ####"];
        }];
        expect(textView.text).to.equal(@"#### TEST #### quick brown fox jumps over the lazy dog");
    });

    it(@"should properly transform text in middle", ^{
        [textView transformTextAtRange:NSMakeRange(5, 12) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"blah_string"];
        }];
        expect(textView.text).to.equal(@"The qblah_stringox jumps over the lazy dog");
    });

    it(@"should properly transform text at end", ^{
        [textView transformTextAtRange:NSMakeRange(31, 12) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"a fat bear"];
        }];
        expect(textView.text).to.equal(@"The quick brown fox jumps over a fat bear");
    });

    it(@"should properly ignore ranges whose beginnings are out of range", ^{
        [textView transformTextAtRange:NSMakeRange(9999, 1000) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"~~~~ !!!! ~~~~"];
        }];
        expect(textView.text).to.equal(baseString);
    });

    it(@"should properly trim ranges whose ends are out of range", ^{
        [textView transformTextAtRange:NSMakeRange(10, 1000) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"~~~~ !!!! ~~~~"];
        }];
        expect(textView.text).to.equal(@"The quick ~~~~ !!!! ~~~~");
    });

    it(@"should properly add text to an empty text view", ^{
        textView.text = @"";
        expect(textView.text).to.equal(@"");
        [textView transformTextAtRange:NSMakeRange(0, 1) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:baseString];
        }];
        expect(textView.text).to.equal(baseString);
    });

    it(@"should properly handle an empty string for transformed text", ^{
        [textView transformTextAtRange:NSMakeRange(0, 11) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return nil;
        }];
        expect(textView.text).to.equal(@"rown fox jumps over the lazy dog");
    });

    it(@"should properly ignore a nil block", ^{
        [textView transformTextAtRange:NSMakeRange(0, 11) withTransformer:nil];
        expect(textView.text).to.equal(baseString);
    });
});

describe(@"transformTextAtRange with attributed text", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    NSString *replacementString = @"## TEST ##";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly add attribute", ^{
        // Text view starts with unstyled text
        textView.attributedText = [[NSMutableAttributedString alloc] initWithString:baseString];
        NSUInteger location = 1;
        NSUInteger length = 12;
        [textView transformTextAtRange:NSMakeRange(location, length) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:replacementString
                                                                         attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
            return buffer;
        }];
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *fColor = [textView.attributedText attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:NULL];
            if (i >= location && i < location + [replacementString length]) {
                expect(fColor).to.equal([UIColor redColor]);
            }
            else {
                expect(fColor).to.beNil;
            }
        }
    });

    it(@"should properly overwrite attribute", ^{
        // Text view starts with green text
        textView.attributedText = [[NSMutableAttributedString alloc] initWithString:baseString
                                                                         attributes:@{NSForegroundColorAttributeName: [UIColor greenColor]}];
        NSUInteger location = 1;
        NSUInteger length = 12;
        [textView transformTextAtRange:NSMakeRange(location, length) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:replacementString
                                                                         attributes:@{NSForegroundColorAttributeName: [UIColor redColor]}];
            return buffer;
        }];
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *fColor = [textView.attributedText attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:NULL];
            UIColor *expectColor = (i >= location && i < location + [replacementString length]) ? [UIColor redColor] : [UIColor greenColor];
            expect(fColor).to.equal(expectColor);
        }
    });

    it(@"should properly remove attribute", ^{
        // Text view starts with green text
        textView.attributedText = [[NSMutableAttributedString alloc] initWithString:baseString
                                                                         attributes:@{NSForegroundColorAttributeName: [UIColor greenColor]}];
        NSUInteger location = 1;
        NSUInteger length = 12;
        [textView transformTextAtRange:NSMakeRange(location, length) withTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:replacementString];
        }];
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *fColor = [textView.attributedText attribute:NSForegroundColorAttributeName atIndex:i effectiveRange:NULL];
            if (i >= location && i < location + [replacementString length]) {
                expect(fColor).to.beNil;
            }
            else {
                expect(fColor).to.equal([UIColor greenColor]);
            }
        }
    });
});

SpecEnd

SpecBegin(transformSelectedTextWithTransformer)

describe(@"transformSelectedTextWithTransformer", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly transform selected text with a nonzero selection length", ^{
        textView.selectedRange = NSMakeRange(0, 3);
        [textView transformSelectedTextWithTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"#### TEST ####"];
        }];
        expect(textView.text).to.equal(@"#### TEST #### quick brown fox jumps over the lazy dog");
    });

    it(@"should properly transform selected text with a zero selection length", ^{
        textView.selectedRange = NSMakeRange(4, 0);
        [textView transformSelectedTextWithTransformer:^NSAttributedString *(__unused NSAttributedString *s) {
            return [[NSAttributedString alloc] initWithString:@"#### TEST ####"];
        }];
        expect(textView.text).to.equal(@"The #### TEST ####quick brown fox jumps over the lazy dog");
    });
});

SpecEnd

SpecBegin(insertPlainText)

describe(@"insertPlainText", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly insert text at beginning", ^{
        [textView insertPlainText:@"1234567890" location:0];
        expect(textView.text).to.equal(@"1234567890The quick brown fox jumps over the lazy dog");
    });

    it(@"should properly insert text in the middle", ^{
        [textView insertPlainText:@"HELLO_WORLD" location:4];
        expect(textView.text).to.equal(@"The HELLO_WORLDquick brown fox jumps over the lazy dog");
    });

    it(@"should properly insert text at end", ^{
        [textView insertPlainText:@"*^*^*^*^*^" location:43];
        expect(textView.text).to.equal(@"The quick brown fox jumps over the lazy dog*^*^*^*^*^");
    });
});

SpecEnd

SpecBegin(insertAttributedText)

describe(@"insertAttributedText", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;
    NSAttributedString *insertString = [[NSAttributedString alloc] initWithString:@"1234567890"
                                                                       attributes:@{NSBackgroundColorAttributeName: [UIColor purpleColor]}];

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly insert attributed text at beginning", ^{
        NSUInteger location = 0;
        [textView insertAttributedText:insertString location:location];
        expect(textView.text).to.equal(@"1234567890The quick brown fox jumps over the lazy dog");
        
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *bgColor = [textView.attributedText attribute:NSBackgroundColorAttributeName atIndex:i effectiveRange:NULL];
            if (i >= location && i < location + [insertString length]) {
                expect(bgColor).to.equal([UIColor purpleColor]);
            }
            else {
                expect(bgColor).to.beNil;
            }
        }
    });

    it(@"should properly insert text in the middle", ^{
        NSUInteger location = 4;
        [textView insertAttributedText:insertString location:location];
        expect(textView.text).to.equal(@"The 1234567890quick brown fox jumps over the lazy dog");
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *bgColor = [textView.attributedText attribute:NSBackgroundColorAttributeName atIndex:i effectiveRange:NULL];
            if (i >= location && i < location + [insertString length]) {
                expect(bgColor).to.equal([UIColor purpleColor]);
            }
            else {
                expect(bgColor).to.beNil;
            }
        }
    });

    it(@"should properly insert text at end", ^{
        NSUInteger location = 43;
        [textView insertAttributedText:insertString location:location];
        expect(textView.text).to.equal(@"The quick brown fox jumps over the lazy dog1234567890");
        for (NSUInteger i=0; i<[textView.attributedText length]; i++) {
            UIColor *bgColor = [textView.attributedText attribute:NSBackgroundColorAttributeName atIndex:i effectiveRange:NULL];
            if (i >= location && i <= location + [insertString length]) {
                expect(bgColor).to.equal([UIColor purpleColor]);
            }
            else {
                expect(bgColor).to.beNil;
            }
        }
    });
});

SpecEnd

SpecBegin(insertTextAttachment)

describe(@"insertTextAttachment", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;
    // Create an image programmatically
    CGRect imageRect = CGRectMake(0, 0, 200, 200);
    UIGraphicsBeginImageContext(imageRect.size);
    CGContextRef c = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(c, [[UIColor yellowColor] CGColor]);
    CGContextFillRect(c, imageRect);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    NSTextAttachment *attachment = [NSTextAttachment new];
    attachment.image = img;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly insert a text attachment", ^{
        [textView insertTextAttachment:attachment location:11];
        id object = [textView.attributedText attribute:NSAttachmentAttributeName atIndex:11 effectiveRange:NULL];
        expect(object).to.equal(attachment);
    });

    it(@"should properly ignore a nil text attachment", ^{
        [textView insertTextAttachment:nil location:11];
        id object = [textView.attributedText attribute:NSAttachmentAttributeName atIndex:11 effectiveRange:NULL];
        expect(textView.text).to.equal(baseString);
        expect(object).to.beNil;
    });

    it(@"should properly ignore an invalid location", ^{
        [textView insertTextAttachment:nil location:100000];
        expect(textView.text).to.equal(baseString);
    });
});

SpecEnd

SpecBegin(removeTextForRange)

describe(@"removeTextForRange", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly remove text at beginning", ^{
        [textView removeTextForRange:NSMakeRange(0, 2)];
        expect(textView.text).to.equal(@"e quick brown fox jumps over the lazy dog");
    });

    it(@"should properly remove text in the middle", ^{
        [textView removeTextForRange:NSMakeRange(5, 7)];
        expect(textView.text).to.equal(@"The qown fox jumps over the lazy dog");
    });

    it(@"should properly remove text at end", ^{
        [textView removeTextForRange:NSMakeRange(31, 12)];
        expect(textView.text).to.equal(@"The quick brown fox jumps over ");
    });

    it(@"should properly remove text for a zero-length range", ^{
        [textView removeTextForRange:NSMakeRange(30, 0)];
        expect(textView.text).to.equal(baseString);
    });

    it(@"should properly handle an empty text view", ^{
        textView.text = @"";
        expect(textView.text).to.equal(@"");
        [textView removeTextForRange:NSMakeRange(0, 1)];
        expect(textView.text).to.equal(@"");
    });
});

SpecEnd
