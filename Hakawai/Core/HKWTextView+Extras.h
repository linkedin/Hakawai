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

/*!
 This category provides a number of (hopefully) useful extra capabilities which may be used directly or by plug-ins.
 */
@interface HKWTextView (Extras)

/*!
 If YES, scrolling is prohibited. Less error-prone than setting the \c scrollingEnabled property.
 */
@property (nonatomic) BOOL disableVerticalScrolling;


#pragma mark - API (word utilities)

/*!
 Return the rectangle corresponding to the word immediately preceding the cursor. If there is no word preceding the
 cursor, the null rectangle is returned. The return value is relative to the coordinates of the parent text view.
 */
- (CGRect)rectForWordPrecedingCursor;

/*!
 Return the range for the word immediately preceding the location. If there is no word preceding the location, the
 range's location will be marked as the \c NSNotFound constant.

 \param location    the location from where to begin searching
 \param toEnd       whether or not the reported range should encompass the entire word, not just the length from the
 beginning of the word to \c location
 */
- (NSRange)rangeForWordPrecedingLocation:(NSUInteger)location searchToEnd:(BOOL)toEnd;

/*!
 Return the range for the word immediately preceding the current selection range's start location. If there is no word
 preceding the location, this method returns the \c NSNotFound constant.
 */
- (NSRange)rangeForWordPrecedingCursor;

/*!
 Return the character preceding the given location. If the location is 0 or invalid, this method returns 0 (the null
 character).
 */
- (unichar)characterPrecedingLocation:(NSInteger)location;

/**
 Returns whether the user is currently engaging in a long press gesture by querying the state of the view's long press gesture recognizers

 @return Boolean indicating whether the user is currently long pressing
 */
- (BOOL)isCurrentlyLongPressing;

@end
