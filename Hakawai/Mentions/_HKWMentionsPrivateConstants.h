//
//  _HKWMentionsPrivateConstants.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "_HKWPrivateConstants.h"

#ifndef Hakawai__HKWMentionsPrivateConstants_h
#define Hakawai__HKWMentionsPrivateConstants_h

// Comment this out if state transitions should not be explicitly logged.
//#define LOG_STATE_TRANSITIONS

#if defined(DEBUG) && defined(LOG_STATE_TRANSITIONS)
#define HKW_STATE_LOG(msg, ...) NSLog(msg, ##__VA_ARGS__)
#else
#define HKW_STATE_LOG(msg, ...)
#endif

#endif
