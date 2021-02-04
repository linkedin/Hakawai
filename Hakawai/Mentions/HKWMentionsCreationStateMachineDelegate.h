#import "HKWChooserViewProtocol.h"
#import "HKWTextView.h"
#import "HKWTextView+Plugins.h"
#import "HKWMentionsDefaultChooserViewDelegate.h"
#import "HKWMentionsPlugin.h"

@protocol HKWMentionsCreationStateMachineDelegate <HKWMentionsDefaultChooserViewDelegate, HKWMentionsCustomChooserViewDelegate>

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
- (void)createMention:(HKWMentionsAttribute *)mention cursorLocation:(NSUInteger)cursorLocation;

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
