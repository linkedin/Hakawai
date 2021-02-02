#import "HKWMentionsPlugin.h"

#import "_HKWMentionsCreationStateMachine.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 This class handles data request and processing, with built in cooldown and dedupe logic. It also handles table view UI setup.
 This is only needed when the consumer of the library chooses the default chooser view implementation.
 If the consumer chooses its own custom chooser view option, this class will never be created.
 */
@interface HKWMentionDataProvider: NSObject <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithStateMachine:(HKWMentionsCreationStateMachine *)stateMachine
                            delegate:(id<HKWMentionsCreationStateMachineDelegate>)delegate;

- (void)queryUpdatedWithKeyString:(NSString *)string
                       searchType:(HKWMentionsSearchType)type
                     isWhitespace:(BOOL)isWhitespace
                 controlCharacter:(unichar)character;

@end

NS_ASSUME_NONNULL_END
