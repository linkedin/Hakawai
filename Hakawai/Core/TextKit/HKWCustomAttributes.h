//
//  HKWCustomAttributes.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "HKWRoundedRectBackgroundAttributeValue.h"

/*!
 An attribute which draws text with a rounded rectangle background effect.

 Rounded rectangle background attributes should be paired with \c HKWRoundedRectBackgroundAttributeValue objects.

 \warning Don't apply this attribute to more than three lines' worth of contiguous text, as visual glitches will occur.
 I suspect this may be a problem with the layout manager methods which return bounding rects.
 */
static NSString* const HKWRoundedRectBackgroundAttributeName = @"HKWRoundedRectBackgroundAttributeName";
