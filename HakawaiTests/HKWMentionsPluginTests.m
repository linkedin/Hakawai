//
//  HKWMentionsPluginTests.m
//  Hakawai
//
//  Created by Matthew Schouest on 8/17/17.
//  Copyright (c) 2017 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView.h"
#import "HKWTextView+Plugins.h"
#import "HKWMentionsPlugin.h"
#import "HKWMentionsPluginV1.h"
#import "HKWMentionsPluginV2.h"
#import "HKWMentionsAttribute.h"
#import "HKWCustomAttributes.h"

@interface HKWMentionsPluginV1 ()
- (BOOL)stringValidForMentionsCreation:(NSString *)string;
@end

@interface HKWMentionsPluginV2 ()
- (BOOL)stringValidForMentionsCreation:(NSString *)string;
@end

// Methods for testing attribute values/ranges in pluginV2
@interface HKWMentionsPluginV2 (Testing)
- (id)valueForAttributeWithName:(NSAttributedStringKey)attrName forWordOfLength:(NSUInteger)length;
- (NSRange)rangeForAttributeWithName:(NSAttributedStringKey)attrName forWordOfLength:(NSUInteger)length;
@end

@implementation HKWMentionsPluginV2 (Testing)

- (id)valueForAttributeWithName:(NSAttributedStringKey)attrName forWordOfLength:(NSUInteger)length {
    __block id returnValue;
    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView.attributedText  enumerateAttributesInRange:NSMakeRange(parentTextView.attributedText.length-length, length)
                                                       options:0
                                                    usingBlock:^(NSDictionary *attrs, __unused NSRange range, __unused BOOL *stop) {
        id value = attrs[attrName];
        if (!value) {
            return;
        }
        returnValue = value;
    }];
    return returnValue;
}

- (NSRange)rangeForAttributeWithName:(NSAttributedStringKey)attrName forWordOfLength:(NSUInteger)length {
    __block NSRange returnRange;
    __strong __auto_type parentTextView = self.parentTextView;
    [parentTextView.attributedText  enumerateAttributesInRange:NSMakeRange(parentTextView.attributedText.length-length, length)
                                                       options:0
                                                    usingBlock:^(NSDictionary *attrs, NSRange range, __unused BOOL *stop) {
        id value = attrs[attrName];
        if (!value) {
            return;
        }
        returnRange = range;
    }];
    return returnRange;
}

@end

@interface HKWDummyMentionsDefaultChooserViewDelegate : NSObject <HKWMentionsDefaultChooserViewDelegate>

@property (nonatomic) NSArray<NSString *> *trimmableStrings;

- (instancetype)initWithTrimmableStrings:(NSArray<NSString *> *)trimmableStrings;

- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity;

- (nonnull NSString *)trimmedNameForEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity;

@end

@implementation HKWDummyMentionsDefaultChooserViewDelegate

- (instancetype)initWithTrimmableStrings:(NSArray<NSString *> *)trimmableStrings;
{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.trimmableStrings = trimmableStrings;
    return self;
}

- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity {
    return [self.trimmableStrings containsObject:entity.entityName];
}

- (nonnull NSString *)trimmedNameForEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity {
    return [entity.entityName componentsSeparatedByString:@" "][0];
}

- (void)asyncRetrieveEntitiesForKeyString:(nonnull NSString *)keyString searchType:(HKWMentionsSearchType)type controlCharacter:(unichar)character completion:(void (^ _Null_unspecified)(NSArray * _Null_unspecified, BOOL, BOOL))completionBlock {
}


- (UITableViewCell * _Null_unspecified)cellForMentionsEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity withMatchString:(NSString * _Null_unspecified)matchString tableView:(UITableView * _Null_unspecified)tableView atIndexPath:(NSIndexPath * _Null_unspecified)indexPath {
    return nil;
}


- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity tableView:(UITableView * _Null_unspecified)tableView {
    return 0.0;
}


@end

SpecBegin(mentionPluginsSetup)

