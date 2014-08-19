//
//  BasicDummyPlugin.h
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HKWSimplePluginProtocol.h"

@interface HKWTBasicDummyPlugin : NSObject <HKWSimplePluginProtocol>

@property (nonatomic, strong) NSString *pluginName;

+ (instancetype)dummyPluginWithName:(NSString *)name;

@end
