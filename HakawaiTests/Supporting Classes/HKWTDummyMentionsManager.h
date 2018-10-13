//
//  HKWTDummyMentionsManager.h
//  Hakawai
//
//  Copyright (c) 2018 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWMentionsPlugin.h"
#import "HKWTDummyMentionEntity.h"

@interface HKWTDummyMentionsManager: NSObject<HKWMentionsDelegate>

- (void)asyncRetrieveEntitiesForKeyString:(NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void(^)(NSArray *results, BOOL dedupe, BOOL isComplete))completionBlock;

- (UITableViewCell *)cellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                           withMatchString:(NSString *)matchString
                                 tableView:(UITableView *)tableView
                               atIndexPath:(NSIndexPath *)indexPath;


- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity tableView:(UITableView *)tableView;

@end
