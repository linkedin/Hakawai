//
//  HKWAttribute.h
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

/*!
 An object representing an attribute which can be applied to part of an attributed string.

 \note HKWAttribute objects aren't used anywhere else in the library, but are present for convenience and usage in
 future plug-ins.
 */
@interface HKWAttribute : NSObject

@property (nonatomic, readonly) NSString *attribute;
@property (nonatomic, readonly) id parameter;

+ (instancetype)fontAttributeWithFont:(UIFont *)font;
+ (instancetype)paragraphStyleAttributeWithStyle:(NSParagraphStyle *)style;
+ (instancetype)foregroundColorAttributeWithColor:(UIColor *)color;
+ (instancetype)backgroundColorAttributeWithColor:(UIColor *)color;
+ (instancetype)ligatureAttributeWithMode:(BOOL)useLigatures;
+ (instancetype)kernAttributeWithKerning:(CGFloat)kerning;
+ (instancetype)strikethroughAttributeWithParams:(NSUInteger)params;
+ (instancetype)underlineAttributeWithParams:(NSUInteger)params;
+ (instancetype)strokeColorAttributeWithColor:(UIColor *)color;
+ (instancetype)strokeWidthAttributeWithWidth:(CGFloat)width;
+ (instancetype)shadowAttributeWithShadow:(NSShadow *)shadow;
+ (instancetype)textEffectAttributeWithEffect:(NSString *)effect;
+ (instancetype)attachmentAttributeWithAttachment:(NSTextAttachment *)attachment;
+ (instancetype)linkAttributeWithURL:(NSURL *)URL;
+ (instancetype)baselineOffsetAttributeWithOffset:(CGFloat)offset;
+ (instancetype)underlineColorAttributeWithColor:(UIColor *)color;
+ (instancetype)strikethroughColorAttributeWithColor:(UIColor *)color;
+ (instancetype)obliquenessAttributeWithObliqueness:(CGFloat)obliqueness;
+ (instancetype)expansionAttributeWithExpansion:(CGFloat)expansion;

// NSWritingDirectionAttributeName is not supported

/*!
 Given an array of \c HKWAttribute objects, generate an attribute dictionary
 */
+ (NSDictionary *)attributeDictionaryWithAttributes:(NSArray *)attributes;

@end
