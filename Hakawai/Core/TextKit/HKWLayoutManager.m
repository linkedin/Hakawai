//
//  HKWLayoutManager.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWLayoutManager.h"

#import "HKWCustomAttributes.h"

typedef NSArray RoundedRectAttributeTuple;
typedef NSMutableArray RangeValuesBuffer;
typedef NSMutableArray RectValuesBuffer;

@interface HKWLayoutManager ()
@property (nonatomic, readonly) CGFloat cornerRadius;
@property (nonatomic, readonly) CGFloat additionalHeight;
@end

@implementation HKWLayoutManager

- (void)drawGlyphsForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    [super drawGlyphsForGlyphRange:glyphsToShow atPoint:origin];
    // Here to be overriden if necessary
}

- (void)drawBackgroundForGlyphRange:(NSRange)glyphsToShow atPoint:(CGPoint)origin {
    [super drawBackgroundForGlyphRange:glyphsToShow atPoint:origin];

    // -------------------------------------------------------------------------------------------------------------- //
    // Handle drawing background for the new rounded rect background attribute.
    NSArray *tuples = [self roundedRectBackgroundAttributeTuplesInTextStorage:self.textStorage
                                                             withinGlyphRange:glyphsToShow];
    NSArray *roundedRectBackgroundRectArrays = [self rectArraysForRoundedRectBackgroundAttributeTuples:tuples
                                                                                       inTextContainer:self.textContainers[0]];
    if ([roundedRectBackgroundRectArrays count] == 0) {
        return;
    }

    NSAssert([tuples count] == [roundedRectBackgroundRectArrays count],
             @"The number of tuples must always be equal to the number of rounded rect background rect arrays");

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    for (NSUInteger i=0; i<[tuples count]; i++) {
        HKWRoundedRectBackgroundAttributeValue *data = tuples[i][1];
        CGContextSetStrokeColorWithColor(context, [data.backgroundColor CGColor]);
        CGContextSetFillColorWithColor(context, [data.backgroundColor CGColor]);

        for (NSValue *value in roundedRectBackgroundRectArrays[i]) {
            CGRect unionRect = [value CGRectValue];
            // Adjust the rect to increase its padding, and to position it correctly
            unionRect.origin.x += origin.x;
            unionRect.origin.y += origin.y - ((CGFloat)0.5*self.additionalHeight);
            unionRect.size.height += self.additionalHeight;

            if (unionRect.size.width < 2*self.cornerRadius || unionRect.size.height < 2*self.cornerRadius) {
                continue;
            }

            CGPathRef p = CGPathCreateWithRoundedRect(unionRect, self.cornerRadius, self.cornerRadius, NULL);
            CGContextAddPath(context, p);
            CGContextStrokePath(context);
            CGPathRelease(p);
            p = CGPathCreateWithRoundedRect(unionRect, self.cornerRadius, self.cornerRadius, NULL);
            CGContextAddPath(context, p);
            CGContextFillPath(context);
            CGPathRelease(p);
        }
    }
    CGContextRestoreGState(context);
}


#pragma mark - Private methods

/*!
 Return an array of tuple-style arrays. Each tuple contains two objects: the NSValue-encoded range of a rounded
 rectangle background (RRB) attribute, and the RRB value object itself.
 */
- (NSArray *)roundedRectBackgroundAttributeTuplesInTextStorage:(NSTextStorage *)textStorage
                                              withinGlyphRange:(NSRange)glyphRange {
    NSMutableArray *buffer = [NSMutableArray array];
    if (!textStorage || glyphRange.location == NSNotFound) {
        return nil;
    }

    // Convert from glyph to character range, because we will be enumerating over the characters to apply attributes
    // Glyphs and character ranges are usually equal in English, but can be very different in other languages like Tamil, Farsi and Arabic
    // https://www.icu-project.org/docs/papers/forms_of_unicode/
    NSRange characterRange = [self characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];

    // Go through the attributes in the given range and pick out the ones that correspond to the
    [textStorage enumerateAttributesInRange:characterRange
                                    options:NSAttributedStringEnumerationLongestEffectiveRangeNotRequired
                                 usingBlock:^(NSDictionary *attrs, NSRange attributeRange, __unused BOOL *stop) {
                                     for (NSString *attr in attrs) {
                                         if (attr == HKWRoundedRectBackgroundAttributeName) {
                                             id const attributeValue = attrs[attr];
                                             if (!attributeValue) {
                                                 NSAssert(NO, @"Internal error");
                                                 continue;
                                             }
                                             RoundedRectAttributeTuple *tuple = @[[NSValue valueWithRange:attributeRange], attributeValue];
                                             [buffer addObject:tuple];
                                         }
                                     }
                                 }];
    return [NSArray arrayWithArray:buffer];
}

/*!
 Given an array of tuples generated by \c roundedRectBackgroundAttributeTuplesInTextStorage:withinRange: method,
 return a final array of line fragment rects which the layout manager should draw onto the screen.
 */
