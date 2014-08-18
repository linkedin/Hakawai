//
//  HKWMentionsAttribute.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <Foundation/Foundation.h>

#import "HKWMentionsEntityProtocol.h"

@interface HKWMentionsAttribute : NSObject <HKWMentionsEntityProtocol>

@property (nonatomic, strong) NSString *mentionText;
@property (nonatomic, strong) NSString *entityIdentifier;

@property (nonatomic, strong) NSDictionary *metadata;

/*!
 The range of the mention. This is only valid when calling the mentions plug-in's \c mentions API method; it is not used
 for internal calculations.
 */
@property (nonatomic) NSRange range;

+ (instancetype)mentionWithText:(NSString *)text identifier:(NSString *)identifier;

@end
