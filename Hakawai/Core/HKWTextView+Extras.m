//
//  HKWTextView+Extras.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTextView+Extras.h"

#import "_HKWTextView.h"

@interface HKWTextView ()
@property (nonatomic, readonly) BOOL inInsertionMode;
@end

@implementation HKWTextView (Extras)

#pragma mark - API (word utilities)

- (CGRect)rectForWordPrecedingCursor {
    if (!self.inInsertionMode || self.selectedRange.location == 0) {
        return CGRectNull;
    }
    // Get the bottom-most rect
    NSRange range = [self rangeForWordPrecedingLocation:self.selectedRange.location searchToEnd:YES];
    UITextPosition *start = [self positionFromPosition:self.beginningOfDocument
                                                offset:range.location];
    UITextPosition *end = [self positionFromPosition:self.beginningOfDocument
                                              offset:range.location + range.length - 1];
    UITextRange *textRange = [self textRangeFromPosition:start toPosition:end];
    NSArray *rects = [self selectionRectsForRange:textRange];
    NSAssert([rects count] > 0, @"Internal error: no selection rects for range.");
    // Go through all the rects and find the one placed the lowest
    CGRect lowestRect = CGRectMake(0, FLT_MAX, 0, 0);
    BOOL gotAtLeastOneRect = NO;
    for (UITextSelectionRect *selectionRect in rects) {
        if (selectionRect.rect.origin.y < lowestRect.origin.y && !HKW_rectIsDegenerate(selectionRect.rect)) {
            lowestRect = selectionRect.rect;
            gotAtLeastOneRect = YES;
        }
    }
    if (!gotAtLeastOneRect) {
        return CGRectNull;
    }
    return lowestRect;
}

- (NSRange)rangeForWordPrecedingCursor {
    return [self rangeForWordPrecedingLocation:self.selectedRange.location searchToEnd:YES];
}

- (NSRange)rangeForWordPrecedingLocation:(NSInteger)location searchToEnd:(BOOL)toEnd {
    NSCharacterSet *whitespaceNewlineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (!self.inInsertionMode
        || location == 0
        || location > [self.text length]
        || [whitespaceNewlineSet characterIsMember:[self characterPrecedingLocation:location]]) {
        return NSMakeRange(NSNotFound, 0);
    }
    // Walk backwards through the string to find the first delimiter.
    NSInteger firstLocation = 0;
    for (NSInteger i=location - 1; i>=0; i--) {
        if (i > 0) {
            unichar c = [self.text characterAtIndex:i];
            if ([whitespaceNewlineSet characterIsMember:c]) {
                firstLocation = i + 1;
                break;
            }
        }
    }
    NSInteger length;
    if (location == [self.text length]
        || [whitespaceNewlineSet characterIsMember:[self.text characterAtIndex:location]]
        || !toEnd) {
        // We're at the end of a word, or the end of the text field in general
        length = location - firstLocation;
    }
    else {
        // Walk forward through the string to find the end, or the next whitespace/newline
        NSInteger cursor = firstLocation;
        while (cursor < [self.text length]) {
            cursor++;
            if ([whitespaceNewlineSet characterIsMember:[self characterPrecedingLocation:cursor]]) {
                cursor--;
                break;
            }
        }
        length = cursor - firstLocation;
    }
    return NSMakeRange(firstLocation, length);
}

- (unichar)characterPrecedingLocation:(NSInteger)location {
    unichar character = (unichar)0;
    if (location > 0 && location <= [self.text length]) {
        character = [self.text characterAtIndex:(location - 1)];
    }
    return character;
}

- (BOOL)inInsertionMode {
    return (self.selectedRange.length == 0);
}

/*!
 Return NO if and only if both size dimensions of the \c CGRect argument are nonzero.
 */
BOOL HKW_rectIsDegenerate(CGRect rect) {
    return (rect.size.width == 0 || rect.size.height == 0);
}

@end
