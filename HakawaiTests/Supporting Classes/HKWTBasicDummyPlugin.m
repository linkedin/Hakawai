//
//  BasicDummyPlugin.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import "HKWTBasicDummyPlugin.h"

@implementation HKWTBasicDummyPlugin

@synthesize parentTextView;

+ (instancetype)dummyPluginWithName:(NSString *)name {
    HKWTBasicDummyPlugin *plugin = [self new];
    plugin.pluginName = name;
    return plugin;
}

@end
