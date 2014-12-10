//
//  HKWMentionsPlugin.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <Foundation/Foundation.h>

#import "HKWControlFlowPluginProtocols.h"
#import "HKWMentionsEntityProtocol.h"
#import "HKWChooserViewProtocol.h"

/*!
 An attribute for \c NSAttributedString objects representing a mention. This attribute by itself confers no special
 formatting on its text; the plug-in is responsible for coloring and highlighting text according to the current state.
 */
static NSString *const HKWMentionAttributeName = @"HKWMentionAttributeName";

/*!
 An enum representing supported modes for positioning the chooser view.

 \c HKWMentionsChooserPositionModeEnclosedTop places the chooser view inline within the text view, and locks the
 single-line viewport to the top of the text view.

 \c HKWMentionsChooserPositionModeEnclosedBottom places the chooser view inline within the text view, and locks the
 single-line viewport to the bottom of the text view.

 All the 'Custom' modes require the delegate to provide a frame for the chooser view.

 \c HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp is a custom mode where the arrow is configured to point
 up and the single-line viewport is locked to the top.

 \c HKWMentionsChooserPositionModeCustomLockTopArrowPointingDown is a custom mode where the arrow is configured to point
 down and the single-line viewport is locked to the top.

 \c HKWMentionsChooserPositionModeCustomLockTopNoArrow is a custom mode where the chooser is configured with no chrome
 and the single-line viewport is locked to the top.

 \c HKWMentionsChooserPositionModeCustomLockBottomArrowPointingUp is a custom mode where the arrow is configured to
 point up and the single-line viewport is locked to the bottom.

 \c HKWMentionsChooserPositionModeCustomLockBottomArrowPointingDown is a custom mode where the arrow is configured to
 point down and the single-line viewport is locked to the bottom.

 \c HKWMentionsChooserPositionModeCustomLockBottomNoArrow is a custom mode where the chooser is configured with no
 chrome and the single-line viewport is locked to the bottom.

 \c HKWMentionsChooserPositionModeCustomNoLockArrowPointingUp is a custom mode where the arrow is configured to point
 up and the text view is never locked.

 \c HKWMentionsChooserPositionModeCustomNoLockArrowPointingDown is a custom mode where the arrow is configured to
 point down and the text view is never locked.

 \c HKWMentionsChooserPositionModeCustomNoLockNoArrow is a custom mode where the chooser is configured with no chrome
 and the text view is never locked.
 */
typedef enum {
    HKWMentionsChooserPositionModeEnclosedTop = 0,
    HKWMentionsChooserPositionModeEnclosedBottom,
    HKWMentionsChooserPositionModeCustomLockTopArrowPointingUp,
    HKWMentionsChooserPositionModeCustomLockTopArrowPointingDown,
    HKWMentionsChooserPositionModeCustomLockTopNoArrow,
    HKWMentionsChooserPositionModeCustomLockBottomArrowPointingUp,
    HKWMentionsChooserPositionModeCustomLockBottomArrowPointingDown,
    HKWMentionsChooserPositionModeCustomLockBottomNoArrow,
    HKWMentionsChooserPositionModeCustomNoLockArrowPointingUp,
    HKWMentionsChooserPositionModeCustomNoLockArrowPointingDown,
    HKWMentionsChooserPositionModeCustomNoLockNoArrow
} HKWMentionsChooserPositionMode;

typedef enum {
    HKWMentionsSearchTypeImplicit,
    HKWMentionsSearchTypeExplicit
} HKWMentionsSearchType;

/*!
 An enum representing possible states that the mentions plug-in may be in.
 */
typedef enum {
    HKWMentionsPluginStateQuiescent,
    HKWMentionsPluginStateCreatingMention
} HKWMentionsPluginState;

@class HKWMentionsPlugin;
/*!
 A protocol providing a way for listeners to be informed when the state of the mentions plug-in changes. This allows
 a host application to know when the plug-in is creating a mention, and when it is quiescent.
 */
@protocol HKWMentionsStateChangeDelegate <NSObject>

@optional

- (void)mentionsPlugin:(HKWMentionsPlugin *)plugin
        stateChangedTo:(HKWMentionsPluginState)newState
                  from:(HKWMentionsPluginState)oldState;

- (void)mentionsPluginActivatedChooserView:(HKWMentionsPlugin *)plugin;
- (void)mentionsPluginDeactivatedChooserView:(HKWMentionsPlugin *)plugin;

@end

