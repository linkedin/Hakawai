//
//  _HKWMentionsPlugin.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWMentionsPlugin.h"

@interface HKWMentionsPlugin ()

@property (nonatomic, strong) NSCharacterSet *controlCharacterSet;
@property (nonatomic) NSInteger implicitSearchLength;
@property (nonatomic, readonly) BOOL implicitMentionsEnabled;

@property (nonatomic) BOOL shouldEnableUndoUponUnregistration;

@end
