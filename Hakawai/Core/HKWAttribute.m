//
//  HKWAttribute.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWAttribute.h"

@interface HKWAttribute ()
@property (nonatomic, strong, readwrite) NSString *attribute;
@property (nonatomic, strong, readwrite) NSObject *parameter;
@end

@implementation HKWAttribute

+ (instancetype)instanceWithAttribute:(NSString *)attribute parameter:(id)parameter {
    HKWAttribute *attr = [[self class] new];
    attr.attribute = attribute;
    attr.parameter = parameter;
    return attr;
}

+ (instancetype)fontAttributeWithFont:(UIFont *)font {
    return [[self class] instanceWithAttribute:NSFontAttributeName parameter:font];
}

+ (instancetype)paragraphStyleAttributeWithStyle:(NSParagraphStyle *)style {
    return [[self class] instanceWithAttribute:NSParagraphStyleAttributeName parameter:style];
}

+ (instancetype)foregroundColorAttributeWithColor:(UIColor *)color {
    return [[self class] instanceWithAttribute:NSForegroundColorAttributeName parameter:color];
}

+ (instancetype)backgroundColorAttributeWithColor:(UIColor *)color {
    return [[self class] instanceWithAttribute:NSBackgroundColorAttributeName parameter:color];
}

+ (instancetype)ligatureAttributeWithMode:(BOOL)useLigatures {
    return [[self class] instanceWithAttribute:NSLigatureAttributeName parameter:(useLigatures ? @(1) : @(0))];
}

+ (instancetype)kernAttributeWithKerning:(CGFloat)kerning {
    return [[self class] instanceWithAttribute:NSKernAttributeName parameter:@(kerning)];
}

+ (instancetype)strikethroughAttributeWithParams:(NSUInteger)params {
    return [[self class] instanceWithAttribute:NSStrikethroughStyleAttributeName parameter:@(params)];
}

+ (instancetype)underlineAttributeWithParams:(NSUInteger)params {
    return [[self class] instanceWithAttribute:NSUnderlineStyleAttributeName parameter:@(params)];
}

+ (instancetype)strokeColorAttributeWithColor:(UIColor *)color {
    return [[self class] instanceWithAttribute:NSStrokeColorAttributeName parameter:color];
}

+ (instancetype)strokeWidthAttributeWithWidth:(CGFloat)width {
    return [[self class] instanceWithAttribute:NSStrokeWidthAttributeName parameter:@(width)];
}

+ (instancetype)shadowAttributeWithShadow:(NSShadow *)shadow {
    return [[self class] instanceWithAttribute:NSShadowAttributeName parameter:shadow];
}

+ (instancetype)textEffectAttributeWithEffect:(NSString *)effect {
    return [[self class] instanceWithAttribute:NSTextEffectAttributeName parameter:effect];
}

+ (instancetype)attachmentAttributeWithAttachment:(NSTextAttachment *)attachment {
    return [[self class] instanceWithAttribute:NSAttachmentAttributeName parameter:attachment];
}

+ (instancetype)linkAttributeWithURL:(NSURL *)URL {
    return [[self class] instanceWithAttribute:NSLinkAttributeName parameter:URL];
}

+ (instancetype)baselineOffsetAttributeWithOffset:(CGFloat)offset {
    return [[self class] instanceWithAttribute:NSBaselineOffsetAttributeName parameter:@(offset)];
}

+ (instancetype)underlineColorAttributeWithColor:(UIColor *)color {
    return [[self class] instanceWithAttribute:NSUnderlineColorAttributeName parameter:color];
}

+ (instancetype)strikethroughColorAttributeWithColor:(UIColor *)color {
    return [[self class] instanceWithAttribute:NSStrikethroughColorAttributeName parameter:color];
}

+ (instancetype)obliquenessAttributeWithObliqueness:(CGFloat)obliqueness {
    return [[self class] instanceWithAttribute:NSObliquenessAttributeName parameter:@(obliqueness)];
}

+ (instancetype)expansionAttributeWithExpansion:(CGFloat)expansion {
    return [[self class] instanceWithAttribute:NSExpansionAttributeName parameter:@(expansion)];
}

@end
