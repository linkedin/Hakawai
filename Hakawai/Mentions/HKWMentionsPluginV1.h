//
//  HKWMentionsPluginV1.h
//  Hakawai
//
//  Created by Binya Koatz on 7/29/20.
//  Copyright © 2020 LinkedIn. All rights reserved.
//

#import "HKWMentionsPlugin.h"

// Don't confuse this with the public 'HKWMentionsPluginState', which exposes fewer implementation details.
typedef NS_ENUM(NSInteger, HKWMentionsState) {
    // The user is not creating a mention and not in any of the following states.
    HKWMentionsStateQuiescent = 0,

    // The user is currently creating a mention.
    HKWMentionsStartDetectionStateCreatingMention,

    // The user's cursor is currently positioned at the right edge of a mention. Pressing 'delete' again will select the
    //  mention.
    HKWMentionsStateAboutToSelectMention,

    // The user has selected a mention. Deleting text should trim or remove the mention. Inserting text should bleach
    //  the mention.
    HKWMentionsStateSelectedMention,

    // The mentions plugin's text view has lost focus and cleanup is happening. This is a transient state that is
    //  intended to last only as long as textViewDidEndEditing: is running, and allow cleanup code to properly engage
    //  special-case behavior needed for cleanup.
    HKWMentionsStateLosingFocus
};

NS_ASSUME_NONNULL_BEGIN

@interface HKWMentionsPluginV1 : NSObject <HKWMentionsPlugin>
@end

NS_ASSUME_NONNULL_END