- (NSArray *)rectArraysForRoundedRectBackgroundAttributeTuples:(NSArray *)attributeTuples
                                               inTextContainer:(NSTextContainer *)container {
    if ([attributeTuples count] == 0 || !container) {
        return nil;
    }

    NSMutableArray *finalRectArrays = [NSMutableArray new];

    NSRange currentRange;
    RectValuesBuffer *lineFragments = [NSMutableArray new];
    RectValuesBuffer *enclosingRects = [NSMutableArray new];
    for (RoundedRectAttributeTuple *tuple in attributeTuples) {
        [lineFragments removeAllObjects];
        [enclosingRects removeAllObjects];

        // Destructure the tuple
        currentRange = [((NSValue *)tuple[0]) rangeValue];
        HKWRoundedRectBackgroundAttributeValue *data = tuple[1];
        if (currentRange.location == NSNotFound) {
            continue;
        }

        // Get the line fragment rects for the given RRB attribute
        [self enumerateLineFragmentsForGlyphRange:currentRange
                                       usingBlock:^(__unused CGRect rect,
                                                    CGRect usedRect,
                                                    NSTextContainer *textContainer,
                                                    NSRange glyphRange,
                                                    __unused BOOL *stop) {
                                           if (container != textContainer) {
                                               return;
                                           }
                                           NSString *substr = [[self.textStorage attributedSubstringFromRange:glyphRange] string];
                                           NSUInteger count = [[self class] numberOfTrailingSpacesInString:substr];
                                           if (count == 0) {
                                               [lineFragments addObject:[NSValue valueWithCGRect:usedRect]];
                                           }
                                           else {
                                               // Technically, glyphs don't map one-to-one with characters.
                                               // However, this should be okay, because it only triggers for trailing
                                               //  whitespace characters, which *should* map one-to-one with their
                                               //  glyphs.
                                               // If there are trailing whitespace/newlines, remove them.
                                               NSAssert((NSUInteger)glyphRange.length >= count, @"Internal error");
                                               NSRange subRange = NSMakeRange((NSUInteger)glyphRange.location, (NSUInteger)glyphRange.length-count);
                                               CGRect subRect = [self boundingRectForGlyphRange:subRange inTextContainer:textContainer];
                                               [lineFragments addObject:[NSValue valueWithCGRect:subRect]];
                                           }
                                       }];

        // Get the enclosing rects for the given RRB attribute
        [self enumerateEnclosingRectsForGlyphRange:currentRange
                          withinSelectedGlyphRange:NSMakeRange(NSNotFound, 0)
                                   inTextContainer:container
                                        usingBlock:^(CGRect rect, __unused BOOL *stop) {
                                            [enclosingRects addObject:[NSValue valueWithCGRect:rect]];
                                        }];

        // Combine the two sets of rects to form a final rects group
        NSArray *unionRects = [self arrayOfRectsForFragmentRects:lineFragments
                                                  enclosingRects:enclosingRects
                                                rrbAttributeData:data];
        if (!unionRects) {
            return nil;
        }
        [finalRectArrays addObject:unionRects];
    }
    return [NSArray arrayWithArray:finalRectArrays];
}

- (NSArray *)arrayOfRectsForFragmentRects:(NSArray *)fragmentRects
                           enclosingRects:(NSArray *)enclosingRects
                         rrbAttributeData:(__unused HKWRoundedRectBackgroundAttributeValue *)data {
    RectValuesBuffer *buffer = [NSMutableArray array];
    if ([fragmentRects count] == 0) {
        return nil;
    }

    // First, destructure fragmentRects
    const NSUInteger fragmentRectsCount = [fragmentRects count];
    CGFloat *rectXArray = malloc(fragmentRectsCount * sizeof(CGFloat));
    if (!rectXArray) {
        goto ALLOC_X_FAILED;
    }
    CGFloat *rectYArray = malloc(fragmentRectsCount * sizeof(CGFloat));
    if (!rectYArray) {
        goto ALLOC_Y_FAILED;
    }
    CGFloat *rectWidthArray = malloc(fragmentRectsCount * sizeof(CGFloat));
    if (!rectWidthArray) {
        goto ALLOC_WIDTH_FAILED;
    }
    CGFloat *rectHeightArray = malloc(fragmentRectsCount * sizeof(CGFloat));
    if (!rectHeightArray) {
        goto ALLOC_HEIGHT_FAILED;
    }

    for (NSUInteger i=0; i<fragmentRectsCount; i++) {
        CGRect fragmentRect = [fragmentRects[i] CGRectValue];
        rectXArray[i] = fragmentRect.origin.x;
        rectYArray[i] = fragmentRect.origin.y;
        rectWidthArray[i] = fragmentRect.size.width;
        rectHeightArray[i] = fragmentRect.size.height;
    }

    for (NSValue *value in enclosingRects) {
        CGRect currentEnclosingRect = [value CGRectValue];

        // Clip the enclosing rect to the bounds of the fragment rects
        CGRect intersectionRect = currentEnclosingRect;
        for (NSUInteger i=0; i<fragmentRectsCount; i++) {
            CGRect currentFragmentRect = CGRectMake(rectXArray[i],
                                                    rectYArray[i],
                                                    rectWidthArray[i],
                                                    rectHeightArray[i]);
            if (CGRectIntersectsRect(intersectionRect, currentFragmentRect)) {
                // If the rects intersect, shrink the rect.
                intersectionRect = CGRectIntersection(intersectionRect, currentFragmentRect);
            }
        }
        // Add to buffer
        [buffer addObject:[NSValue valueWithCGRect:intersectionRect]];
    }
    // Clean up and return
ALLOC_HEIGHT_FAILED:
    free(rectHeightArray);
ALLOC_WIDTH_FAILED:
    free(rectWidthArray);
ALLOC_Y_FAILED:
    free(rectYArray);
ALLOC_X_FAILED:
    free(rectXArray);
    return [NSArray arrayWithArray:buffer];
}

+ (NSUInteger)numberOfTrailingSpacesInString:(NSString *)str {
    NSUInteger count = 0;
    for (NSInteger i=(NSInteger)[str length]-1; i>=0; i--) {
        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[str characterAtIndex:(NSUInteger)i]]) {
            count++;
        }
        else {
            break;
        }
    }
    return count;
}


#pragma mark - Module parameters

- (CGFloat)cornerRadius {
    return 3.0;
}

- (CGFloat)additionalHeight {
    return 1.0;
}

@end

