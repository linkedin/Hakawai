//
//  HKWTextView+Extras.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWTextView.h"

@interface HKWTextView (Extras)

/*!
 If YES, scrolling is prohibited. Less error-prone than setting the \c scrollingEnabled property.
 */
@property (nonatomic) BOOL disableVerticalScrolling;


#pragma mark - Autoediting-related APIs

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
