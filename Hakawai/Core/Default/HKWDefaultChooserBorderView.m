//
//  HKWDefaultChooserBorderView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWDefaultChooserBorderView.h"

@interface HKWDefaultChooserBorderView ()
@property (nonatomic, readonly) CGFloat arrowWidth;
@property (nonatomic, readonly) CGFloat arrowHeight;
@end

@implementation HKWDefaultChooserBorderView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        self.backgroundColor = [UIColor clearColor];
        self.strokeThickness = 1.0;
        self.pointerXPercent = 0.5;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.arrowVisible) {
        [self drawBorderWithPointer];
    }
    else {
        [self drawBorderWithoutPointer];
    }
}

- (void)drawBorderWithoutPointer {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);
    CGMutablePathRef path = CGPathCreateMutable();
    CGRect bounds = self.bounds;

    CGFloat currentY = self.borderOnTop ? bounds.size.height - self.strokeThickness/2.0f : (0 + self.strokeThickness/2.0f);
    CGPathMoveToPoint(path, NULL, 0, currentY);
    CGPathAddLineToPoint(path, NULL, bounds.size.width, currentY);
    CGContextAddPath(context, path);

    CGContextSetLineWidth(context, self.strokeThickness);
    [self.strokeColor setStroke];
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(path);
    CGContextRestoreGState(context);
}

- (void)drawBorderWithPointer {
    CGSize size = self.bounds.size;
    CGFloat baseY = self.borderOnTop ? (size.height - self.strokeThickness/2.0f) : (0 + self.strokeThickness/2.0f);
    CGFloat topY = baseY + self.arrowTipYOffset;

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSaveGState(context);

    // Left line segment
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, 0, baseY);
    CGPathAddLineToPoint(path, NULL, self.arrowLeftX, baseY);
    CGPathAddLineToPoint(path, NULL, self.arrowMiddleX, topY);
    CGPathAddLineToPoint(path, NULL, self.arrowRightX, baseY);
    CGPathAddLineToPoint(path, NULL, size.width, baseY);
    CGContextSetLineJoin(context, kCGLineJoinRound);

    CGContextAddPath(context, path);
    CGContextSetLineWidth(context, self.strokeThickness);
    [self.strokeColor setStroke];
    CGContextDrawPath(context, kCGPathStroke);
    CGPathRelease(path);
    CGContextRestoreGState(context);

    [self moveArrowToPosition];
}

- (void)moveArrowToPosition {
    BOOL arrowPointsUp = self.borderOnTop;
    CGFloat xPosition = (CGFloat)floor((self.bounds.size.width * self.pointerXPercent) - (self.arrowWidth/2.0f));
    CGFloat yPosition = arrowPointsUp ? (self.bounds.size.height - self.arrowHeight) : 0;
    [self.delegate moveArrowViewToPositionRelativeToBorderView:CGPointMake(xPosition, yPosition)];
}


#pragma mark - Properties

- (void)setArrowVisible:(BOOL)arrowVisible {
    _arrowVisible = arrowVisible;
    [self setNeedsDisplay];
}

- (void)setBorderOnTop:(BOOL)borderOnTop {
    _borderOnTop = borderOnTop;
    [self setNeedsDisplay];
}

- (void)setPointerXPercent:(CGFloat)pointerXPercent {
    if (_pointerXPercent == pointerXPercent) return;
    // Clamp to bounds
    static const CGFloat lowerClamp = 0.05f;
    static const CGFloat upperClamp = 0.95f;
    if (pointerXPercent < lowerClamp) pointerXPercent = lowerClamp;
    if (pointerXPercent > upperClamp) pointerXPercent = upperClamp;
    _pointerXPercent = pointerXPercent;
    [self setNeedsDisplay];
}

- (UIColor *)strokeColor {
    if (!_strokeColor) {
        _strokeColor = [UIColor colorWithRed:0.66f green:0.66f blue:0.67f alpha:1.0f];
    }
    return _strokeColor;
}

- (UIColor *)arrowFillColor {
    if (!_arrowFillColor) {
        _arrowFillColor = [UIColor whiteColor];
    }
    return _arrowFillColor;
}

- (CGFloat)arrowWidth {
    return [self.delegate sizeForArrowView].width;
}

- (CGFloat)arrowHeight {
    return [self.delegate sizeForArrowView].height;
}


#pragma mark - Computed properties

- (CGFloat)arrowLeftX {
    return self.arrowMiddleX - self.arrowWidth/2.0f;
}

- (CGFloat)arrowMiddleX {
    return (CGFloat)floor(self.pointerXPercent * (self.bounds.size.width));
}

- (CGFloat)arrowRightX {
    return self.arrowMiddleX + self.arrowWidth/2.0f;
}

- (CGFloat)arrowTipYOffset {
    BOOL arrowPointsUp = self.borderOnTop;
    return arrowPointsUp ? self.strokeThickness/2.0f - self.arrowHeight : self.arrowHeight - self.strokeThickness/2.0f;
}

@end
