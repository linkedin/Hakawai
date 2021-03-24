//
//  HKWExternalMentionConstants.m
//  Hakawai
//
//  Created by Chen Yuan on 3/23/21.
//  Copyright © 2021 LinkedIn. All rights reserved.
//

#import "HKWExternalMentionConstants.h"

@implementation HKWExternalMentionConstants

+ (nonnull NSCharacterSet *)atSymbols {
    return [NSCharacterSet characterSetWithCharactersInString:@"@＠"];
}

@end
