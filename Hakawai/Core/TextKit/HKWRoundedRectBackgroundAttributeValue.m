//
//  HKWRoundedRectBackgroundAttributeValue.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWRoundedRectBackgroundAttributeValue.h"

@implementation HKWRoundedRectBackgroundAttributeValue

+ (instancetype)valueWithBackgroundColor:(UIColor *)color {
    HKWRoundedRectBackgroundAttributeValue *v = [[self class] new];
    v.backgroundColor = color;
    return v;
}

@end
