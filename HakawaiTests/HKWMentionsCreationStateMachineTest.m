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
#import "HKWMentionsPluginV1.h"
#import "HKWMentionsPluginV2.h"
#import "HKWMentionsAttribute.h"
#import "HKWRoundedRectBackgroundAttributeValue.h"
#import "_HKWMentionsCreationStateMachine.h"
#import "_HKWMentionsCreationStateMachine.h"
#import "HKWMentionDataProvider.h"
#import "HKWTDummyMentionsManager.h"

@interface HKWMentionsCreationStateMachine ()

@property (nonatomic) HKWMentionDataProvider *dataProvider;

@property (nonatomic, strong) NSMutableString *stringBuffer;

@end

@interface HKWMentionDataProvider ()

@property (nonatomic) NSArray *entityArray;

@end

@interface HKWMentionsPluginV1 () <HKWMentionsDefaultChooserViewDelegate>

@property (nonatomic, strong) HKWMentionsCreationStateMachine *creationStateMachine;

@end

@interface HKWMentionsPluginV2 () <HKWMentionsDefaultChooserViewDelegate>

@property (nonatomic, strong) HKWMentionsCreationStateMachine *creationStateMachine;

@end

SpecBegin(explicitMentionList)

describe(@"Showing mentions list for explicit search only - MENTIONS PLUGIN V1", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV1 *mentionsPlugin;
    __block HKWTDummyMentionsManager *mentionsManager;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV1 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
                                                        controlCharacters:[NSCharacterSet characterSetWithCharactersInString:@"@"]
                                                             searchLength:0];
        mentionsManager = [[HKWTDummyMentionsManager alloc] init];
        mentionsPlugin.defaultChooserViewDelegate = mentionsManager;
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    it(@"should not show mention list for email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        HKWMentionsCreationStateMachine *sm;
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@"B"];
    [textView setText:@"AB"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
    [textView setText:@"AB@"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(3, 0) replacementText:@"C"];
    [textView setText:@"AB@C"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);
    });

    it(@"should show mention list for non email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        HKWMentionsCreationStateMachine *sm;
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@" "];
    [textView setText:@"A "];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
    [textView setText:@"A @"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(5);
    });

    it(@"should show mentions list for explicit search(when typed control character `@`)", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"@"];
        [textView setText:@"@"];
        HKWMentionsCreationStateMachine *sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(5);
    });

    it(@"should trigger initial fetch mentions request when text begins editing", ^{
        [textView.delegate textViewShouldBeginEditing:textView];
        HKWMentionsCreationStateMachine *sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(1);
    });
});

describe(@"Showing mentions list for explicit search only - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;
    __block HKWTDummyMentionsManager *mentionsManager;

    beforeEach(^{
        HKWTextView.enableMentionsPluginV2 = YES;
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
                                                        controlCharacters:[NSCharacterSet characterSetWithCharactersInString:@"@"]
                                                             searchLength:0];
        mentionsManager = [[HKWTDummyMentionsManager alloc] init];
        mentionsPlugin.defaultChooserViewDelegate = mentionsManager;
        [textView setControlFlowPlugin:mentionsPlugin];
    });

    afterAll(^{
        HKWTextView.enableMentionsPluginV2 = NO;
    });

    it(@"should not show mention list for email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        HKWMentionsCreationStateMachine *sm;
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@"B"];
    [textView setText:@"AB"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
    [textView setText:@"AB@"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(3, 0) replacementText:@"C"];
    [textView setText:@"AB@C"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);
    });

    it(@"should show mention list for non email", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"A"];
        [textView setText:@"A"];
        HKWMentionsCreationStateMachine *sm;
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(1, 0) replacementText:@" "];
    [textView setText:@"A "];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(0);

    [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(2, 0) replacementText:@"@"];
    [textView setText:@"A @"];
        sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(5);
    });

    it(@"should show mentions list for explicit search(when typed control character `@`)", ^{
        [mentionsPlugin textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"@"];
        [textView setText:@"@"];
        HKWMentionsCreationStateMachine *sm = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        NSArray *entityArray = sm.dataProvider.entityArray;
    expect(entityArray.count).to.equal(5);
    });
});

