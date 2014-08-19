//
//  HKWTextViewPluginTests.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView.h"
#import "HKWTBasicDummyPlugin.h"
#import "HKWTControlFlowDummyPlugin.h"

@interface HKWTextView ()
- (BOOL)textViewShouldBeginEditing:(UITextView *)textView;
- (void)textViewDidBeginEditing:(UITextView *)textView;
- (BOOL)textViewShouldEndEditing:(UITextView *)textView;
- (void)textViewDidEndEditing:(UITextView *)textView;
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)replacementText;
- (void)textViewDidChange:(UITextView *)textView;
- (void)textViewDidChangeSelection:(UITextView *)textView;
- (BOOL)textView:(UITextView *)textView shouldInteractWithTextAttachment:(NSTextAttachment *)textAttachment inRange:(NSRange)characterRange;
- (BOOL)textView:(UITextView *)textView shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange;
@end

SpecBegin(basicPlugins)

describe(@"basic plugin API", ^{
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];\
    });

    it(@"should properly register and unregister basic plug-ins", ^{
        HKWTBasicDummyPlugin *p1 = [HKWTBasicDummyPlugin dummyPluginWithName:@"p1"];
        HKWTBasicDummyPlugin *p2 = [HKWTBasicDummyPlugin dummyPluginWithName:@"p2"];
        HKWTBasicDummyPlugin *p3 = [HKWTBasicDummyPlugin dummyPluginWithName:@"p3"];
        // Add plug-ins
        expect([textView.simplePlugins count]).to.equal(0);
        [textView addSimplePlugin:p1];
        expect([textView.simplePlugins count]).to.equal(1);
        [textView addSimplePlugin:p2];
        expect([textView.simplePlugins count]).to.equal(2);
        // Add the same plugin again
        [textView addSimplePlugin:p2];
        expect([textView.simplePlugins count]).to.equal(2);
        [textView addSimplePlugin:p3];
        expect([textView.simplePlugins count]).to.equal(3);

        // Check parentTextView
        expect(p1.parentTextView).to.equal(textView);
        expect(p2.parentTextView).to.equal(textView);
        expect(p3.parentTextView).to.equal(textView);

        // Remove plug-ins
        [textView removeSimplePluginNamed:@"p1"];
        expect([textView.simplePlugins count]).to.equal(2);
        // Remove a non-added plugin
        [textView removeSimplePluginNamed:@"INVALID"];
        expect([textView.simplePlugins count]).to.equal(2);
        [textView removeSimplePluginNamed:@"p3"];
        expect([textView.simplePlugins count]).to.equal(1);
        // Remove an already-removed plugin
        [textView removeSimplePluginNamed:@"p1"];
        expect([textView.simplePlugins count]).to.equal(1);
        [textView removeSimplePluginNamed:@"p2"];
        expect([textView.simplePlugins count]).to.equal(0);

        // Check parentTextView
        expect(p1.parentTextView).to.beNil;
        expect(p2.parentTextView).to.beNil;
        expect(p3.parentTextView).to.beNil;
    });
});

SpecEnd

SpecBegin(controlFlowPlugins)

describe(@"control flow plugin API", ^{
    __block HKWTextView *textView;

    beforeEach(^{
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];\
    });

    it(@"should properly register and unregister control flow plugins plug-ins", ^{
        HKWTControlFlowDummyPlugin *p1 = [HKWTControlFlowDummyPlugin dummyPluginWithName:@"p1"];
        HKWTControlFlowDummyPlugin *p2 = [HKWTControlFlowDummyPlugin dummyPluginWithName:@"p2"];

        expect(textView.controlFlowPlugin).to.beNil;
        expect(p1.parentTextView).to.beNil;
        expect(p2.parentTextView).to.beNil;

        // Set plug-ins
        textView.controlFlowPlugin = p1;
        expect(textView.controlFlowPlugin).to.equal(p1);
        expect(p1.parentTextView).to.equal(textView);

        // Reset plug-in
        textView.controlFlowPlugin = p2;
        expect(textView.controlFlowPlugin).to.equal(p2);
        expect(p1.parentTextView).to.beNil;
        expect(p2.parentTextView).to.equal(textView);

        // Set to nil
        textView.controlFlowPlugin = nil;
        expect(textView.controlFlowPlugin).to.beNil;
        expect(p2.parentTextView).to.beNil;

        // Set plug-in again
        textView.controlFlowPlugin = p1;
        expect(textView.controlFlowPlugin).to.equal(p1);
        expect(p1.parentTextView).to.equal(textView);
    });

    it(@"should properly forward calls to delegate methods", ^{
        HKWTControlFlowDummyPlugin *p1 = [HKWTControlFlowDummyPlugin dummyPluginWithName:@"p1"];
        textView.controlFlowPlugin = p1;
        __block BOOL rightBlockWasCalled = NO;
        void (^blockToCall)(void) = ^{
            rightBlockWasCalled = YES;
        };
        void (^failBlock)(void) = ^{
            XCTFail(@"Fail block was called");
        };

        // Test APIs
        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.shouldBeginEditingBlock = blockToCall;
        [textView textViewShouldBeginEditing:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.didBeginEditingBlock = blockToCall;
        [textView textViewDidBeginEditing:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.shouldEndEditingBlock = blockToCall;
        [textView textViewShouldEndEditing:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.didEndEditingBlock = blockToCall;
        [textView textViewDidEndEditing:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.shouldChangeTextInRangeBlock = blockToCall;
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"dummy"];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.didChangeBlock = blockToCall;
        [textView textViewDidChange:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.didChangeSelectionBlock = blockToCall;
        [textView textViewDidChangeSelection:textView];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.shouldInteractWithTextAttachmentBlock = blockToCall;
        [textView textView:textView shouldInteractWithTextAttachment:nil inRange:NSMakeRange(0, 0)];
        expect(rightBlockWasCalled).to.equal(YES);

        [p1 resetBlocks];
        rightBlockWasCalled = NO;
        p1.shouldInteractWithURLBlock = blockToCall;
        [textView textView:textView shouldInteractWithURL:[NSURL URLWithString:@"example.com"] inRange:NSMakeRange(0, 10)];
        expect(rightBlockWasCalled).to.equal(YES);

        // Test unregistration
        textView.controlFlowPlugin = nil;
        p1.shouldBeginEditingBlock = failBlock;
        p1.didBeginEditingBlock = failBlock;
        p1.shouldEndEditingBlock = failBlock;
        p1.didEndEditingBlock = failBlock;
        p1.shouldChangeTextInRangeBlock = failBlock;
        p1.didChangeBlock = failBlock;
        p1.didChangeSelectionBlock = failBlock;
        p1.shouldInteractWithTextAttachmentBlock = failBlock;
        p1.shouldInteractWithURLBlock = failBlock;

        // None of these should trip the fail block
        [textView textViewShouldBeginEditing:textView];
        [textView textViewDidBeginEditing:textView];
        [textView textViewShouldEndEditing:textView];
        [textView textViewDidEndEditing:textView];
        [textView textView:textView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:@"dummy"];
        [textView textViewDidChange:textView];
        [textView textViewDidChangeSelection:textView];
        [textView textView:textView shouldInteractWithTextAttachment:nil inRange:NSMakeRange(0, 0)];
        [textView textView:textView shouldInteractWithURL:[NSURL URLWithString:@"example.com"] inRange:NSMakeRange(0, 10)];
    });
});

SpecEnd
