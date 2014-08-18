//
//  LIREChooserShadowView.m
//  LIRichEditorLibrary
//
//  Created by Austin Zheng on 5/29/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import "LIREChooserShadowView.h"

@interface LIREChooserShadowView ()
@property (nonatomic, strong) UIColor *translucentDarkColor;

@end

@implementation LIREChooserShadowView

+ (instancetype)chooserShadowViewPointingUp:(BOOL)pointingUp size:(CGSize)size {
    LIREChooserShadowView *view = [[[self class] alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)
                                                                   pointingUp:pointingUp];
    return view;
}

- (id)initWithFrame:(CGRect)frame pointingUp:(BOOL)pointingUp {
    self = [super initWithFrame:frame];
    if (!self) return nil;
    // Setup
    self.backgroundColor = [UIColor clearColor];
    self.pointingUp = pointingUp;
    return self;
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    // Draw the gradient
    CGFloat locations[] = {0.0, 0.2, 1.0};
    CFMutableArrayRef colors = CFArrayCreateMutable(NULL, 3, NULL);
    CFArrayInsertValueAtIndex(colors, 0, [self.darkGradientColor CGColor]);
    CFArrayInsertValueAtIndex(colors, 1, [self.translucentDarkColor CGColor]);
    CFArrayInsertValueAtIndex(colors, 2, [self.lightGradientColor CGColor]);
    CGGradientRef gradient = CGGradientCreateWithColors(NULL, colors, locations);
    CFRelease(colors);

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGPoint startPoint = CGPointMake(rect.size.width/2.0,
                                     self.pointingUp ? 0 : self.bounds.size.height);
    CGPoint endPoint = CGPointMake(rect.size.width/2.0,
                                   self.pointingUp ? self.bounds.size.height : 0);
    CGContextDrawLinearGradient(ctx, gradient, startPoint, endPoint, 0);
    CGGradientRelease(gradient);
}


#pragma mark - Properties

- (void)setPointingUp:(BOOL)pointingUp {
    if (_pointingUp == pointingUp) return;
    _pointingUp = pointingUp;
    [self setNeedsDisplay];
}

- (UIColor *)darkGradientColor {
    if (!_darkGradientColor) {
        _darkGradientColor = [UIColor colorWithRed:0.89 green:0.89 blue:0.89 alpha:1.0];
        self.translucentDarkColor = nil;
    }
    return _darkGradientColor;
}

- (UIColor *)translucentDarkColor {
    if (!_translucentDarkColor) {
        _translucentDarkColor = [self.darkGradientColor colorWithAlphaComponent:0.5];
    }
    return _translucentDarkColor;
}

- (UIColor *)lightGradientColor {
    if (!_lightGradientColor) {
        _lightGradientColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
    }
    return _lightGradientColor;
}

@end
