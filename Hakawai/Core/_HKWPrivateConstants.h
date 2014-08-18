//
//  _HKWPrivateConstants.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#ifndef Hakawai_HKWPrivateConstants_h
#define Hakawai_HKWPrivateConstants_h

#define FULL_RANGE(__x__) NSMakeRange(0, [__x__ length])

#ifdef DEBUG
#define HKWLOG(msg, ...) NSLog(msg, ##__VA_ARGS__)
#else
#define HKWLOG(msg, ...)
#endif

#define HKW_DESCRIBE_FRAME(__frame, __msg) HKWLOG(@"frame (%@, origin: (%f, %f), width: %f, height: %f)", (__msg), \
(__frame).origin.x, (__frame).origin.y, (__frame).size.width, (__frame).size.height)

// ifndef
#endif