//
//  HKWControlFlowPluginProtocol.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "HKWSimplePluginProtocol.h"

@class HKWTextView;

/*!
 A protocol definining the interface for a control flow plug-in.

 A control flow plug-in is a module which temporarily takes control of the editor text view in order to perform a
 complex action. An example of a control flow plugin might be a module to insert 'mentions', like the mentions supported
 by the apps of certain large social networking sites.

 \note The \c HKWControlFlowPluginProtocol inherits from the \c UITextViewDelegate protocol.
 */
@protocol HKWControlFlowPluginProtocol <UITextViewDelegate, HKWSimplePluginProtocol>
@optional

/*!
 If available, this method is called when the text view is in single line viewport mode, but the viewport changes (e.g.
 because the user typed text that spilled over onto the next line).
 */
- (void)singleLineViewportChanged;

/*!
 If available, this method is called when the text view is in single line viewport mode, tap interception is enabled,
 and the user tapped on the text view somewhere.
 */
- (void)singleLineViewportTapped;

@end
