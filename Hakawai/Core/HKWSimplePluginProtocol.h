//
//  HKWSimplePluginProtocol.h
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

@class HKWTextView;

/*!
 A protocol definining the interface for a simple plug-in.

 A simple plug-in is a module which deals primarily with affecting the state of newly inserted text, or changing the
 attributes of text the user has selected. Examples of simple plug-ins might be a module to enable bold text, or a
 module to insert inline images.
 */
@protocol HKWSimplePluginProtocol <NSObject>

@property (nonatomic, readonly) NSString *pluginName;
@property (nonatomic, weak) HKWTextView *parentTextView;

@optional

@end
