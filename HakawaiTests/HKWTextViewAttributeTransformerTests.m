//
//  HKWTextViewAttributeTransformerTests.m
//  Hakawai
//
//  Created by Austin Zheng on 8/19/14.
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#define EXP_SHORTHAND

#ifdef HKW_FULL_RANGE
#define HKWT_FULL_RANGE HKW_FULL_RANGE
#else
#define HKWT_FULL_RANGE(__x__) NSMakeRange(0, [__x__ length])
#endif

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView+TextTransformation.h"

@interface HKWTextView ()
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText;
@end

SpecBegin(customAttributes)

describe(@"customAttributes API", ^{
    NSString *c1 = @"CustomAttribute1Name";
    NSString *c2 = @"CustomAttribute2Name";
    NSString *c3 = @"CustomAttribute3Name";
    NSString *replacement = @"The quick brown fox jumps over the lazy dog";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly add a custom attribute", ^{
        id customValue = [UIColor orangeColor];
        [textView activateCustomAttributeWithName:c1 value:customValue];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:replacement];
        // Now check to see if the attribute was added
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            expect(value).to.equal(customValue);
        }
        // Now move the cursor and insert some more text
        NSUInteger newLocation = [textView.text length];
        textView.selectedRange = NSMakeRange(newLocation, 0);
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(newLocation, 0) replacementText:replacement];
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            expect(value).to.equal(customValue);
        }
    });

    it(@"should properly remove a custom attribute", ^{
        id customValue = [UIColor grayColor];
        [textView activateCustomAttributeWithName:c1 value:customValue];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:replacement];
        // Now check to see if the attribute was added
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            expect(value).to.equal(customValue);
        }
        // Now move the cursor, deactivate the custom attribute, and insert some more text
        NSUInteger newLocation = [textView.text length];
        [textView deactivateCustomAttributeWithName:c1];
        textView.selectedRange = NSMakeRange(newLocation, 0);
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(newLocation, 0) replacementText:replacement];
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            if (i < [replacement length]) {
                // Only the first half of the string should have the custom value
                expect(value).to.equal(customValue);
            }
            else {
                expect(value).to.beNil;
            }
        }
    });

    it(@"should properly remove all custom attributes when asked", ^{
        id cv1 = @"cv1";
        id cv2 = @"cv2";
        id cv3 = @"cv3";
        [textView activateCustomAttributeWithName:c1 value:cv1];
        [textView activateCustomAttributeWithName:c2 value:cv2];
        [textView activateCustomAttributeWithName:c3 value:cv3];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:replacement];
        // Now check to see if the attributes were added
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value1 = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            id value2 = [textView.attributedText attribute:c2 atIndex:i effectiveRange:NULL];
            id value3 = [textView.attributedText attribute:c3 atIndex:i effectiveRange:NULL];
            expect(value1).to.equal(cv1);
            expect(value2).to.equal(cv2);
            expect(value3).to.equal(cv3);
        }
        // Now move the cursor, deactivate all custom attributes, and insert some more text
        NSUInteger newLocation = [textView.text length];
        [textView deactivateAllCustomAttributes];
        textView.selectedRange = NSMakeRange(newLocation, 0);
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(newLocation, 0) replacementText:replacement];
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value1 = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            id value2 = [textView.attributedText attribute:c2 atIndex:i effectiveRange:NULL];
            id value3 = [textView.attributedText attribute:c3 atIndex:i effectiveRange:NULL];
            if (i < [replacement length]) {
                // Only the first half of the string should have the custom value
                expect(value1).to.equal(cv1);
                expect(value2).to.equal(cv2);
                expect(value3).to.equal(cv3);
            }
            else {
                expect(value1).to.beNil;
                expect(value2).to.beNil;
                expect(value3).to.beNil;
            }
        }
    });

    it(@"should properly ignore trying to add attribute with nil name", ^{
        [textView activateCustomAttributeWithName:nil value:[UIColor greenColor]];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:replacement];
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            expect(value).to.beNil;
        }
    });

    it(@"should properly ignore trying to remove nil attributes", ^{
        [textView activateCustomAttributeWithName:c1 value:nil];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:replacement];
        for (NSUInteger i=0; i<[textView.text length]; i++) {
            id value = [textView.attributedText attribute:c1 atIndex:i effectiveRange:NULL];
            expect(value).to.beNil;
        }
    });
});

SpecEnd

SpecBegin(stripAttributeFromTextAtRange)

