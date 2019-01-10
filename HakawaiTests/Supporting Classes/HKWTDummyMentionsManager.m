//
//  HKWTDummyMentionsManager.m
//  Hakawai
//
//  Copyright (c) 2018 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTDummyMentionsManager.h"

@implementation HKWTDummyMentionsManager

- (void)asyncRetrieveEntitiesForKeyString:(NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void(^)(NSArray *results, BOOL dedupe, BOOL isComplete))completionBlock {
    if (type == HKWMentionsSearchTypeInitial) {
        completionBlock([[NSArray alloc] initWithObjects:[HKWTDummyMentionEntity entityWithName:@"Alan Perlis" entityID:@"1"], nil], YES, YES);
    }
    NSArray *fakeData = @[[HKWTDummyMentionEntity entityWithName:@"Alan Perlis" entityID:@"1"],
                          [HKWTDummyMentionEntity entityWithName:@"Maurice Wilkes" entityID:@"2"],
                          [HKWTDummyMentionEntity entityWithName:@"Michael Rabin" entityID:@"12"],
                          [HKWTDummyMentionEntity entityWithName:@"Richard Hamming" entityID:@"3"],
                          [HKWTDummyMentionEntity entityWithName:@"John McCarthy" entityID:@"6"]];
    if (completionBlock) {
        completionBlock(fakeData, YES, YES);
    }
}

- (UITableViewCell *)cellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity withMatchString:(NSString *)matchString tableView:(UITableView *)tableView atIndexPath:(NSIndexPath *)indexPath  {
    return [[UITableViewCell alloc] init];
}

- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity tableView:(UITableView *)tableView {
    return 0;
}

@end
