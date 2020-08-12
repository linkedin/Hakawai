//
//  HKWMentionsPluginV2.h
//  Hakawai
//
//  Created by Binya Koatz on 7/29/20.
//  Copyright © 2020 LinkedIn. All rights reserved.
//

#import "HKWMentionsPlugin.h"

NS_ASSUME_NONNULL_BEGIN

@interface HKWMentionsPluginV2 : NSObject <HKWMentionsPlugin>

/*!
 Instantiate a mentions plug-in with the specified chooser mode, no control characters, and a default search length of
 3 characters.
 */
+ (nonnull instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, and search length.

 \param controlCharacterSet    a \c NSCharacterSet containing the character or characters that should be used to begin
                               an explicit mention, or nil if explicit mentions should not be enabled
 \param searchLength           the number of characters to wait before beginning an implicit mention, or 0 or a negative
                               value if implicit mentions should not be enabled
 */
+ (nonnull instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *_Null_unspecified)controlCharacterSet
                                 searchLength:(NSInteger)searchLength;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, search length, a color for
 unselected mentions text, and a background color and text color for selected mentions text.
 */
+ (nonnull instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *_Null_unspecified)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                              unselectedColor:(UIColor *_Null_unspecified)unselectedColor
                                selectedColor:(UIColor *_Null_unspecified)selectedColor
                      selectedBackgroundColor:(UIColor *_Null_unspecified)selectedBackgroundColor;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, search length, custom attributes
 to apply to unselected mentions, and custom attributes to apply to selected mentions.
 */
+ (nonnull instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *_Null_unspecified)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                  unselectedMentionAttributes:(NSDictionary *_Null_unspecified)unselectedAttributes
                    selectedMentionAttributes:(NSDictionary *_Null_unspecified)selectedAttributes;

@end

NS_ASSUME_NONNULL_END
