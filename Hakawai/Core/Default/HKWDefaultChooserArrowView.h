//
//  HKWDefaultChooserArrowView.h
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

// NOTE: This view doesn't do much at the moment. It's provided in case you want some sort of shading or other visual
//  effects to be applied to the triangular notch in the border.

@interface HKWDefaultChooserArrowView : UIView

@property (nonatomic) BOOL pointingUp;
@property (nonatomic, strong) UIColor *tipGradientColor;
@property (nonatomic, strong) UIColor *baseGradientColor;

+ (instancetype)chooserArrowViewPointingUp:(BOOL)pointingUp;

@end
