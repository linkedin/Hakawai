//
//  HKWAttribute.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <UIKit/UIKit.h>

/*!
 An object representing an attribute which can be applied to part of an attributed string.
 */
@interface HKWAttribute : NSObject

@property (nonatomic, readonly) NSString *attribute;
@property (nonatomic, readonly) NSObject *parameter;

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

@end
