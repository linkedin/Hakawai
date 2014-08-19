//
//  HKWSimplePluginProtocol.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
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
