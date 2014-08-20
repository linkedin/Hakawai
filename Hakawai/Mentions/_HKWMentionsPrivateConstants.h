//
//  _HKWMentionsPrivateConstants.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWPrivateConstants.h"

#ifndef Hakawai__HKWMentionsPrivateConstants_h
#define Hakawai__HKWMentionsPrivateConstants_h

// Comment this out if state transitions should not be explicitly logged.
//#define HKW_LOG_STATE_TRANSITIONS

#if defined(DEBUG) && defined(HKW_LOG_STATE_TRANSITIONS)
#define HKW_STATE_LOG(msg, ...) NSLog(msg, ##__VA_ARGS__)
#else
#define HKW_STATE_LOG(msg, ...)
#endif

#endif
