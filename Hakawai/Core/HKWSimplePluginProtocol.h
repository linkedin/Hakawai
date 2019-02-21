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

/// A string containing a unique identifier for this plug-in
@property (nonatomic, readonly) NSString *pluginName;

/// A weak reference to the \c HKWTextView instance owning this plug-in currently; it is set and unset automatically
@property (nonatomic, weak) HKWTextView *parentTextView;

/*!
 Perform any initial setup required when the plug-in is first registered to a text view.

 \note This method is called after the parent text view sets the plug-in's \c parentTextView property.
 */
- (void)performInitialSetup;

/*!
 Perform any final cleanup required when the plug-in is unregistered from a text view.

 \note This method is called before the parent text view nils out the plug-in's \c parentTextView property.
 */
- (void)performFinalCleanup;

@optional

/// This property holds the `string` added in the `HKWTextView` via dictation
@property (nonatomic, strong, readwrite) NSString *dictationString;

@end
