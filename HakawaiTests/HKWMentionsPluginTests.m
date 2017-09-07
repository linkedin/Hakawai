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
#import "HKWMentionsPlugin.h"
#import "HKWMentionsAttribute.h"

SpecBegin(mentionPluginsSetup)

describe(@"basic mentions plugin setup", ^{
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    });

    it(@"should properly register and unregister mentions plug-in", ^{
        HKWMentionsPlugin *plugin = [HKWMentionsPlugin mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
        // Add plug-ins
        [textView setControlFlowPlugin:plugin];
        expect([textView controlFlowPlugin]).to.beKindOf(HKWMentionsPlugin.class);

        // Check parentTextView
        expect(plugin.parentTextView).to.equal(textView);

        // Remove plug-in
        textView.controlFlowPlugin = nil;
        expect(textView.controlFlowPlugin).to.beNil;
        expect(plugin.parentTextView).to.beNil;
    });
});

describe(@"inserting and reading mentions", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPlugin *mentionsPlugin;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPlugin mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp];
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

SpecEnd
