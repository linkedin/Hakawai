//
//  _HKWPrivateConstants.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#ifndef Hakawai_HKWPrivateConstants_h
#define Hakawai_HKWPrivateConstants_h

#define HKW_FULL_RANGE(__x__) NSMakeRange(0, [__x__ length])

#ifdef DEBUG
#define HKWLOG(msg, ...) NSLog(msg, ##__VA_ARGS__)
#else
#define HKWLOG(msg, ...)
#endif

#define HKW_DESCRIBE_FRAME(__frame, __msg) HKWLOG(@"frame (%@, origin: (%f, %f), width: %f, height: %f)", (__msg), \
(__frame).origin.x, (__frame).origin.y, (__frame).size.width, (__frame).size.height)

BOOL HKW_systemVersionIsAtLeast(NSString *version);

// ifndef
#endif