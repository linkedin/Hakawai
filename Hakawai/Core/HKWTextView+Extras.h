//
//  HKWTextView+Extras.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWTextView.h"

@interface HKWTextView (Extras)

/*!
 If YES, scrolling is prohibited. Less error-prone than setting the \c scrollingEnabled property.
 */
@property (nonatomic) BOOL disableVerticalScrolling;


#pragma mark - Autoediting-related APIs

/*!
 A property allowing a plug-in to inform the text view as to whether or not attempts by the autocorrect/predictive text
 system should be ignored.

 \warning This property is ignored if the abstraction layer is in use. The abstraction layer uses a different mechanism
 to accept or ignore attempted changes to the text view.
 */
@property (nonatomic) BOOL shouldRejectAutocorrectInsertions;

/*!
 If an autocorrect suggestion is currently being proposed, reject it. Otherwise, this method does nothing.
 */
- (void)dismissAutocorrectSuggestion;

/*!
 Temporarily override the text view's autocapitalization mode.
 */
- (void)overrideAutocapitalizationWith:(UITextAutocapitalizationType)override;

/*!
 If the text view's autocapitalization mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
                       in the process of losing its first responder status
 */
- (void)restoreOriginalAutocapitalization:(BOOL)shouldCycle;

/*!
 Temporarily override the text view's autocorrection mode.
 */
- (void)overrideAutocorrectionWith:(UITextAutocorrectionType)override;

/*!
 If the text view's autocorrection mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
                       in the process of losing its first responder status
 */
- (void)restoreOriginalAutocorrection:(BOOL)shouldCycle;

/*!
 Temporarily override the text view's spell checking mode.
 */
- (void)overrideSpellCheckingWith:(UITextSpellCheckingType)override;

/*!
 If the text view's spell checking mode was previously overriden, restore the original mode.
 \param shouldCycle    whether or not the first responder status should be cycled or not; set to NO if the text view is
                       in the process of losing its first responder status
 */
- (void)restoreOriginalSpellChecking:(BOOL)shouldCycle;

@end
