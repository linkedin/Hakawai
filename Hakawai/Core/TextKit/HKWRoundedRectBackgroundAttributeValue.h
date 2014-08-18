//
//  HKWRoundedRectBackgroundAttributeValue.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
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
