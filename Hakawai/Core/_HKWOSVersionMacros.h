//
//  _HKWOSVersionMacros.h
//  Hakawai
//
//  Created by Carl Jahn
//  Copyright (c) 2013 Carl Jahn. All rights reserved.
//

///---------------------------
/// @name Runtime Checks
///---------------------------

#ifndef __IPHONE_5_0
#define __IPHONE_5_0     50000
#endif
#ifndef __IPHONE_5_1
#define __IPHONE_5_1     50100
#endif
#ifndef __IPHONE_6_0
#define __IPHONE_6_0     60000
#endif
#ifndef __IPHONE_6_1
#define __IPHONE_6_1     60100
#endif
#ifndef __IPHONE_7_0
#define __IPHONE_7_0     70000
#endif
#ifndef __IPHONE_7_1
#define __IPHONE_7_1     70100
#endif
#ifndef __IPHONE_8_0
#define __IPHONE_8_0     80000
#endif

//If the symbol for iOS 5 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_5_0
#define NSFoundationVersionNumber_iOS_5_0 881.00
#endif

#ifdef NSFoundationVersionNumber_iOS_5_0
#define _iOS_5_0 NSFoundationVersionNumber_iOS_5_0
#endif

//If the symbol for iOS 5.1 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_5_1
#define NSFoundationVersionNumber_iOS_5_1 890.10
#endif

#ifdef NSFoundationVersionNumber_iOS_5_1
#define _iOS_5_1 NSFoundationVersionNumber_iOS_5_1
#endif

//If the symbol for iOS 6.0 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_6_0
#define NSFoundationVersionNumber_iOS_6_0 993.00 //extracted from iOS 7 Header
#endif

#ifdef NSFoundationVersionNumber_iOS_6_0
#define _iOS_6_0 NSFoundationVersionNumber_iOS_6_0
#endif

//If the symbol for iOS 6.1 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_6_1
#define NSFoundationVersionNumber_iOS_6_1 993.00 //extracted from iOS 7 Header
#endif

#ifdef NSFoundationVersionNumber_iOS_6_1
#define _iOS_6_1 NSFoundationVersionNumber_iOS_6_1
#endif

//If the symbol for iOS 7 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_7_0
#define NSFoundationVersionNumber_iOS_7_0 1047.00 //extracted from iOS 7 Header
#endif

#ifdef NSFoundationVersionNumber_iOS_7_0
#define _iOS_7_0 NSFoundationVersionNumber_iOS_7_0
#endif

//If the symbol for iOS 7.1 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_7_1
#define NSFoundationVersionNumber_iOS_7_1 1047.25 //extracted from iOS 8 Header
#endif

#ifdef NSFoundationVersionNumber_iOS_7_1
#define _iOS_7_1 NSFoundationVersionNumber_iOS_7_1
#endif

//If the symbol for iOS 8 isnt defined, define it.
#ifndef NSFoundationVersionNumber_iOS_8_0
#define NSFoundationVersionNumber_iOS_8_0 1134.10 //extracted with NSLog(@"%f", NSFoundationVersionNumber)
#endif

#ifdef NSFoundationVersionNumber_iOS_8_0
#define _iOS_8_0 NSFoundationVersionNumber_iOS_8_0
#endif

/**
 Runtime check for the current version Nummer.
 checks ( CURRENT_VERSION_NUMBR == GIVEN_VERSION_NUMBER)
 @_gVersion - the given Version Number. aka (_iOS_7_0 or NSFoundationVersionNumber_iOS_7_0 and so on)
 */
#define HKW_SYSTEM_VERSION_EQUAL_TO(_gVersion)                  ( fabsf(NSFoundationVersionNumber - _gVersion) < DBL_EPSILON )

/**
 Runtime check for the current version Nummer.
 checks CURRENT_VERSION_NUMBER > GIVEN_VERSION_NUMBER
 @_gVersion - the given Version Number. aka (_iOS_7_0 or NSFoundationVersionNumber_iOS_7_0 and so on)
 */
#define HKW_SYSTEM_VERSION_GREATER_THAN(_gVersion)              ( NSFoundationVersionNumber >  _gVersion )

/**
 Runtime check for the current version Nummer.
 checks CURRENT_VERSION_NUMBER >= GIVEN_VERSION_NUMBER
 @_gVersion - the given Version Number. aka (_iOS_7_0 or NSFoundationVersionNumber_iOS_7_0 and so on)
 */
#define HKW_SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(_gVersion)  ( NSFoundationVersionNumber > _gVersion || HKW_SYSTEM_VERSION_EQUAL_TO(_gVersion) )


/**
 Runtime check for the current version Nummer.
 checks CURRENT_VERSION_NUMBER < GIVEN_VERSION_NUMBER
 @_gVersion - the given Version Number. aka (_iOS_7_0 or NSFoundationVersionNumber_iOS_7_0 and so on)
 */
#define HKW_SYSTEM_VERSION_LESS_THAN(_gVersion)                 ( NSFoundationVersionNumber <  _gVersion )


/**
 Runtime check for the current version Nummer.
 checks CURRENT_VERSION_NUMBER <= GIVEN_VERSION_NUMBER
 @_gVersion - the given Version Number. aka (_iOS_7_0 or NSFoundationVersionNumber_iOS_7_0 and so on)
 */
#define HKW_SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(_gVersion)     ( NSFoundationVersionNumber < _gVersion || HKW_SYSTEM_VERSION_EQUAL_TO(_gVersion)
