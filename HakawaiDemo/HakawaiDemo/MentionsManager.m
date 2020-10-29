//
//  MentionsManager.m
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "MentionsManager.h"

#import "MentionEntity.h"

// This #define determines whether or not custom trimming behavior should be enabled
//#define USE_CUSTOM_TRIMMING_BEHAVIOR

@interface MentionsManager ()
@property (nonatomic, strong) NSArray *fakeData;
@end

@implementation MentionsManager

// The mentions delegate is implemented as a singleton here for convenience; it does not need to be in your application
+ (instancetype)sharedInstance {
    static MentionsManager *staticInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        staticInstance = [[self class] new];
        [staticInstance setupFakeData];
    });
    return staticInstance;
}

- (void)setupFakeData {
    self.fakeData = @[[MentionEntity entityWithName:@"Alan Perlis" entityId:@"1"],
                      [MentionEntity entityWithName:@"Maurice Wilkes" entityId:@"2"],
                      [MentionEntity entityWithName:@"Richard Hamming" entityId:@"3"],
                      [MentionEntity entityWithName:@"Marvin Minsky" entityId:@"4"],
                      [MentionEntity entityWithName:@"James Wilkinson" entityId:@"5"],
                      [MentionEntity entityWithName:@"John McCarthy" entityId:@"6"],  // DupeTesting: First instance
                      [MentionEntity entityWithName:@"Edsger Dijkstra" entityId:@"7"],
                      [MentionEntity entityWithName:@"Charles Bachman" entityId:@"8"],
                      [MentionEntity entityWithName:@"Donald Knuth" entityId:@"9"],
                      [MentionEntity entityWithName:@"Allen Newell" entityId:@"10"],
                      [MentionEntity entityWithName:@"Herbert Simon" entityId:@"11"],
                      [MentionEntity entityWithName:@"Michael Rabin" entityId:@"12"],
                      [MentionEntity entityWithName:@"Dana Scott" entityId:@"13"],
                      [MentionEntity entityWithName:@"John Backus" entityId:@"14"],
                      [MentionEntity entityWithName:@"Robert Floyd" entityId:@"15"],
                      [MentionEntity entityWithName:@"Kenneth Iverson" entityId:@"16"],
                      [MentionEntity entityWithName:@"Antony Hoare" entityId:@"17"],
                      [MentionEntity entityWithName:@"Edgar Codd" entityId:@"18"],
                      [MentionEntity entityWithName:@"Stephen Cook" entityId:@"19"],
                      [MentionEntity entityWithName:@"Dennis Ritchie" entityId:@"20"],
                      [MentionEntity entityWithName:@"Kenneth Thompson" entityId:@"21"],
                      [MentionEntity entityWithName:@"Niklaus Wirth" entityId:@"22"],
                      [MentionEntity entityWithName:@"Richard Karp" entityId:@"23"],
                      [MentionEntity entityWithName:@"John Hopcroft" entityId:@"24"],
                      [MentionEntity entityWithName:@"Robert Tarjan" entityId:@"25"],
                      [MentionEntity entityWithName:@"John McCarthy" entityId:@"6"],  // DupeTesting: Second instance. New Page.
                      [MentionEntity entityWithName:@"John McCarthy" entityId:@"6"], // DupeTesting: Third instance. Same Page.
                      // Entity that has an autocorrect-able first name
                      [MentionEntity entityWithName:@"Asd Tarjan" entityId:@"26"],
                      [MentionEntity entityWithName:@"Asd Tarjan2 👍" entityId:@"27"],
                      [MentionEntity entityWithName:@"TEST @" entityId:@"28"],
                      // korean
                      [MentionEntity entityWithName:@"긴 기 ㅣ" entityId:@"29"],
                      // "asdf" on persian keyboard
                      [MentionEntity entityWithName:@"شسیب شسیب شسی شسیب شس" entityId:@"30"],
                      [MentionEntity entityWithName:@"😀😀 😁😁" entityId:@"31"],
                      // japanese
                      [MentionEntity entityWithName:@"らい" entityId:@"32"],
                      [MentionEntity entityWithName:@"Asd Tarjan2 👍👍" entityId:@"33"],
                      [MentionEntity entityWithName:@"😀FirstName1😀 😁LastName2😁" entityId:@"34"],
                      [MentionEntity entityWithName:@"🦋FirstName1🦋 🐛LastName2🐛" entityId:@"35"]];
}


#pragma mark - Protocol

// In this method, the plug-in gives us a mentions entity (one we previously returned in response to a query), and asks
//  us to provide a table view cell corresponding to that entity to be presented to the user.
- (UITableViewCell *)cellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                           withMatchString:(NSString *)matchString
                                 tableView:(UITableView *)tableView
                               atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"mentionsCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"mentionsCell"];
        cell.backgroundColor = LIGHT_GRAY_COLOR;
    }
    cell.textLabel.text = [entity entityName];
    cell.detailTextLabel.text = [entity entityId];
    return cell;
}

- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity tableView:(UITableView *)tableView {
    return 44;
}

// In this method, the plug-in gives us a search string and some metadata, as well as a block. Our responsibility is to
//  perform whatever work is necessary to get the entities for that search string (network call, database query, etc),
//  and then to call the completion block with an array of entity objects corresponding to the search string. See the
//  documentation for the method for more details.
- (void)asyncRetrieveEntitiesForKeyString:(NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void (^)(NSArray *, BOOL, BOOL))completionBlock {
    if (!completionBlock) {
        return;
    }
    if (type == HKWMentionsSearchTypeInitial) {
        return;
    }
    NSArray *data = self.fakeData;

    // This #define determines whether or not the first response should be returned in a synchronous or asynchronous
    //  manner. This is useful for testing purposes.
#define SHOULD_BE_SYNCHRONOUS

#ifdef SHOULD_BE_SYNCHRONOUS
    NSMutableArray *buffer = [NSMutableArray array];
    if ([keyString length] == 0) {
        buffer = [data copy];
    }
    else {
        for (id<HKWMentionsEntityProtocol> entity in data) {
            NSString *name = [entity entityName];
            if ([[self class] string:keyString isPrefixOfString:name]) {
                [buffer addObject:entity];
            }
        }
    }
    completionBlock([buffer copy], YES, YES);
#else
    // Pretend to do a network request.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *buffer = [NSMutableArray array];
        if ([keyString length] == 0) {
            buffer = [data copy];
        }
        else {
            for (id<HKWMentionsEntityProtocol> entity in data) {
                NSString *name = [entity entityName];
                if ([[self class] string:keyString isPrefixOfString:name]) {
                    [buffer addObject:entity];
                }
            }
        }
        // Simulate multi-loading
        if ([buffer count] > 10) {
            // This simulates a three-part response.
            // The first part is returned to the mentions plug-in immediately. The next segment is returned after 2
            //  seconds, and the third part is returned after 6 seconds.
            NSArray *firstBuffer = [buffer objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)]];
            NSArray *secondBuffer = [buffer objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 3)]];
            NSArray *finalBuffer = [buffer objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(6, [buffer count] - 6)]];
            completionBlock(firstBuffer, YES, NO);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completionBlock(secondBuffer, YES, NO);
            });
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                completionBlock(finalBuffer, YES, YES);
            });
        }
        else {
            // Normal, load all at once
            completionBlock([buffer copy], YES, YES);
        }
    });
#endif
}

// An optional method which allows us to specify whether or not a given entity can be 'trimmed'; for example, a mention
//  'John Doe' might be trimmed down to just 'John' by pressing the backspace key
- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol>)entity {
    return YES;
}

#ifdef USE_CUSTOM_TRIMMING_BEHAVIOR
- (NSString *)trimmedNameForEntity:(id<LIREMentionsEntityProtocol>)entity {
    NSString *name = [entity entityName];
    if ([name length] < 8) {
        return name;
    }
    return [name substringToIndex:8];
}
#endif

- (UITableViewCell *)loadingCellForTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"loadingCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"loadingCell"];
        cell.backgroundColor = LIGHT_GRAY_COLOR;
    }
    cell.textLabel.text = @"... LOADING ...";
    return cell;
}

- (CGFloat)heightForLoadingCellInTableView:(UITableView *)tableView {
    return 44;
}


#pragma mark - State change delegate

// The state-change delegate allows your app to optionally listen in on certain important events that might happen to
//  the mentions plug-in. For example, implementing the optional method below allows your app to be notified whenever a
//  new mention is successfully created.
- (void)mentionsPlugin:(id<HKWMentionsPlugin>)plugin
        createdMention:(id<HKWMentionsEntityProtocol>)entity
            atLocation:(NSUInteger)location {
    NSLog(@"Mentions plug-in created mention named \"%@\" at location %ld", [entity entityName], (long) location);
}

- (void)selected:(id<HKWMentionsEntityProtocol>)entity atIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Mentions plug-in selected entity named \"%@\" at index %ld", [entity entityName], (long) [indexPath row]);
}


#pragma mark - Utility

+ (BOOL)string:(NSString *)testString isPrefixOfString:(NSString *)compareString {
    if ([compareString length] == 0
        || [testString length] == 0
        || [compareString length] < [testString length]) {
        return NO;
    }
    NSString *prefix = ([testString length] == [compareString length]
                        ? compareString
                        : [compareString substringToIndex:[testString length]]);
    return [testString compare:prefix
                       options:(NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch)] == NSOrderedSame;
}

@end
