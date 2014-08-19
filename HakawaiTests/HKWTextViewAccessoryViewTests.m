//
//  HKWTextViewAccessoryViewTests.m
//  Hakawai
//
//  Created by Austin Zheng on 8/18/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#define EXP_SHORTHAND

#import "Specta.h"
#import "Expecta.h"

#import "HKWTextView+Plugins.h"

SpecBegin(accessoryViewProperties)

describe(@"accessory view-related properties", ^{
    __block HKWTextView *textView;
    __block UIView *baseView;
    __block UIView *containerView;
    CGFloat textViewX = 11;
    CGFloat textViewY = 7;

    beforeEach(^{
        // Set up the basic view hierarchy: a base view, a container view, and a text view
        baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
        containerView = [[UIView alloc] initWithFrame:CGRectMake(5, 25, 120, 200)];
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(textViewX, textViewY, 50, 60)];
        [baseView addSubview:containerView];
        [containerView addSubview:textView];
    });

    it(@"should properly reflect the state of a sibling view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect(textView.attachedAccessoryView).to.beNil;
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect(textView.attachedAccessoryView).to.equal(siblingView);
        // Detach the view
        [textView detachAccessoryView:siblingView];
        expect(textView.attachedAccessoryView).to.beNil;
    });

    it(@"should properly reflect the state of a free floating view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect(textView.attachedAccessoryView).to.beNil;
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect(textView.attachedAccessoryView).to.equal(floatingView);
        // Detach the view
        [textView detachAccessoryView:floatingView];
        expect(textView.attachedAccessoryView).to.beNil;
    });
});

SpecEnd

SpecBegin(siblingAccessoryViews)

