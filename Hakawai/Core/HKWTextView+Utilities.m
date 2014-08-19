//
//  HKWTextView+Utilities.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWTextView+Utilities.h"

@interface HKWTextView ()
@property (nonatomic, readonly) BOOL inInsertionMode;
@end

@implementation HKWTextView (Utilities)

- (CGRect)rectForWordPrecedingCursor {
    if (!self.inInsertionMode || self.selectedRange.location == 0) {
        return CGRectNull;
    }
    // Get the bottom-most rect
    NSRange range = [self rangeForWordPrecedingCursor];
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
        if (selectionRect.rect.origin.y < lowestRect.origin.y && !rectIsDegenerate(selectionRect.rect)) {
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
    NSUInteger selectedLocation = self.selectedRange.location;
    NSCharacterSet *whitespaceNewlineSet = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    if (!self.inInsertionMode
        || selectedLocation == 0
        || [whitespaceNewlineSet characterIsMember:[self characterPrecedingLocation:selectedLocation]]) {
        return NSMakeRange(NSNotFound, 0);
    }
    // Walk backwards through the string to find the first delimiter.
    NSInteger location = 0;
    for (NSInteger i=selectedLocation - 1; i>=0; i--) {
        if (i > 0) {
            unichar c = [self.text characterAtIndex:i];
            if ([whitespaceNewlineSet characterIsMember:c]) {
                location = i + 1;
                break;
            }
        }
    }
    NSInteger length;
    if (selectedLocation == [self.text length]
        || [whitespaceNewlineSet characterIsMember:[self.text characterAtIndex:selectedLocation]]) {
        // We're at the end of a word, or the end of the text field in general
        length = selectedLocation - location;
    }
    else {
        // Walk forward through the string to find the end, or the next whitespace/newline
        NSInteger cursor = location;
        while (cursor < [self.text length]) {
            cursor++;
            if ([whitespaceNewlineSet characterIsMember:[self characterPrecedingLocation:cursor]]) {
                cursor--;
                break;
            }
        }
        length = cursor - location;
    }
    return NSMakeRange(location, length);
}

- (unichar)characterPrecedingLocation:(NSInteger)location {
    unichar character = (unichar)0;
    if (location > 0 && location <= [self.text length]) {
        character = [self.text characterAtIndex:(location - 1)];
    }
    return character;
}


#pragma mark - Utility methods

- (BOOL)inInsertionMode {
    return (self.selectedRange.length == 0);
}


#pragma mark - CGRect utility functions

/*!
 Return NO if and only if both size dimensions of the \c CGRect argument are nonzero.
 */
BOOL rectIsDegenerate(CGRect rect) {
    return (rect.size.width == 0 || rect.size.height == 0);
}

@end
