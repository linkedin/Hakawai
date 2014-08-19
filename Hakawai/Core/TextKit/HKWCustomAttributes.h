//
//  HKWCustomAttributes.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import "HKWRoundedRectBackgroundAttributeValue.h"

/*!
 An attribute which draws text with a rounded rectangle background effect.

 Rounded rectangle background attributes should be paired with \c HKWRoundedRectBackgroundAttributeValue objects.

 \warning Don't apply this attribute to more than three lines' worth of contiguous text, as visual glitches will occur.
 I suspect this may be a problem with the layout manager methods which return bounding rects.
 */
static NSString* const HKWRoundedRectBackgroundAttributeName = @"HKWRoundedRectBackgroundAttributeName";