describe(@"stripAttributeFromTextAtRange API", ^{
    NSString *baseString = @"The quick brown fox jumps over the lazy dog";
    NSUInteger baseLength = [baseString length];
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly strip an attribute from text", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString
                                                                  attributes:@{attributeName: attributeValue}];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            expect(observedValue).to.equal(attributeValue);
        }
        // Strip the attribute
        [textView stripAttributeFromTextAtRange:HKWT_FULL_RANGE(textView.attributedText) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            expect(observedValue).to.beNil;
        }
    });

    it(@"should properly strip an attribute partially present in text", ^{
        // This tests the case where the range provided is greater than the actual attribute range
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSUInteger attrLocation = 5;
        NSUInteger attrLength = 8;

        NSMutableAttributedString *buffer = [[NSMutableAttributedString alloc] initWithString:baseString];
        [buffer addAttribute:attributeName value:attributeValue range:NSMakeRange(attrLocation, attrLength)];
        textView.attributedText = buffer;

        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            if (i >= attrLocation && i < attrLocation + attrLength) {
                expect(observedValue).to.equal(attributeValue);
            }
            else {
                expect(observedValue).to.equal(nil);
            }
        }
        // Strip the attribute
        [textView stripAttributeFromTextAtRange:HKWT_FULL_RANGE(textView.attributedText) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            expect(observedValue).to.beNil;
        }
    });

    it(@"should properly strip attribute from part of a piece of text", ^{
        // This tests the case where the range provided is smaller than the actual attribute range
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString
                                                                  attributes:@{attributeName: attributeValue}];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            expect(observedValue).to.equal(attributeValue);
        }
        // Strip the attribute
        NSUInteger stripLocation = 5;
        NSUInteger stripLength = 8;
        [textView stripAttributeFromTextAtRange:NSMakeRange(stripLocation, stripLength) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            if (i >= stripLocation && i < stripLocation + stripLength) {
                expect(observedValue).to.equal(nil);
            }
            else {
                expect(observedValue).to.equal(attributeValue);
            }
        }
    });

    it(@"should properly ignore stripping a not-present attribute", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:baseString
                                                                     attributes:@{attributeName: attributeValue}];
        textView.attributedText = buffer;
        buffer = textView.attributedText;
        [textView stripAttributeFromTextAtRange:HKWT_FULL_RANGE(buffer) attributeName:NSStrikethroughColorAttributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            NSDictionary *attrs = [textView.attributedText attributesAtIndex:i effectiveRange:NULL];
            NSDictionary *baseAttrs = [buffer attributesAtIndex:i effectiveRange:NULL];
            expect(attrs).to.equal(baseAttrs);
        }
    });

    it(@"should properly ignore stripping a nil attribute", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:baseString
                                                                     attributes:@{attributeName: attributeValue}];
        textView.attributedText = buffer;
        buffer = textView.attributedText;
        [textView stripAttributeFromTextAtRange:HKWT_FULL_RANGE(buffer) attributeName:nil];
        for (NSUInteger i=0; i<baseLength; i++) {
            NSDictionary *attrs = [textView.attributedText attributesAtIndex:i effectiveRange:NULL];
            NSDictionary *baseAttrs = [buffer attributesAtIndex:i effectiveRange:NULL];
            expect(attrs).to.equal(baseAttrs);
        }
    });

    it(@"should properly ignore an invalid range", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:baseString
                                                                     attributes:@{attributeName: attributeValue}];
        textView.attributedText = buffer;
        buffer = textView.attributedText;
        [textView stripAttributeFromTextAtRange:NSMakeRange(10000, 5) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            NSDictionary *attrs = [textView.attributedText attributesAtIndex:i effectiveRange:NULL];
            NSDictionary *baseAttrs = [buffer attributesAtIndex:i effectiveRange:NULL];
            expect(attrs).to.equal(baseAttrs);
        }
    });

    it(@"should properly handle a zero-length range", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:baseString
                                                                     attributes:@{attributeName: attributeValue}];
        textView.attributedText = buffer;
        buffer = textView.attributedText;
        [textView stripAttributeFromTextAtRange:NSMakeRange(3, 0) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            NSDictionary *attrs = [textView.attributedText attributesAtIndex:i effectiveRange:NULL];
            NSDictionary *baseAttrs = [buffer attributesAtIndex:i effectiveRange:NULL];
            expect(attrs).to.equal(baseAttrs);
        }
    });

    it(@"should properly handle a too-long range", ^{
        NSString *attributeName = NSForegroundColorAttributeName;
        id attributeValue = [UIColor greenColor];
        NSAttributedString *buffer = [[NSAttributedString alloc] initWithString:baseString
                                                                     attributes:@{attributeName: attributeValue}];
        textView.attributedText = buffer;
        buffer = textView.attributedText;
        [textView stripAttributeFromTextAtRange:NSMakeRange(0, 5000) attributeName:attributeName];
        for (NSUInteger i=0; i<baseLength; i++) {
            id observedValue = [textView.attributedText attribute:attributeName atIndex:i effectiveRange:NULL];
            expect(observedValue).to.beNil;
        }
    });
});

SpecEnd

SpecBegin(transformTypingAttributes)

describe(@"transformTypingAttributesWithTransformer API", ^{
    NSString *baseString = @"0123456789";
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        textView.attributedText = [[NSAttributedString alloc] initWithString:baseString];
    });

    it(@"should properly transform typing attributes", ^{
        UIFont *const font = [UIFont fontWithName:@"Helvetica" size:10];
        if (!font) {
            expect(font).notTo.beNil();
        }
        NSDictionary *old = @{NSBackgroundColorAttributeName: [UIColor greenColor],
                              NSFontAttributeName: font};
        NSDictionary *new = @{NSForegroundColorAttributeName: [UIColor blueColor],
                              NSBackgroundColorAttributeName: [UIColor redColor]};
        textView.selectedRange = NSMakeRange(0, 0);
        textView.typingAttributes = old;
        expect(textView.typingAttributes).to.equal(old);
        [textView transformTypingAttributesWithTransformer:^NSDictionary *(__unused NSDictionary *currentAttributes) {
            return new;
        }];
        expect(textView.typingAttributes).to.equal(new);
    });

    it(@"should properly ignore a nil transformer block", ^{
        UIFont *const font = [UIFont fontWithName:@"Helvetica" size:10];
        if (!font) {
            expect(font).notTo.beNil();
        }
        NSDictionary *old = @{NSBackgroundColorAttributeName: [UIColor greenColor],
                              NSFontAttributeName: font};
        textView.selectedRange = NSMakeRange(0, 0);
        textView.typingAttributes = old;
        expect(textView.typingAttributes).to.equal(old);
        [textView transformTypingAttributesWithTransformer:nil];
        expect(textView.typingAttributes).to.equal(old);
    });
});

SpecEnd