describe(@"basic mentions plugin setup - MENTIONS PLUGIN V1", ^{
    __block HKWTextView *textView;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = NO;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly register and unregister mentions plug-in", ^{
        HKWMentionsPluginV1 *plugin = [HKWMentionsPluginV1 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        // Add plug-ins
        [textView setControlFlowPlugin:plugin];
        expect([textView controlFlowPlugin]).to.beKindOf(HKWMentionsPluginV1.class);

        // Check parentTextView
        expect(plugin.parentTextView).to.equal(textView);

        // Remove plug-in
        textView.controlFlowPlugin = nil;
        expect(textView.controlFlowPlugin).to.beNil;
        expect(plugin.parentTextView).to.beNil;
    });
});

describe(@"basic mentions plugin setup - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly register and unregister mentions plug-in", ^{
        HKWMentionsPluginV2 *plugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        // Add plug-ins
        [textView setControlFlowPlugin:plugin];
        expect([textView controlFlowPlugin]).to.beKindOf(HKWMentionsPluginV2.class);

        // Check parentTextView
        expect(plugin.parentTextView).to.equal(textView);

        // Remove plug-in
        textView.controlFlowPlugin = nil;
        expect(textView.controlFlowPlugin).to.beNil;
        expect(plugin.parentTextView).to.beNil;
    });
});

describe(@"inserting and reading mentions - MENTIONS PLUGIN V1", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV1 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = NO;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV1 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should properly return mentions", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"Asdf ghjkl" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"Qwerty Uiop" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);
        

        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];

        expect(mentionsPlugin.mentions.count).to.equal(2);
    });

    it(@"should properly handle mentions containing emoji", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"Asdf ghjk🐝" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"Qwerty👨‍👩‍👧‍👧 Uiop" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);
        

        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);
    });

    it(@"should properly handle mentions containing only emoji", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"🐝🙅‍♂️ 👨‍👨‍👧👔" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"🦎🌘" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];

        expect(mentionsPlugin.mentions.count).to.equal(2);
    });
});

describe(@"inserting and reading mentions - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should properly return mentions", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"Asdf ghjkl" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"Qwerty Uiop" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];

        expect(mentionsPlugin.mentions.count).to.equal(2);
    });

    it(@"should properly handle mentions containing emoji", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"Asdf ghjk🐝" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"Qwerty👨‍👩‍👧‍👧 Uiop" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);


        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);
    });

    it(@"should properly handle mentions containing only emoji", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"🐝🙅‍♂️ 👨‍👨‍👧👔" identifier:@"1"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"🦎🌘" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        [textView insertText:@" "];

        [textView insertText:m2.mentionText];
        m2.range = NSMakeRange(m1.mentionText.length + 1, m2.mentionText.length);
        [mentionsPlugin addMention:m2];

        expect(mentionsPlugin.mentions.count).to.equal(2);
    });
});

describe(@"mentions validation - MENTIONS PLUGIN V1", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV1 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = NO;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV1 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"check the string validation for dictation string", ^{
        NSString *const mentionString = @"Alan Perkis";

        // Multi word string should not be valid for mentions creation
        BOOL isStringValid = [mentionsPlugin stringValidForMentionsCreation:mentionString];
        expect(isStringValid).to.equal(NO);

        // Multi word string should be valid for mentions creation, only if it matches the dictation string
        [mentionsPlugin setDictationString:mentionString];
        isStringValid = [mentionsPlugin stringValidForMentionsCreation:mentionString];
        expect(isStringValid).to.equal(YES);
    });
});

describe(@"mentions validation - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"check the string validation for dictation string", ^{
        NSString *const mentionString = @"Alan Perkis";

        // Multi word string should not be valid for mentions creation
        BOOL isStringValid = [mentionsPlugin stringValidForMentionsCreation:mentionString];
        expect(isStringValid).to.equal(NO);

        // Multi word string should be valid for mentions creation, only if it matches the dictation string
        [mentionsPlugin setDictationString:mentionString];
        isStringValid = [mentionsPlugin stringValidForMentionsCreation:mentionString];
        expect(isStringValid).to.equal(YES);
    });
});

describe(@"deleting and reading mentions - MENTIONS PLUGIN V1", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV1 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = NO;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV1 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should properly handle mention deletion", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"Asdf ghjkl" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // the first attempt to delete mention should select the mention and modify the state. No changes apply to the mention and text
        BOOL deletionResult1 = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(m1.mentionText.length-1, 1) replacementText:@""];
        expect(deletionResult1).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // the second attempt deletes the whole mention
        BOOL deletionResult2 = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(m1.mentionText.length-1, 1) replacementText:@""];
        expect(deletionResult2).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(0);
        expect([textView.text length]).to.equal(0);
        

    });
});

