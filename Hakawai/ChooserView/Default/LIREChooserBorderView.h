//
//  LIREChooserBorderView.h
//  LIRichEditorLibrary
//
//  Created by Austin Zheng on 5/28/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol LIREChooserBorderViewProtocol <NSObject>

- (UIView *)arrowView;
- (CGSize)sizeForArrowView;
- (void)moveArrowViewToPositionRelativeToBorderView:(CGPoint)position;

@end

@interface LIREChooserBorderView : UIView

@property (nonatomic, weak) id<LIREChooserBorderViewProtocol>delegate;

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
