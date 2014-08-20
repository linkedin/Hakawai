//
//  HKWDefaultChooserArrowView.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWDefaultChooserArrowView.h"

const static CGFloat ARROW_VIEW_WIDTH = 10.0;
const static CGFloat ARROW_VIEW_HEIGHT = 5.0;
const static CGFloat MASK_LINE_WIDTH = 1.0;

@interface HKWDefaultChooserArrowView ()
@end

@implementation HKWDefaultChooserArrowView

+ (instancetype)chooserArrowViewPointingUp:(BOOL)pointingUp {
    HKWDefaultChooserArrowView *view = [[[self class] alloc] initWithFrame:CGRectMake(0, 0,
                                                                                ARROW_VIEW_WIDTH,
                                                                                ARROW_VIEW_HEIGHT)
                                                          pointingUp:pointingUp];
    view.backgroundColor = [UIColor clearColor];
    return view;
}

- (id)initWithFrame:(CGRect)frame pointingUp:(BOOL)pointingUp {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    // Setup
    self.pointingUp = pointingUp;
    self.layer.mask = [self createMaskLayer:pointingUp];
    return self;
}

- (CALayer *)createMaskLayer:(BOOL)pointingUp {
    CAShapeLayer *layer = [CAShapeLayer layer];
    CGMutablePathRef path = CGPathCreateMutable();

    CGFloat quarterLineWidth = 0.25*MASK_LINE_WIDTH;
    CGFloat baseY = pointingUp ? (ARROW_VIEW_HEIGHT) : (0) ;
    CGFloat topY = pointingUp ? 0 + quarterLineWidth : (ARROW_VIEW_HEIGHT - quarterLineWidth);
    CGFloat leftX = 0 + quarterLineWidth;
    CGFloat rightX = ARROW_VIEW_WIDTH - quarterLineWidth;
    CGFloat midX = ARROW_VIEW_WIDTH/2.0;

    CGPathMoveToPoint(path, NULL, leftX, baseY);
    CGPathAddLineToPoint(path, NULL, midX, topY);
    CGPathAddLineToPoint(path, NULL, rightX, baseY);
    CGPathCloseSubpath(path);

    layer.path = path;
    layer.lineWidth = MASK_LINE_WIDTH;
    layer.fillColor = [[UIColor whiteColor] CGColor];
    layer.strokeColor = [[UIColor whiteColor] CGColor];
    layer.lineJoin = kCALineJoinMiter;
    CGPathRelease(path);
    return layer;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    // Create the gradient
    CFMutableArrayRef colors = CFArrayCreateMutable(NULL, 2, NULL);
    CFArrayInsertValueAtIndex(colors, 0, [self.tipGradientColor CGColor]);
    CFArrayInsertValueAtIndex(colors, 1, [self.baseGradientColor CGColor]);
    CGGradientRef gradient = CGGradientCreateWithColors(NULL, colors, NULL);
    CFRelease(colors);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint startPoint = CGPointMake(ARROW_VIEW_WIDTH/2.0, self.pointingUp ? 0 : ARROW_VIEW_HEIGHT);
    CGPoint endPoint = CGPointMake(ARROW_VIEW_WIDTH/2.0, self.pointingUp ? ARROW_VIEW_HEIGHT : 0);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
}


#pragma mark - Properties

- (void)setPointingUp:(BOOL)pointingUp {
    if (_pointingUp == pointingUp) return;
    _pointingUp = pointingUp;
    self.layer.mask = [self createMaskLayer:pointingUp];
    [self setNeedsDisplay];
}

- (UIColor *)baseGradientColor {
    if (!_baseGradientColor) {
        _baseGradientColor = [UIColor clearColor];
    }
    return _baseGradientColor;
}

- (UIColor *)tipGradientColor {
    if (!_tipGradientColor) {
        _baseGradientColor = [UIColor clearColor];
    }
    return _tipGradientColor;
}

@end
