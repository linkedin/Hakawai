//
//  HKWTControlFlowDummyPlugin.h
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "HKWControlFlowPluginProtocol.h"

@interface HKWTControlFlowDummyPlugin : NSObject <HKWControlFlowPluginProtocol>

@property (nonatomic, strong) NSString *pluginName;

@property (nonatomic, copy) void (^shouldBeginEditingBlock)(void);
@property (nonatomic, copy) void (^didBeginEditingBlock)(void);
@property (nonatomic, copy) void (^shouldEndEditingBlock)(void);
@property (nonatomic, copy) void (^didEndEditingBlock)(void);
@property (nonatomic, copy) void (^shouldChangeTextInRangeBlock)(void);
@property (nonatomic, copy) void (^didChangeBlock)(void);
@property (nonatomic, copy) void (^didChangeSelectionBlock)(void);
@property (nonatomic, copy) void (^shouldInteractWithTextAttachmentBlock)(void);
@property (nonatomic, copy) void (^shouldInteractWithURLBlock)(void);

+ (instancetype)dummyPluginWithName:(NSString *)name;

- (void)resetBlocks;

@end