describe(@"deleting and reading mentions - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should properly handle mention deletion - no personalization", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1

        // delete the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(m1.mentionText.length-1, 1) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(0);
        expect([textView.text length]).to.equal(0);
    });

    it(@"should properly handle range mention deletion - no personalization - intersects beginning/end", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName1 LastName1" identifier:@"2"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:@"FirstName2 LastName2" identifier:@"3"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord ";
        [textView insertText:string];
        [textView insertText:m2.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        m2.range = NSMakeRange(m1.mentionText.length + string.length, m2.mentionText.length);

        [mentionsPlugin addMention:m1];
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);

        // Text is:
        // FirstName1 LastName1 NonMentionWord FirstName2 LastName2

        // delete the both mentions
        NSUInteger middleOfMention1Location = m1.mentionText.length/2;
        NSUInteger lenthPastMention2 = m1.mentionText.length+string.length+m2.mentionText.length/2-middleOfMention1Location;
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(middleOfMention1Location, lenthPastMention2) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(0);
        expect([textView.text length]).to.equal(0);
    });

    it(@"should properly handle range mention deletion with trimming - personalization - intersects beginning/end", ^{
        NSString *firstString = @"FirstName1 LastName1";
        NSString *secondString = @"FirstName2 LastName2";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString, secondString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"4"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:secondString identifier:@"5"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord ";
        [textView insertText:string];
        [textView insertText:m2.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        m2.range = NSMakeRange(m1.mentionText.length + string.length, m2.mentionText.length);

        [mentionsPlugin addMention:m1];
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);

        // Text is:
        // FirstName1 LastName1 NonMentionWord FirstName2 LastName2

        // personalize both mentions
        NSUInteger middleOfMention1 = m1.mentionText.length/2;
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(middleOfMention1, m1.mentionText.length+string.length+m2.mentionText.length/2-middleOfMention1) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect([textView.text length]).to.equal(m1.mentionText.length + m2.mentionText.length);
        expect(textView.text).to.equal([NSString stringWithFormat:@"%@%@", [delegate trimmedNameForEntity:m1], [delegate trimmedNameForEntity:m2]]);
    });

    it(@"deletion range before mention - normal", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"6"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        NSString *string = @"NonMentionWord ";
        [textView insertText:string];
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(string.length, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // NonMentionWord FirstName1 LastName1

        // delete the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, string.length) replacementText:@""];
        expect(deletionResult).to.equal(YES);
    });

    it(@"deletion range after mention - normal", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"7"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord";
        [textView insertText:string];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1 NonMentionWord

        // delete the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(m1.mentionText.length, string.length) replacementText:@""];
        expect(deletionResult).to.equal(YES);
    });

    it(@"range within mention - delete mention", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"8"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1

        // delete the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, m1.mentionText.length-2) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(0);
        expect([textView.text length]).to.equal(0);
    });

    it(@"range within mention - personalize mention", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"9"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1

        // personalize the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, m1.mentionText.length-2) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(1);
        expect([textView.text length]).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName1");
    });

    it(@"deletion range includes mention - normal", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"10"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        NSString *string1 = @"NonMentionWord ";
        [textView insertText:string1];
        [textView insertText:m1.mentionText];
        NSString *string2 = @" NonMentionWord";
        [textView insertText:string2];
        m1.range = NSMakeRange(string1.length, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // NonMentionWord FirstName1 LastName1 NonMentionWord

        // delete all the text
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, string1.length + m1.mentionText.length + string2.length) replacementText:@""];

        expect(deletionResult).to.equal(YES);
    });

    it(@"range within first half of mention - personalize mention", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"11"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord";
        [textView insertText:string];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1 NonMentionWord

        // personalize the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, m1.mentionText.length-1+string.length) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(1);
        expect([textView.text length]).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName1");
    });

    it(@"range within second half of mention - personalize mention", ^{
        NSString *firstString = @"FirstName1 LastName1";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"12"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord";
        [textView insertText:string];
        m1.range = NSMakeRange(0, m1.mentionText.length);

        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName1 LastName1 NonMentionWord

        // personalize the whole mention
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(m1.mentionText.length/2+1, m1.mentionText.length/2-1+string.length) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(1);
        expect([textView.text length]).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName1");
    });

    it(@"should properly handle range mention deletion with trimming - personalization - intersects beginning/end - PERSIAN", ^{
        NSString *firstString = @"شسیب شسیب";
        NSString *secondString = @"شسیب شسیب";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString, secondString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"6"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:secondString identifier:@"7"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord ";
        [textView insertText:string];
        [textView insertText:m2.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        m2.range = NSMakeRange(m1.mentionText.length + string.length, m2.mentionText.length);

        [mentionsPlugin addMention:m1];
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);

        // Text is:
        // FirstName1 LastName1 NonMentionWord FirstName2 LastName2

        // personalize both mentions
        NSUInteger middleOfMention1 = m1.mentionText.length/2;
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(middleOfMention1, m1.mentionText.length+string.length+m2.mentionText.length/2-middleOfMention1) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect([textView.text length]).to.equal(m1.mentionText.length + m2.mentionText.length);
        expect(textView.text).to.equal([NSString stringWithFormat:@"%@%@", [delegate trimmedNameForEntity:m1], [delegate trimmedNameForEntity:m2]]);
    });

    it(@"should properly handle range mention deletion with trimming - personalization - intersects beginning/end EMOJI", ^{
        NSString *firstString = @"😁FirstName1😁 LastName1😁";
        NSString *secondString = @"😁FirstName2😁 LastName2😁";
        HKWDummyMentionsDefaultChooserViewDelegate *delegate = [[HKWDummyMentionsDefaultChooserViewDelegate alloc] initWithTrimmableStrings:@[firstString, secondString]];
        mentionsPlugin.defaultChooserViewDelegate = delegate;
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:firstString identifier:@"8"];
        HKWMentionsAttribute *m2 = [HKWMentionsAttribute mentionWithText:secondString identifier:@"9"];

        expect(mentionsPlugin.mentions.count).to.equal(0);

        [textView insertText:m1.mentionText];
        NSString *string = @" NonMentionWord ";
        [textView insertText:string];
        [textView insertText:m2.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        m2.range = NSMakeRange(m1.mentionText.length + string.length, m2.mentionText.length);

        [mentionsPlugin addMention:m1];
        [mentionsPlugin addMention:m2];
        expect(mentionsPlugin.mentions.count).to.equal(2);

        // Text is:
        // FirstName1 LastName1 NonMentionWord FirstName2 LastName2

        // personalize both mentions
        NSUInteger middleOfMention1 = [m1.mentionText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 8;
        NSUInteger mentionLength1 = [m1.mentionText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
        NSUInteger middleOfMention2 = [m2.mentionText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 8;
        BOOL deletionResult = [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(middleOfMention1, mentionLength1+string.length+middleOfMention2-middleOfMention1) replacementText:@""];
        expect(deletionResult).to.equal(NO);
        expect(mentionsPlugin.mentions.count).to.equal(2);
        NSUInteger newMentionLength1 = [m1.mentionText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
        NSUInteger newMentionLength2 = [m2.mentionText lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
        NSUInteger textViewLength = [textView.text lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4;
        expect(textViewLength).to.equal(newMentionLength1 + newMentionLength2);
        expect(textView.text).to.equal([NSString stringWithFormat:@"%@%@", [delegate trimmedNameForEntity:m1], [delegate trimmedNameForEntity:m2]]);
    });
});

describe(@"pasting mentions - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"paste mention inside mention", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName LastName

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length);
        [textView copy:nil];
        // Paste FirstName LastName in middle of existing FirstName LastName, leaving:
        // FirstName|FirstName LastName| LastName, where || denote mention attributes
        textView.selectedRange = NSMakeRange(m1.mentionText.length/2, 0);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[0]).range.location).to.equal(m1.mentionText.length/2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[0]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstNameFirstName LastName LastName");
    });

    it(@"paste mention at beginning of text", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Add a space so the mentions don't bleed into each other
        [textView insertText:@" "];

        // Text is:
        // FirstName LastName

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length+1);
        [textView copy:nil];
        // Paste FirstName LastName at beginning, leaving:
        // |FirstName LastName||FirstName LastName|, where || denote mention attributes
        textView.selectedRange = NSMakeRange(0, 0);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.location).to.equal(m1.mentionText.length+1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName LastName FirstName LastName ");
    });

    it(@"paste mention at end of text", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Add a space so the mentions don't bleed into each other
        [textView insertText:@" "];

        // Text is:
        // FirstName LastName

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length);
        [textView copy:nil];
        // Paste FirstName LastName at beginning, leaving:
        // |FirstName LastName||FirstName LastName|, where || denote mention attributes
        textView.selectedRange = NSMakeRange(m1.mentionText.length+1, 0);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.location).to.equal(m1.mentionText.length+1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName LastName FirstName LastName");
    });

    it(@"paste mention with range", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"1"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Add a space so the mentions don't bleed into each other
        NSString *nonMentionText = @" NonMentionWord";
        [textView insertText:nonMentionText];

        // Text is:
        // FirstName LastName NonMentionWord

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length);
        [textView copy:nil];
        // Paste FirstName LastName over half of first name
        // FirstName|FirstName LastName|, where || denote mention attributes
        textView.selectedRange = NSMakeRange(m1.mentionText.length/2, m1.mentionText.length/2 + nonMentionText.length);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[0]).range.location).to.equal(m1.mentionText.length/2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[0]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstNameFirstName LastName");
    });

    it(@"paste mention with emojis", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName 😁😁" identifier:@"2"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Add a space so the mentions don't bleed into each other
        [textView insertText:@" "];

        // Text is:
        // FirstName LastName

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length);
        [textView copy:nil];
        // Paste FirstName LastName at end, leaving:
        // |FirstName LastName 😁😁| |FirstName LastName 😁😁|, where || denote mention attributes
        textView.selectedRange = NSMakeRange(m1.mentionText.length+1, 0);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.location).to.equal(m1.mentionText.length+1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName LastName 😁😁 FirstName LastName 😁😁");
    });

    it(@"paste from outside after copyString set", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"3"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Add a space so the mentions don't bleed into each other
        [textView insertText:@" "];

        // Text is:
        // FirstName LastName

        // Copy FirstName LastName
        textView.selectedRange = NSMakeRange(0, m1.mentionText.length);
        [textView copy:nil];

        // Paste FirstName LastName at end, leaving:
        // |FirstName LastName| |FirstName LastName|, where || denote mention attributes
        textView.selectedRange = NSMakeRange(m1.mentionText.length+1, 0);
        [textView paste:nil];

        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.location).to.equal(m1.mentionText.length+1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.length).to.equal(m1.mentionText.length);
        expect(textView.text).to.equal(@"FirstName LastName FirstName LastName");

        // Override pasteboard with "CopyText"
        [UIPasteboard generalPasteboard].items = @[@{@"public.utf8-plain-text":@"CopyText"}];
        [textView paste:nil];

        // Paste CopyText at end, leaving:
        // |FirstName LastName| |FirstName LastName|CopyText, where || denote mention attributes

        expect(mentionsPlugin.mentions.count).to.equal(2);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.location).to.equal(m1.mentionText.length+1);
        expect(((HKWMentionsAttribute *)mentionsPlugin.mentions[1]).range.length).to.equal(m1.mentionText.length);
        // Need small delay so text view has time to paste
        expect(textView.text).after(1).to.equal(@"FirstName LastName FirstName LastNameCopyText");
    });

    it(@"paste from outside after maintain attributes", ^{
        // Set text view color so we can test that it remains correct with pasting
        textView.textColor = UIColor.blackColor;

        textView.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        NSString *copyText = @"CopyText";
        [UIPasteboard generalPasteboard].items = @[@{@"public.utf8-plain-text":@"CopyText"}];

        // Paste CopyText after starting text, leaving:
        // CopyText
        [textView paste:nil];

        expect(textView.text).after(1).to.equal(@"CopyText");

        // Test normal font
        expect([mentionsPlugin valueForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length]).to.equal(textView.fontSetByApp);
        expect([mentionsPlugin rangeForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length].location).to.equal(0);
        expect([mentionsPlugin rangeForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length].length).to.equal(copyText.length);

        // Test normal color
        expect([mentionsPlugin valueForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length]).to.equal(textView.textColorSetByApp);
        expect([mentionsPlugin rangeForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length].location).to.equal(0);
        expect([mentionsPlugin rangeForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length].length).to.equal(copyText.length);

        // Add a mention
        HKWMentionsAttribute *mention = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"3"];
        expect(mentionsPlugin.mentions.count).to.equal(0);
        textView.selectedRange = NSMakeRange(textView.text.length, 0);
        [textView insertText:mention.mentionText];
        mention.range = NSMakeRange(textView.text.length-mention.mentionText.length, mention.mentionText.length);
        [mentionsPlugin addMention:mention];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Paste CopyText at end, leaving:
        // CopyText|FirstName LastName|CopyText, where || denote mention attributes
        NSUInteger endOfText = copyText.length+mention.mentionText.length;
        textView.selectedRange = NSMakeRange(endOfText, 0);
        [textView paste:nil];
        expect(textView.text).after(1).to.equal(@"CopyTextFirstName LastNameCopyText");

        // Test normal font
        expect([mentionsPlugin valueForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length]).to.equal(textView.fontSetByApp);
        expect([mentionsPlugin rangeForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length].location).to.equal(endOfText);
        expect([mentionsPlugin rangeForAttributeWithName:NSFontAttributeName forWordOfLength:copyText.length].length).to.equal(copyText.length);

        // Test normal color
        expect([mentionsPlugin valueForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length]).to.equal(textView.textColorSetByApp);
        expect([mentionsPlugin rangeForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length].location).to.equal(endOfText);
        expect([mentionsPlugin rangeForAttributeWithName:NSForegroundColorAttributeName forWordOfLength:copyText.length].length).to.equal(copyText.length);
    });
});

