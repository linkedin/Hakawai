//
//  HKWTextView+Utilities.h
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
 This category provides a variety of useful utility methods that either plug-ins or consumers of the library may use.
 */
@interface HKWTextView (Utilities)

/*!
 Return the rectangle corresponding to the word immediately preceding the cursor. If there is no word preceding the
 cursor, the null rectangle is returned. The return value is relative to the coordinates of the parent text view.
 */
- (CGRect)rectForWordPrecedingCursor;

/*!
 Return the range for the word immediately preceding the cursor. If there is no word preceding the cursor, the range's
 location will be marked as the \c NSNotFound constant.
 */
- (NSRange)rangeForWordPrecedingCursor;

/*!
 Return the character preceding the given location. If the location is 0 or invalid, this method returns 0 (the null
 character).
 */
- (unichar)characterPrecedingLocation:(NSInteger)location;

@end
