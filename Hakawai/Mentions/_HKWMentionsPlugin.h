//
//  _HKWMentionsPlugin.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWMentionsPlugin.h"

@interface HKWMentionsPlugin ()

@property (nonatomic, strong) NSCharacterSet *controlCharacterSet;
@property (nonatomic) NSInteger implicitSearchLength;
@property (nonatomic, readonly) BOOL implicitMentionsEnabled;

@end