/*!
 A protocol describing a delegate and data source for the mentions creation plug-in. The data source is queried by the
 plug-in, and should return an array of result objects that conform with the \c HKWMentionsEntityProtocol protocol. If
 the array is empty, the plug-in will assume that no matches remain for the current input and will terminate the
 creation of the current mentions object.

 The delegate is used to provide certain types of custom UI elements for displaying mentions options, etc.
 */
@protocol HKWMentionsDelegate <NSObject>

/*!
 Request the delegate to fetch mention results asynchronously. Mention results may come from a local store, a server, or
 some combination of the two. The delegate must call the completion block upon success or failure. If the request
 failed, timed out, or must be canceled for any reason, call the completion block with nil or an empty array.

 Note that the block passed into this method as an argument must be called with either YES or NO for the second
 parameter. This parameter indicates whether all expected results have been loaded or not, and is intended to allow a
 single query to be populated by multiple asynchronous sources. For example, your app may immediately return several
 locally stored results, and after a network request returns append additional results. As long as you have NOT called
 the block with 'YES', you may call the block repeatedly to append additional results to the end of the mentions list.
 If the search string changes or you have called the block previously with 'YES' to finalize the results, the mentions
 plug-in will silently ignore additional calls to the block.

 \warning The block must be called the first time with data in order to be allowed to append additional data. Returning
 an initial result set that is empty will cause the plug-in to treat the request as having been completed.

 \warning It is the responsibility of the delegate to determine when a remote request has timed out, and to call the
 completion block accordingly.

 \param keyString          the string that the data source should search upon
 \param searchType         an enum describing the mention type for search purposes; currently, this can be Explicit
                           (user typed in control character) or Implicit (user typed in a number of consecutive valid
                           characters)
 \param character          if \c searchType is Explicit, this is the control character that was typed to begin the
                           mention creation; otherwise, it should be ignored
 \param completionBlock    a provided block that must be called upon completion or failure. Pass in an array containing
                           items conforming to the \c HKWMentionsEntityProtocol protocol; these will be used to populate
                           the chooser list. Also pass in YES or NO depending on whether you expect to append additional
                           results later (see the notes above).
 */
- (void)asyncRetrieveEntitiesForKeyString:(NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void(^)(NSArray *results, BOOL dedupe, BOOL isComplete))completionBlock;

/*!
 Return a table view cell to be displayed for a given mention entity in the chooser view.
 */
- (UITableViewCell *)cellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                           withMatchString:(NSString *)matchString
                                 tableView:(UITableView *)tableView;

/*!
 Return the height of the table view cell for a given mention entity in the chooser view.
 */
- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol>)entity
                                tableView:(UITableView *)tableView;

@optional

/*!
 Return whether or not a given mentions entity can be 'trimmed' - that is, if the entity name is multiple words, it can
 be reduced to just the first word. If not implemented, the plug-in assumes that no entities can be trimmed. Trimming
 is irrelevant for entities that start out with single-word names, unless \c trimmedNameForEntity: is implemented, in
 which case the plug-in will query even for entities with single-word names.
 */
- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol>)entity;

/*!
 If implemented, this method allows the host to specify how a given entity should be trimmed to an abbreviated form. If
 not implemented, the default behavior is to trim the entity down to the first word in its name, unless the name already
 contains no whitespace or newline characters, in which case the entity is not trimmed.
 */
- (NSString *)trimmedNameForEntity:(id<HKWMentionsEntityProtocol>)entity;

/*!
 Return a loading cell to be displayed if results still haven't been returned yet.
 */
- (UITableViewCell *)loadingCellForTableView:(UITableView *)tableView;

/*!
 Return the height of the loading cell; this must be implemented for the loading cell functionality to be enabled.
 */
- (CGFloat)heightForLoadingCellInTableView:(UITableView *)tableView;

@end

@class HKWMentionsAttribute;
@class HKWAbstractChooserView;

@interface HKWMentionsPlugin : NSObject <HKWDirectControlFlowPluginProtocol>

@property (nonatomic, weak) id<HKWMentionsDelegate> delegate;
@property (nonatomic, weak) id<HKWMentionsStateChangeDelegate> stateChangeDelegate;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, no control characters, and a default search length of
 3 characters.
 */
+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, and search length.

 \param controlCharacterSet    a \c NSCharacterSet containing the character or characters that should be used to begin
                               an explicit mention, or nil if explicit mentions should not be enabled
 \param searchLength           the number of characters to wait before beginning an implicit mention, or 0 or a negative
                               value if implicit mentions should not be enabled
 */
