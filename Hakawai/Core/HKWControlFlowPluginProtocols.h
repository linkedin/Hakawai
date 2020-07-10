//
//  HKWControlFlowPluginProtocols.h
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
#import <UIKit/UIKit.h>

#import "HKWSimplePluginProtocol.h"
#import "HKWAbstractionLayer.h"

@class HKWTextView;

/*!
 A protocol definining the interface for a control flow plug-in.

 A control flow plug-in is a module which temporarily takes control of the editor text view in order to perform a
 complex action. An example of a control flow plugin might be a module to insert 'mentions', like the mentions supported
 by the apps of certain large social networking sites.

 \note The \c HKWControlFlowPluginProtocol inherits from the \c UITextViewDelegate protocol.
 */
@protocol HKWDirectControlFlowPluginProtocol <UITextViewDelegate, HKWSimplePluginProtocol>
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

/*!
 If available, this method is called when the text view is programatically updated (e.g. setText: or setAttributedText:)
 */
-(void) textViewDidProgrammaticallyUpdate:(UITextView *)textView;

@end

@protocol HKWAbstractionLayerControlFlowPluginProtocol <HKWAbstractionLayerDelegate, HKWSimplePluginProtocol>
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

/*!
 If available, this method is called when the text view is programatically updated (e.g. setText: or setAttributedText:)
 */
-(void) textViewDidProgrammaticallyUpdate:(UITextView *)textView;

// UITextViewDelegate optional helper methods
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView;
- (BOOL)textViewShouldEndEditing:(UITextView *)textView;
- (void)textViewDidBeginEditing:(UITextView *)textView;
- (void)textViewDidEndEditing:(UITextView *)textView;
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange;
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange;

@end
