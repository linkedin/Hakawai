//
//  HKWTextView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <UIKit/UIKit.h>

@class HKWTextView;

@protocol HKWTextViewDelegate <UITextViewDelegate>
// Note: this protocol should NEVER contain any required methods; doing so will cause clients to break.
@optional

- (void)textViewDidEnterSingleLineViewportMode:(HKWTextView *)textView;
- (void)textViewDidExitSingleLineViewportMode:(HKWTextView *)textView;
- (void)textViewWasTappedInSingleLineViewportMode:(HKWTextView *)textView;
- (void)textView:(HKWTextView *)textView didChangeAttributedTextTo:(NSAttributedString *)newText
    originalText:(NSAttributedString *)originalText
   originalRange:(NSRange)originalRange;
- (void)textView:(HKWTextView *)textView didReceiveNewTextAttachment:(NSTextAttachment *)attachment;

@end

@protocol HKWSimplePluginProtocol, HKWControlFlowPluginProtocol;

/*!
 An enhanced text view designed for use with various plug-ins. It provides additional functionality which a developer
 can pick and choose from in order to more easily implement complex features.
 */
@interface HKWTextView : UITextView

/*!
 An optional delegate object implementing the \c HKWTextViewDelegate protocol.
 
 \warning Do NOT set the text view's \c delegate property directly.
 */
@property (nonatomic, weak) id<HKWTextViewDelegate> externalDelegate;

/*!
 A \c UITextViewDelegate alias for the \c externalDelegate property.
 */
@property (nonatomic) id<UITextViewDelegate> simpleDelegate;

/*!
 A readonly reference to an attached accessory view.
 */
@property (nonatomic, weak, readonly) UIView *attachedAccessoryView;

/*!
 A readonly reference to a view designated as the 'top-level view' for purposes of placing accessory views.
 */
@property (nonatomic, weak, readonly) UIView *customTopLevelView;

/*!
 Return whether or not the text view is in 'single line viewport' mode.
 */
@property (nonatomic, readonly) BOOL inSingleLineViewportMode;

/*!
 Register a simple plug-in with the editor.
 */
- (void)addSimplePlugin:(id<HKWSimplePluginProtocol>)plugin;

/*!
 Unregister a simple plug-in with the editor.
 */
- (void)removeSimplePluginNamed:(NSString *)name;

/*!
 Register a control flow plug-in with the editor. Unlike simple plug-ins, only one control flow plug-in can be enabled
 at a time. Pass in nil to remove any currently registered control flow plug-in.
 */
- (void)registerControlFlowPlugin:(id<HKWControlFlowPluginProtocol>)plugin;

@end
