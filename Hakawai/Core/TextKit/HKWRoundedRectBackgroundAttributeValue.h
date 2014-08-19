//
//  HKWRoundedRectBackgroundAttributeValue.h
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

// This class present to support future customization (e.g. corner radius, etc)

@interface HKWRoundedRectBackgroundAttributeValue : NSObject

/*!
 The color to draw the background highlight effect.
 */
@property (nonatomic, strong) UIColor *backgroundColor;

/// Convenience constructor.
+ (instancetype)valueWithBackgroundColor:(UIColor *)color;

@end
