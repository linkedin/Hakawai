#import "HKWMentionsEntityProtocol.h"

typedef NS_ENUM(NSInteger, HKWMentionsSearchType) {
    HKWMentionsSearchTypeImplicit,
    HKWMentionsSearchTypeExplicit,
    HKWMentionsSearchTypeInitial
};

/*!
 A protocol describing a delegate and data source for the mentions creation plug-in. The data source is queried by the
 plug-in, and should return an array of result objects that conform with the \c HKWMentionsEntityProtocol protocol. If
 the array is empty, the plug-in will assume that no matches remain for the current input and will terminate the
 creation of the current mentions object.

 The delegate is used to provide certain types of custom UI elements for displaying mentions options, etc.
 */
@protocol HKWMentionsDefaultChooserViewDelegate <NSObject>

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
 \param type               an enum describing the mention type for search purposes; currently, this can be Explicit
                           (user typed in control character) or Implicit (user typed in a number of consecutive valid
                           characters)
 \param character          if \c type is Explicit, this is the control character that was typed to begin the
                           mention creation; otherwise, it should be ignored
 \param completionBlock    a provided block that must be called upon completion or failure. Pass in an array containing
                           items conforming to the \c HKWMentionsEntityProtocol protocol; these will be used to populate
                           the chooser list. Also pass in YES or NO depending on whether you expect to append additional
                           results later (see the notes above).
 */
- (void)asyncRetrieveEntitiesForKeyString:(nonnull NSString *)keyString
                               searchType:(HKWMentionsSearchType)type
                         controlCharacter:(unichar)character
                               completion:(void(^_Null_unspecified)(NSArray *_Null_unspecified results, BOOL dedupe, BOOL isComplete))completionBlock;

/*!
 Return a table view cell to be displayed for a given mention entity in the chooser view.
 */
- (UITableViewCell *_Null_unspecified)cellForMentionsEntity:(_Null_unspecified id<HKWMentionsEntityProtocol>)entity
                                            withMatchString:(NSString *_Null_unspecified)matchString
                                                  tableView:(UITableView *_Null_unspecified)tableView
                                                atIndexPath:(NSIndexPath *_Null_unspecified)indexPath;

/*!
 Return the height of the table view cell for a given mention entity in the chooser view.
 */
- (CGFloat)heightForCellForMentionsEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity
                                tableView:(UITableView *_Null_unspecified)tableView;

@optional

/*!
 Return whether or not a given mentions entity can be 'trimmed' - that is, if the entity name is multiple words, it can
 be reduced to just the first word. If not implemented, the plug-in assumes that no entities can be trimmed. Trimming
 is irrelevant for entities that start out with single-word names, unless \c trimmedNameForEntity: is implemented, in
 which case the plug-in will query even for entities with single-word names.
 */
- (BOOL)entityCanBeTrimmed:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity;

/*!
 If implemented, this method allows the host to specify how a given entity should be trimmed to an abbreviated form. If
 not implemented, the default behavior is to trim the entity down to the first word in its name, unless the name already
 contains no whitespace or newline characters, in which case the entity is not trimmed.
 */
- (nonnull NSString *)trimmedNameForEntity:(id<HKWMentionsEntityProtocol> _Null_unspecified)entity;

/*!
 Return a loading cell to be displayed if results still haven't been returned yet.
 */
- (UITableViewCell *_Null_unspecified)loadingCellForTableView:(UITableView *_Null_unspecified)tableView;

/*!
 Return the height of the loading cell; this must be implemented for the loading cell functionality to be enabled.
 */
- (CGFloat)heightForLoadingCellInTableView:(UITableView *_Null_unspecified)tableView;

@end