describe(@"sibling accessory view API", ^{
    __block HKWTextView *textView;
    __block UIView *baseView;
    __block UIView *containerView;
    CGFloat textViewX = 11;
    CGFloat textViewY = 7;

    beforeEach(^{
        // Set up the basic view hierarchy: a base view, a container view, and a text view
        baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
        containerView = [[UIView alloc] initWithFrame:CGRectMake(5, 25, 120, 200)];
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(textViewX, textViewY, 50, 60)];
        [baseView addSubview:containerView];
        [containerView addSubview:textView];
    });

    it(@"should properly attach/detach a sibling view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(2);
        expect(siblingView.superview).to.equal(containerView);
        expect(siblingView.frame.size.width).to.equal(width);
        expect(siblingView.frame.size.height).to.equal(height);
        expect(siblingView.frame.origin.x).to.equal(textViewX + viewX);
        expect(siblingView.frame.origin.y).to.equal(textViewY + viewY);
        // Detach the view
        [textView detachAccessoryView:siblingView];
        expect([containerView.subviews count]).to.equal(1);
        expect(siblingView.superview).to.beNil;
    });

    it(@"should properly ignore attaching a nil view", ^{
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        [textView attachSiblingAccessoryView:nil position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(1);
    });

    it(@"should properly ignore detaching a nil view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(2);
        expect(siblingView.superview).to.equal(containerView);
        // Detach the view
        [textView detachAccessoryView:nil];
        expect([containerView.subviews count]).to.equal(2);
        expect(siblingView.superview).to.equal(containerView);
    });

    it(@"should properly ignore a second sibling attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(2);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachSiblingAccessoryView:badView position:CGPointMake(15, 20)];
        expect([containerView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a floating attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(2);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachFreeFloatingAccessoryView:badView absolutePosition:CGPointMake(15, 20)];
        expect([containerView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a spurious detach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *siblingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachSiblingAccessoryView:siblingView position:CGPointMake(viewX, viewY)];
        expect([containerView.subviews count]).to.equal(2);
        // Detach the wrong view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView detachAccessoryView:badView];
        expect([containerView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
        expect(siblingView.superview).to.equal(containerView);
    });
});

SpecEnd

SpecBegin(freeFloatingAccessoryViews)

describe(@"free floating accessory view API with auto top level", ^{
    __block HKWTextView *textView;
    __block UIView *baseView;
    __block UIView *containerView;
    CGFloat textViewX = 11;
    CGFloat textViewY = 7;

    beforeEach(^{
        // Set up the basic view hierarchy: a base view, a container view, and a text view
        baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
        containerView = [[UIView alloc] initWithFrame:CGRectMake(5, 25, 120, 200)];
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(textViewX, textViewY, 50, 60)];
        [baseView addSubview:containerView];
        [containerView addSubview:textView];
    });

    it(@"should properly attach/detach a free floating view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        expect(floatingView.superview).to.equal(baseView);
        expect(floatingView.frame.size.width).to.equal(width);
        expect(floatingView.frame.size.height).to.equal(height);
        expect(floatingView.frame.origin.x).to.equal(viewX);
        expect(floatingView.frame.origin.y).to.equal(viewY);
        // Detach the view
        [textView detachAccessoryView:floatingView];
        expect([baseView.subviews count]).to.equal(1);
        expect(floatingView.superview).to.beNil;
    });

    it(@"should properly ignore attaching a nil view", ^{
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        [textView attachFreeFloatingAccessoryView:nil absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(1);
    });

    it(@"should properly ignore detaching a nil view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        // Detach the view
        [textView detachAccessoryView:nil];
        expect([baseView.subviews count]).to.equal(2);
        expect(floatingView.superview).to.equal(baseView);
    });

    it(@"should properly ignore a second attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachFreeFloatingAccessoryView:badView absolutePosition:CGPointMake(15, 20)];
        expect([baseView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a sibling attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachSiblingAccessoryView:badView position:CGPointMake(15, 20)];
        expect([baseView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a spurious detach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(1);
        expect([containerView.subviews count]).to.equal(1);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        // Detach the wrong view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView detachAccessoryView:badView];
        expect([baseView.subviews count]).to.equal(2);
        expect(badView.superview).to.beNil;
        expect(floatingView.superview).to.equal(baseView);
    });
});

SpecEnd

SpecBegin(freeFloatingAccessoryViewsCustomTopLevel)

describe(@"free floating accessory view API with custom top level", ^{
    __block HKWTextView *textView;
    __block UIView *baseView;
    __block UIView *containerView;
    __block UIView *otherContainerView;
    CGFloat textViewX = 11;
    CGFloat textViewY = 7;

    beforeEach(^{
        // Set up the basic view hierarchy: a base view, a container view, and a text view
        baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 600)];
        containerView = [[UIView alloc] initWithFrame:CGRectMake(5, 25, 120, 200)];
        otherContainerView = [[UIView alloc] initWithFrame:CGRectMake(13, 21, 270, 510)];
        textView = [[HKWTextView alloc] initWithFrame:CGRectMake(textViewX, textViewY, 50, 60)];
        [baseView addSubview:containerView];
        [baseView addSubview:otherContainerView];
        [containerView addSubview:textView];
        [textView setTopLevelViewForAccessoryViewPositioning:otherContainerView];
    });

    it(@"should properly reflect the state of the attached top-level view", ^{
        expect(textView.customTopLevelView).to.equal(otherContainerView);
        [textView setTopLevelViewForAccessoryViewPositioning:nil];
        expect(textView.customTopLevelView).to.beNil;
        [textView setTopLevelViewForAccessoryViewPositioning:baseView];
        expect(textView.customTopLevelView).to.equal(baseView);
    });

    it(@"should properly attach/detach a free floating view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([containerView.subviews count]).to.equal(1);
        expect([otherContainerView.subviews count]).to.equal(1);
        expect(floatingView.superview).to.equal(otherContainerView);
        expect(floatingView.frame.size.width).to.equal(width);
        expect(floatingView.frame.size.height).to.equal(height);
        expect(floatingView.frame.origin.x).to.equal(viewX);
        expect(floatingView.frame.origin.y).to.equal(viewY);
        // Detach the view
        [textView detachAccessoryView:floatingView];
        expect([otherContainerView.subviews count]).to.equal(0);
        expect(floatingView.superview).to.beNil;
    });

    it(@"should properly ignore attaching a nil view", ^{
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        [textView attachFreeFloatingAccessoryView:nil absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
    });

    it(@"should properly ignore detaching a nil view", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(1);
        // Detach the view
        [textView detachAccessoryView:nil];
        expect([baseView.subviews count]).to.equal(2);
        expect(floatingView.superview).to.equal(otherContainerView);
    });

    it(@"should properly ignore a second attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(1);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachFreeFloatingAccessoryView:badView absolutePosition:CGPointMake(15, 20)];
        expect([otherContainerView.subviews count]).to.equal(1);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a sibling attach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(1);
        // Attach another view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView attachSiblingAccessoryView:badView position:CGPointMake(15, 20)];
        expect([otherContainerView.subviews count]).to.equal(1);
        expect(badView.superview).to.beNil;
    });

    it(@"should properly ignore a spurious detach request", ^{
        CGFloat width = 101;
        CGFloat height = 202;
        CGFloat viewX = 12;
        CGFloat viewY = 19;
        UIView *floatingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(0);
        // Attach the view
        [textView attachFreeFloatingAccessoryView:floatingView absolutePosition:CGPointMake(viewX, viewY)];
        expect([baseView.subviews count]).to.equal(2);
        expect([otherContainerView.subviews count]).to.equal(1);
        // Detach the wrong view
        UIView *badView = [[UIView alloc] initWithFrame:CGRectMake(5, 5, 10, 10)];
        [textView detachAccessoryView:badView];
        expect([otherContainerView.subviews count]).to.equal(1);
        expect(badView.superview).to.beNil;
        expect(floatingView.superview).to.equal(otherContainerView);
    });
});

SpecEnd
