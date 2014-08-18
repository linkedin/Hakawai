//
//  HKWDefaultChooserBorderView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <UIKit/UIKit.h>

@protocol HKWDefaultChooserBorderViewProtocol <NSObject>

- (UIView *)arrowView;
- (CGSize)sizeForArrowView;
- (void)moveArrowViewToPositionRelativeToBorderView:(CGPoint)position;

@end

@interface HKWDefaultChooserBorderView : UIView

@property (nonatomic, weak) id<HKWDefaultChooserBorderViewProtocol>delegate;

@property (nonatomic) BOOL arrowVisible;
@property (nonatomic) BOOL borderOnTop;
@property (nonatomic, strong) UIColor *strokeColor;
@property (nonatomic, strong) UIColor *arrowFillColor;
@property (nonatomic) CGFloat strokeThickness;

@property (nonatomic) CGFloat pointerXPercent;

@property (nonatomic, readonly) CGFloat arrowLeftX;
@property (nonatomic, readonly) CGFloat arrowMiddleX;
@property (nonatomic, readonly) CGFloat arrowRightX;
@property (nonatomic, readonly) CGFloat arrowTipYOffset;

@end
