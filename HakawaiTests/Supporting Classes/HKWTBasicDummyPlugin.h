//
//  BasicDummyPlugin.h
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <Foundation/Foundation.h>

#import "HKWControlFlowPluginProtocols.h"
#import "HKWSimplePluginProtocol.h"

@interface HKWTBasicDummyPlugin : NSObject <HKWSimplePluginProtocol, HKWDirectControlFlowPluginProtocol>

@property (nonatomic, strong) NSString *pluginName;

@property (nonatomic, copy) void (^registerBlock)(void);
@property (nonatomic, copy) void (^unregisterBlock)(void);

+ (instancetype)dummyPluginWithName:(NSString *)name;

@end
