//
//  HKWExternalMentionConstants.h
//  Hakawai
//
//  Created by Chen Yuan on 3/23/21.
//  Copyright © 2021 LinkedIn. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HKWExternalMentionConstants : NSObject

/**
 Character set for at symbols to prepend to mention text, including @, ＠ (Japanese).
 NOTE: This is for the ease of library consumers, not for use inside the library
 */
@property (nonatomic, class, nonnull, readonly) NSCharacterSet *atSymbols;

@end

NS_ASSUME_NONNULL_END
