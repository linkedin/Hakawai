//
//  HKWAttribute.m
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWAttribute.h"

@interface HKWAttribute ()
@property (nonatomic, strong, readwrite) NSString *attribute;
@property (nonatomic, strong, readwrite) id parameter;
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

+ (NSDictionary *)attributeDictionaryWithAttributes:(NSArray *)attributes {
    NSMutableDictionary *buffer = [NSMutableDictionary dictionary];
    for (id object in attributes) {
        if (![object isKindOfClass:[HKWAttribute class]]) {
            continue;
        }
        HKWAttribute *attr = (HKWAttribute *)object;
        [buffer setObject:attr.parameter forKey:attr.attribute];
    }
    return [buffer copy];
}

@end
