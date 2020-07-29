#import "HKWChooserViewProtocol.h"
#import "HKWTextView.h"
#import "HKWTextView+Plugins.h"
#import "HKWMentionsDefaultChooserViewDelegate.h"
#import "HKWMentionsPlugin.h"

@protocol HKWMentionsCreationStateMachineProtocol <HKWMentionsDefaultChooserViewDelegate>

/*!
 Get whether or not the host app supports displaying a loading cell.
 */
@property (nonatomic, readonly) BOOL loadingCellSupported;

/*!
 Whether or not we should continue searching for an explicit mention after we get back empty results. If this
 is off, empty results will return the mentions creation state to \c HKWMentionsPluginStateQuiescent. If this is
 on, empty results won't modify the mentions creation state.
 */
@property (nonatomic, readonly) BOOL shouldContinueSearchingAfterEmptyResults;

/*!
 Request the bounds of the editor text view owning the delegate.
 */
- (CGRect)boundsForParentEditorView;

/*!
 Request the origin of the editor text view owning the delegate.
 */
- (CGPoint)originForParentEditorView;

/*!
 Request that the delegate attach a view to the parent editor text view at the specified origin. If sibling mode, the
 origin should be relative to the parent editor text view's frame (as if the view were to be added as a subview). If
 in free-floating mode, the origin should be relative to the topmost view in the view hierarchy.
 */
- (void)attachViewToParentEditor:(UIView *)view origin:(CGPoint)origin mode:(HKWAccessoryViewMode)mode;

/*!
 Inform the delegate that the accessory view is about to be activated or deactivated.
 */
- (void)accessoryViewStateWillChange:(BOOL)activated;

/*!
 Inform the delegate that the accessory view has been activated or deactivated.
 */
- (void)accessoryViewActivated:(BOOL)activated;

/*!
 Inform the delegate that a new mention annotation should be created. Relevant metadata are contained in the \c mention
 argument. This method also moves the editor view out of the mention creation state.
 */
- (void)createMention:(HKWMentionsAttribute *)mention startingLocation:(NSUInteger)location;

/*!
 Inform the delegate an entity was selected as a result of user input.
 */
- (void)selected:(id<HKWMentionsEntityProtocol>)entity
     atIndexPath:(NSIndexPath *)indexPath;

/*!
 Inform the delegate that the editor view should move out of the mention creation state without adding a new mention
 annotation.
 */
- (void)cancelMentionFromStartingLocation:(NSUInteger)location;

- (HKWMentionsChooserPositionMode)chooserPositionMode;

- (CGFloat)heightForSingleLineViewport;

/*!
 Return the position of the center of the chooser cursor, relative to the text view itself.
 */
- (CGFloat)positionForChooserCursorRelativeToView:(UIView *)view atLocation:(NSUInteger)location;

@end

/**
 This is a temprorary protocol that V1 and V2 version of HKWMentionsCreationStateMachine will conform to so we can toggle between two versions easily.
 Once V2 is fully ramped and tested, we will remove V1 version and this protocol.
 */
@protocol HKWMentionsCreationStateMachine

/// The background color of the chooser view.
@property (nonatomic, strong) UIColor *chooserViewBackgroundColor;

/// The edge insets applied to the chooser view. Only valid if the chooser view isn't using a custom frame.
@property (nonatomic) UIEdgeInsets chooserViewEdgeInsets;

/// The class of the chooser view to instantiate. Must be a subclass of the \c UIView class. If set to an invalid value
/// or nil, defaults to the built-in chooser view.
@property (nonatomic) Class<HKWChooserViewProtocol> chooserViewClass;

/*!
 Character control search explicit inputted in the chooser view.
 Needs to be public for integration between Hakawai and HotPot.
*/
@property (nonatomic) unichar explicitSearchControlCharacter;

/*!
 Return a new, initialized state machine instance.
 */
+ (instancetype)stateMachineWithDelegate:(id<HKWMentionsCreationStateMachineProtocol>)delegate;

/**
 Informs the state machine typeahead results are returned, so it can update its internal state accordingly.
 */
- (void)dataReturnedWithEmptyResults:(BOOL)isEmptyResults
         keystringEndsWithWhiteSpace:(BOOL)keystringEndsWithWhiteSpace;
/*!
 Inform the state machine that a single character was typed by the user into the text view.
 */
- (void)characterTyped:(unichar)c;

/*!
 Inform the state machine that a valid string was inserted into the text view (no spaces, newlines, or forbidden
 characters).
 */
- (void)validStringInserted:(NSString *)string;

/*!
 Inform the state machine that a character or string was deleted from the text view.
 */
- (void)stringDeleted:(NSString *)deleteString;

/*!
 Inform the state machine that the cursor was moved from its prior position and is now in insertion mode.
 */
- (void)cursorMoved;

/*!
 Inform the state machine that mention creation has started.

 \param prefix                   a string containing text that the user typed before mentions creation started, but
                                 should be used as a query string for asking the data source for suggestions
 \param usingControlCharacter    whether or not the mention was started by typing a special control character
 \param character                if \c usingControlCharacter is NO, this is ignored; otherwise, the control character
                                 used to begin the mention
 \param location                 the index position where the completed mention should begin
 */
- (void)mentionCreationStartedWithPrefix:(NSString *)prefix
                   usingControlCharacter:(BOOL)usingControlCharacter
                        controlCharacter:(unichar)character
                                location:(NSUInteger)location;

/*!
 Inform the state machine that mention creation must stop immediately.
 */
- (void)cancelMentionCreation;

/**
 Setup chooser view if needed.
 */
- (void)setupChooserViewIfNeeded;

/*!
 Completely reset the chooser view. This is useful if the parent plug-in is detached from its editor text view.
 */
- (void)resetChooserView;

/*!
 If the chooser arrow is showing, hide it until the next time the chooser view appears after disappearing.
 */
- (void)hideChooserArrow;

/*!
 Inform the state machine to trigger fetch for initial mentions
 */
- (void)fetchInitialMentions;

/*!
 Get the chooser view frame. If the chooser view has not yet been instantiated, returns the nil rectangle.
 */
- (CGRect)chooserViewFrame;

/*!
 A reference to the entity chooser view, or nil if it hasn't yet been instantiated.
 */
- (UIView<HKWChooserViewProtocol> *)getEntityChooserView;

/*!
 Return a rect describing the frame that would be assigned to the chooser view if in one of the preset modes, or
 \c CGRectNull otherwise.
 */
- (CGRect)frameForMode:(HKWMentionsChooserPositionMode)mode;

/*!
 Shows the chooser view.
 Needs to be public for integration between Hakawai and HotPot.
 */
- (void)showChooserView;

/*!
 Handles the selection from the user.
 Needs to be public for integration between Hakawai and HotPot.
 // TODO: remove indexPath as it's no longer needed for tracking
 */
- (void)handleSelectionForEntity:(id<HKWMentionsEntityProtocol>)entity indexPath:(NSIndexPath *)indexPath;

@optional
/*!
 reload the results chooser view.
 This needs to be called when the results data is updated.
 */
- (void)reloadChooserView;

@end