describe(@"Test basic mention typing logic in multiple languages - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;
    __block HKWTDummyMentionsManager *mentionsManager;

     beforeEach(^{
         HKWTextView.enableMentionsPluginV2 = YES;
         textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
         mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
                                                         controlCharacters:[NSCharacterSet characterSetWithCharactersInString:@"@"]
                                                              searchLength:0];
         mentionsManager = [[HKWTDummyMentionsManager alloc] init];
         mentionsPlugin.defaultChooserViewDelegate = mentionsManager;
         [textView setControlFlowPlugin:mentionsPlugin];
     });

     afterAll(^{
         HKWTextView.enableMentionsPluginV2 = NO;
     });

    it(@"test with english", ^{
        [textView insertText:@"@"];
        [textView insertText:@"a"];
        // Text: @a
        HKWMentionsCreationStateMachine *creationStateMachine = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        expect(creationStateMachine.stringBuffer).to.equal(@"a");
        [textView insertText:@"b"];
        // Text: @ab
        expect(creationStateMachine.stringBuffer).to.equal(@"ab");
        [textView deleteBackward];
        // Text: @a
        expect(creationStateMachine.stringBuffer).to.equal(@"a");
        [textView deleteBackward];
        // Text: @
        expect(creationStateMachine.stringBuffer).to.equal(@"");
        [textView insertText:@"ab"];
        // Text: @ab
        expect(creationStateMachine.stringBuffer).to.equal(@"ab");
    });

    it(@"test with korean hanji", ^{
        [textView insertText:@"@"];
        [textView insertText:@"ㄱ"];
        // Text: @ㄱ
        HKWMentionsCreationStateMachine *creationStateMachine = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        expect(creationStateMachine.stringBuffer).to.equal(@"ㄱ");
        [textView insertText:@"ㅣ"];
        // Text: @ㄱㅣ
        expect(creationStateMachine.stringBuffer).to.equal(@"ㄱㅣ");
        [textView deleteBackward];
        // Text: @ㄱ
        expect(creationStateMachine.stringBuffer).to.equal(@"ㄱ");
        [textView deleteBackward];
        // Text: @
        expect(creationStateMachine.stringBuffer).to.equal(@"");
        [textView insertText:@"ㄱㅣ"];
        // Text: @ㄱㅣ
        expect(creationStateMachine.stringBuffer).to.equal(@"ㄱㅣ");
    });

    it(@"test with emojis", ^{
        [textView insertText:@"@"];
        [textView insertText:@"😁"];
        // Text: @😁
        HKWMentionsCreationStateMachine *creationStateMachine = (HKWMentionsCreationStateMachine *)mentionsPlugin.creationStateMachine;
        expect(creationStateMachine.stringBuffer).to.equal(@"😁");
        [textView insertText:@"😁"];
        // Text: @😁😁
        expect(creationStateMachine.stringBuffer).to.equal(@"😁😁");
        [textView deleteBackward];
        // Text: @😁
        expect(creationStateMachine.stringBuffer).to.equal(@"😁");
        [textView deleteBackward];
        // Text: @
        expect(creationStateMachine.stringBuffer).to.equal(@"");
        [textView insertText:@"asdf 😁"];
        // Text: @asdf 😁
        expect(creationStateMachine.stringBuffer).to.equal(@"asdf 😁");
    });
});

describe(@"autocorrect setting - MENTIONS PLUGIN V2", ^{
    __block HKWTextView *textView;
    __block HKWMentionsPluginV2 *mentionsPlugin;
    __block HKWTDummyMentionsManager *mentionsManager;

     beforeEach(^{
         HKWTextView.enableMentionsPluginV2 = YES;
         textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
         mentionsPlugin = [HKWMentionsPluginV2 mentionsPluginWithChooserMode:HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp
                                                         controlCharacters:[NSCharacterSet characterSetWithCharactersInString:@"@"]
                                                              searchLength:0];
         mentionsManager = [[HKWTDummyMentionsManager alloc] init];
         mentionsPlugin.defaultChooserViewDelegate = mentionsManager;
         [textView setControlFlowPlugin:mentionsPlugin];
     });

     afterAll(^{
         HKWTextView.enableMentionsPluginV2 = NO;
     });

    it(@"autocorrect on/off with accessory view", ^{
        // Autocorrection should begin default
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
        [textView insertText:@"@"];

        // Autocorrection should turn to NO when accessory view is activated
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView insertText:@"a"];

        // Autocorrection should remain NO while accessory view is activated
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView deleteBackward];
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeNo);
        [textView deleteBackward];

        // Autocorrection should return to default when accessory view is deactivated
        expect(textView.autocorrectionType).to.equal(UITextAutocorrectionTypeDefault);
    });
});

SpecEnd
