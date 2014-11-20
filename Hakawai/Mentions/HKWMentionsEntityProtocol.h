//
//  HKWMentionsEntityProtocol.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <Foundation/Foundation.h>

/*!
 A protocol describing the expected form of 'entity' objects provided by the mention plug-in's data source. Entity
 objects must provide a human-readable name and an ID value. An optional dictionary can contain custom info used to
 format the mentions cells and send up to the server.
 */
@protocol HKWMentionsEntityProtocol <NSObject>

- (NSString *)entityId;
- (NSString *)entityName;
- (NSDictionary *)entityMetadata;

@optional

/*!
 Return a value for a custom key. This method assumes that the consumer has at least an informal agreement as to what
 custom keys are supported and what their potential values can be. It is intended to allow concrete instances of
 mentions entity to provide safe access to custom keys stored within their metadata dictionary.
 */
- (id)valueForCustomKey:(NSString *)customKey;

/*!
 Return a unique ID describing the mentions entity. This is used for deduping records. Depending on the data set,
 the entityId might not be unique enough if IDs were to overlap between different data sets.

 Example: You have an entry in your person DB with an ID of 12345. You also have an entry in your company DB with
          an ID of 12345. A way to differentiate these would be to return a uniqueId that concatenates the type
          and ID: "person_12345" and "company_12345"

 The deduping logic that checks this value will default to using the entityId if a uniqueId is not provided.
 */
- (NSString *)uniqueId;

@end