+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, search length, a color for
 unselected mentions text, and a background color and text color for selected mentions text.
 */
+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                              unselectedColor:(UIColor *)unselectedColor
                                selectedColor:(UIColor *)selectedColor
                      selectedBackgroundColor:(UIColor *)selectedBackgroundColor;

/*!
 Instantiate a mentions plug-in with the specified chooser mode, control character set, search length, custom attributes
 to apply to unselected mentions, and custom attributes to apply to selected mentions.
 */
+ (instancetype)mentionsPluginWithChooserMode:(HKWMentionsChooserPositionMode)mode
                            controlCharacters:(NSCharacterSet *)controlCharacterSet
                                 searchLength:(NSInteger)searchLength
                  unselectedMentionAttributes:(NSDictionary *)unselectedAttributes
                    selectedMentionAttributes:(NSDictionary *)selectedAttributes;

#pragma mark - API

/*!
 Extract mentions attributes from an attributed string. The array of mentions attribute objects returned by this method
 can be passed directly into the \c addMentions: method on the plug-in.
 */
+ (NSArray *)mentionsAttributesInAttributedString:(NSAttributedString *)attributedString;

/*!
 Return an array of \c HKWMentionsAttribute objects corresponding to the mentions attributes which currently exist.
 */
- (NSArray *)mentions;

/*!
 Add a mention attribute to the text view's text. This method is intended to be called when the text view is first
 being populated with text (for example, when a user decides to edit an existing document containing mentions).

 \param mention    a mention object representing the mention to add. The \c range property on the object must be set
                   properly. In addition, the length of \c range must match the length of the \c mentionText property,
                   and the existing text in the text view at \c range must exactly match the value of the \c mentionText
                   string. Invalid mentions are ignored.
 */
- (void)addMention:(HKWMentionsAttribute *)mention;

/*!
 Add multiple mentions to the text view's text. This is a convenience method that calls the \c addMention: method for
 each element in \c mentions that passes typechecking.
 */
- (void)addMentions:(NSArray *)mentions;


#pragma mark - Chooser UI Configuration

/*! 
 The class of the chooser view to instantiate. Must be a subclass of the \c HKWAbstractChooserView class. If set to an
 invalid value or nil, defaults to the built-in chooser view. Set this when the mentions plug-in is created; setting it
 will do nothing after the chooser view is instantiated.
 */
@property (nonatomic) Class<HKWChooserViewProtocol> chooserViewClass;

/*!
 Return the frame of the chooser view. If the chooser view hasn't been instantiated, the null rect will be returend.
 */
- (CGRect)chooserViewFrame;

/*!
 Return a generic reference to the chooser view.
 */
@property (nonatomic, readonly) HKWAbstractChooserView *chooserView;

/*!
 Return the chooser position mode the chooser was configured with.
 */
@property (nonatomic, readonly) HKWMentionsChooserPositionMode chooserPositionMode;

/*!
 The background color of the chooser view. If the chooser view hasn't been instantiated, the color will be applied to
 the chooser view upon instantiation.
 */
@property (nonatomic, strong) UIColor *chooserViewBackgroundColor;

@property (nonatomic) UIEdgeInsets chooserViewEdgeInsets;

/*!
 Whether or not the delegate supports displaying a loading cell in the chooser view while waiting for the results
 */
@property (nonatomic, readonly) BOOL loadingCellSupported;

/*!
 Whether or not to allow resumption of mentions creation upon resuming editing
 */
@property (nonatomic) BOOL resumeMentionsCreationEnabled;

/*!
 Whether or not implicit mentions search is enabled. Implicit mentions do not require a control char such as '@' to
 initiate a mentions search. The default value is true.
 */
@property (nonatomic) BOOL implicitMentionsSearchEnabled;

/*!
 If the plug-in is set to display the chooser view in a custom position, set the top level view and a block to be called
 after the view is attached to its superview (intended to be used to set up layout constraints).
 */
- (void)setChooserTopLevelView:(UIView *)topLevelView attachmentBlock:(void(^)(UIView *))block;

/*!
 Return a rect describing the frame that would be assigned to the chooser view if in one of the preset modes, or
 \c CGRectNull otherwise.
 */
- (CGRect)calculatedChooserFrameForMode:(HKWMentionsChooserPositionMode)mode
                             edgeInsets:(UIEdgeInsets)edgeInsets;

@end
