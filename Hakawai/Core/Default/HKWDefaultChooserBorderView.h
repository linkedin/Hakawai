//
//  HKWDefaultChooserBorderView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
