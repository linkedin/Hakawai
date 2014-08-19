//
//  HKWMentionsAttribute.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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
