//
//  HKWMentionsCreationStateMachine.m
//  Hakawai
//
//  Copyright (c) 2018 LinkedIn Corp. All rights reserved.
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
#import "_HKWMentionsPlugin.h"
#import "HKWMentionsAttribute.h"
#import "HKWRoundedRectBackgroundAttributeValue.h"
#import "_HKWMentionsCreationStateMachine.h"
#import "HKWTDummyMentionsManager.h"

@interface HKWMentionsCreationStateMachine ()

@property (nonatomic) NSArray *entityArray;

@end

@interface HKWMentionsPlugin () <HKWMentionsDelegate>

@property (nonatomic, strong) HKWMentionsCreationStateMachine *creationStateMachine;

@end

SpecBegin(explicitMentionList)

describe(@"Showing mentions list for explicit search only", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPlugin *mentionsPlugin;
    __block HKWTDummyMentionsManager *mentionsManager;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPlugin mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
                                                        controlCharacters:[NSCharacterSet characterSetWithCharactersInString:@"@"]
                                                             searchLength:0];
        mentionsManager = [[HKWTDummyMentionsManager alloc] init];
        mentionsPlugin.delegate = mentionsManager;
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should not show mention list for email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);

        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@"B"];
        [textView setText:@"AB"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);

        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
        [textView setText:@"AB@"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);

        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(3, 0) replacementText:@"C"];
        [textView setText:@"AB@C"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);
    });

    it(@"should show mention list for non email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);

        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@" "];
        [textView setText:@"A "];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(0);

        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
        [textView setText:@"A @"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(5);
    });

    it(@"should show mentions list for explicit search(when typed control character `@`)", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"@"];
        [textView setText:@"@"];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(5);
    });

    it(@"should trigger initial fetch mentions request when text begins editing", ^{
        if (HKWTextView.enableSimpleRefactor) {
            // With simple refactor, we trigger based on cursor movement
            return;
        }
        [textView.delegate textViewShouldBeginEditing:textView];
        expect(mentionsPlugin.creationStateMachine.entityArray.count).to.equal(1);
    });
});

SpecEnd