describe(@"highlight mentions - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"highlight mention", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"3"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName LastName

        // Unhighlighted
        NSRange unhighlightedRange;
        id unhighlightedAttribute = [textView.attributedText attribute:HKWRoundedRectBackgroundAttributeName atIndex:m1.mentionText.length/2 longestEffectiveRange:&unhighlightedRange inRange:NSMakeRange(0, textView.attributedText.length)];
        expect(unhighlightedRange.location).to.equal(0);
        expect(unhighlightedRange.length).to.equal(m1.mentionText.length);
        expect(unhighlightedAttribute).to.equal(nil);

        textView.selectedRange = NSMakeRange(m1.mentionText.length/2, 0);

        // Highlighted
        NSRange highlightedRange;
        id highlightedAttribute = [textView.attributedText attribute:HKWRoundedRectBackgroundAttributeName atIndex:m1.mentionText.length/2 longestEffectiveRange:&highlightedRange inRange:NSMakeRange(0, textView.attributedText.length)];
        expect(highlightedRange.location).to.equal(0);
        expect(highlightedRange.length).to.equal(m1.mentionText.length);
        expect([highlightedAttribute class]).to.equal([HKWRoundedRectBackgroundAttributeValue class]);
    });

    it(@"do not highlight mention - multichar select", ^{
        HKWMentionsAttribute *m1 = [HKWMentionsAttribute mentionWithText:@"FirstName LastName" identifier:@"3"];

        expect(mentionsPlugin.mentions.count).to.equal(0);
        [textView insertText:m1.mentionText];
        m1.range = NSMakeRange(0, m1.mentionText.length);
        [mentionsPlugin addMention:m1];
        expect(mentionsPlugin.mentions.count).to.equal(1);

        // Text is:
        // FirstName LastName

        // Unhighlighted
        NSRange unhighlightedRange;
        id unhighlightedAttribute = [textView.attributedText attribute:HKWRoundedRectBackgroundAttributeName atIndex:m1.mentionText.length/2 longestEffectiveRange:&unhighlightedRange inRange:NSMakeRange(0, textView.attributedText.length)];
        expect(unhighlightedRange.location).to.equal(0);
        expect(unhighlightedRange.length).to.equal(m1.mentionText.length);
        expect(unhighlightedAttribute).to.equal(nil);

        textView.selectedRange = NSMakeRange(m1.mentionText.length/2, 1);

        // Unhighlighted
        NSRange unhighlightedRange2;
        id unhighlightedAttribute2 = [textView.attributedText attribute:HKWRoundedRectBackgroundAttributeName atIndex:m1.mentionText.length/2 longestEffectiveRange:&unhighlightedRange2 inRange:NSMakeRange(0, textView.attributedText.length)];
        expect(unhighlightedRange2.location).to.equal(0);
        expect(unhighlightedRange2.length).to.equal(m1.mentionText.length);
        expect(unhighlightedAttribute2).to.equal(nil);
    });
});

SpecEnd
