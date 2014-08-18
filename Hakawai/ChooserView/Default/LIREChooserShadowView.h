//
//  LIREChooserShadowView.h
//  LIRichEditorLibrary
//
//  Created by Austin Zheng on 5/29/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LIREChooserShadowView : UIView

@property (nonatomic) BOOL pointingUp;
@property (nonatomic, strong) UIColor *darkGradientColor;
@property (nonatomic, strong) UIColor *lightGradientColor;

+ (instancetype)chooserShadowViewPointingUp:(BOOL)pointingUp size:(CGSize)size;

@end
