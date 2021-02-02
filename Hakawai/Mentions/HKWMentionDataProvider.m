#import "HKWMentionDataProvider.h"

#import "_HKWMentionsCreationStateMachine.h"

#import "HKWChooserViewProtocol.h"
#import "_HKWDefaultChooserView.h"
#import "HKWMentionsAttribute.h"
#import "HKWMentionDataProvider.h"
#import "_HKWMentionsPrivateConstants.h"

/*!
 States for the network state subsidiary state machine.
 */
typedef NS_ENUM(NSInteger, HKWMentionsCreationNetworkState) {
    // The mentions creation system is ready: data has been populated, and the system is waiting for the user to type
    //  a character, select a mention, or perform another action.
    HKWMentionsCreationNetworkStateReady = 0,

    // The mentions creation system is ready, but the rate-limiting timer is still active.
    HKWMentionsCreationNetworkStateTimerCooldown,

    // The mentions creation system is ready, the rate-limiting timer is still active, and another request needs to be
    //  made once it expires.
    HKWMentionsCreationNetworkStatePendingRequestAfterCooldown,
};

@interface HKWMentionDataProvider ()

@property (nonatomic, weak) id<HKWMentionsCreationStateMachineDelegate> delegate;

/// query for the current request
@property (nonatomic, copy, nullable, readwrite) NSString *currentQuery;

/// query for the pending request
@property (nonatomic, copy, nullable, readwrite) NSString *pendingQuery;
@property (nonatomic, assign, readwrite) HKWMentionsSearchType pendingSearchType;
@property (nonatomic, assign, readwrite) BOOL pendingQueryIsWhitespace;
@property (nonatomic, assign, readwrite) unichar pendingControlCharacter;

/// Whether or not the results for the current query string are 'finalized', i.e. attempts to append more results should
/// be ignored.
@property (nonatomic) BOOL currentQueryIsComplete;

/// A sequence number used by the state machine to disambiguate data provided by callbacks as valid or expired. The
/// sequence number monotonically increases.
@property (nonatomic) NSUInteger sequenceNumber;

@property (weak, nonatomic) HKWMentionsCreationStateMachine *stateMachine;

/// An array serving as a backing store for the chooser table view; it contains objects representing mentions entities
/// that the user can select from.
@property (nonatomic, nullable, readwrite) NSArray *entityArray;

@property (nonatomic, strong) NSTimer *cooldownTimer;
@property (nonatomic, readonly) NSTimeInterval cooldownPeriod;
@property (nonatomic) HKWMentionsCreationNetworkState networkState;

@end

@implementation HKWMentionDataProvider

- (NSTimeInterval)cooldownPeriod {
    return 0.1;
}

- (instancetype)initWithStateMachine:(nonnull HKWMentionsCreationStateMachine *)stateMachine
                            delegate:(nonnull id<HKWMentionsCreationStateMachineDelegate>)delegate{
    self = [super init];
    if (self) {
        _entityArray = nil;
        _sequenceNumber = 0;
        _stateMachine = stateMachine;
        _delegate = delegate;
    }
    return self;
}

- (void)queryUpdatedWithKeyString:(nonnull NSString *)string
                       searchType:(HKWMentionsSearchType)type
                     isWhitespace:(BOOL)isWhitespace
                 controlCharacter:(unichar)character {
    self.currentQuery = [string copy];
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateReady: {
            [self sendQueryWithKeyString:string
                              searchType:type
                            isWhitespace:isWhitespace
                        controlCharacter:character];
            return;
        }
        case HKWMentionsCreationNetworkStateTimerCooldown:
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown: {
            self.pendingQuery = [string copy];
            self.pendingSearchType = type;
            self.pendingQueryIsWhitespace = isWhitespace;
            self.pendingControlCharacter = character;
            self.networkState = HKWMentionsCreationNetworkStatePendingRequestAfterCooldown;
        }
    }
}

- (void)sendQueryWithKeyString:(nonnull NSString *)string
                    searchType:(HKWMentionsSearchType)type
                  isWhitespace:(BOOL)isWhitespace
              controlCharacter:(unichar)character {
    [self activateCooldownTimer];
    NSLog(@"fire:%@",string);
    // Fire off another request immediately
    self.sequenceNumber += 1;
    NSUInteger sequenceNumber = self.sequenceNumber;
    __weak typeof(self) weakSelf = self;
    [self.delegate asyncRetrieveEntitiesForKeyString:[string copy]
                                          searchType:type
                                    controlCharacter:character
                                          completion:^(NSArray *results, BOOL dedupe,__unused BOOL isComplete) {
        typeof(self) strongSelf = weakSelf;
        typeof(HKWMentionsCreationStateMachine) *stateMachine = strongSelf.stateMachine;
        strongSelf.currentQueryIsComplete = YES;
        // Check for error conditions
        if (sequenceNumber != self.sequenceNumber) {
            // This is a response to an out-of-date request.
            HKWLOG(@"  DEBUG: out-of-date request (seq: %lu, current: %lu)",
                   (unsigned long)sequenceNumber, (unsigned long)self.sequenceNumber);
            return;
        }
        if ([results count] == 0) {
            // No responses
            strongSelf.entityArray = nil;
            [stateMachine dataReturnedWithEmptyResults:YES
                           keystringEndsWithWhiteSpace:isWhitespace];
            return;
        }
        NSUInteger numResults = [results count];
        NSMutableArray *validResults = [NSMutableArray arrayWithCapacity:numResults];
        NSMutableSet *uniqueIds = [NSMutableSet setWithCapacity:numResults];
        for (id entity in results) {
#ifdef DEBUG
            // Validate
            NSAssert([entity conformsToProtocol:@protocol(HKWMentionsEntityProtocol)],
                     @"Data results array contained at least one object that didn't conform to the protocol. This is a \
                     serious error. Object: %@",
                     entity);
#endif
            if (dedupe) {
                // This is the first response; protect against duplicates within this response
                NSString *uniqueId = [self uniqueIdForEntity:entity];
                if ([uniqueId length] && ![uniqueIds containsObject:uniqueId]) {
                    [validResults addObject:entity];
                    [uniqueIds addObject:uniqueId];
                }
            }
            else {
                [validResults addObject:entity];
            }
        }
        self.entityArray = [validResults copy];

        [stateMachine dataReturnedWithEmptyResults:NO
                       keystringEndsWithWhiteSpace:isWhitespace];
    }];
}

- (NSString *)uniqueIdForEntity:(id<HKWMentionsEntityProtocol>)entity {
    if ([entity respondsToSelector:@selector(uniqueId)]) {
        return [entity uniqueId];
    }
    // Default to using the entityId when a uniqueId is not provided
    return [entity entityId];
}

- (void)setSequenceNumber:(NSUInteger)sequenceNumber {
    self.currentQueryIsComplete = NO;
    _sequenceNumber = sequenceNumber;
}

- (void)setEntityArray:(NSArray *)entityArray {
    if (!_entityArray && !entityArray) {
        return;
    }
    _entityArray = entityArray;
    // Force the entity chooser's table view to update
    [self.stateMachine reloadChooserView];
}

/*!
 Configure and activate the cooldown timer. If the cooldown timer was already active, restarts it.
 */
- (void)activateCooldownTimer {
    // Remove any pre-existing timers.
    [self.cooldownTimer invalidate];

    // Advance state
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateReady:
            self.networkState = HKWMentionsCreationNetworkStateTimerCooldown;
            break;
        case HKWMentionsCreationNetworkStateTimerCooldown:
            NSAssert(NO, @"Timer should never be activated when state machine is waiting for timer cooldown.");
            break;
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            // Valid state transition. This happens if a new request is fired as soon as the timer times out.
            self.networkState = HKWMentionsCreationNetworkStateTimerCooldown;
            break;
    }

    // Add and activate the timer
    NSTimer *timer = [NSTimer timerWithTimeInterval:self.cooldownPeriod
                                             target:self
                                           selector:@selector(cooldownTimerFired:)
                                           userInfo:nil
                                            repeats:NO];
    self.cooldownTimer = timer;
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}


/*!
 Handle actions and state transitions after the cooldown timer fires. If the user has queued up another request, this
 method may fire another typeahead request to the server immediately. Otherwise, the firing of the timer indicates that
 it is acceptable to send another request at any time.
 */
- (void)cooldownTimerFired:(__unused NSTimer *)timer {
    switch (self.networkState) {
        case HKWMentionsCreationNetworkStateReady:
            NSAssert(NO, @"Timer should never be active when state machine is in the 'ready' state.");
            return;
        case HKWMentionsCreationNetworkStateTimerCooldown:
            self.networkState = HKWMentionsCreationNetworkStateReady;
            break;
        case HKWMentionsCreationNetworkStatePendingRequestAfterCooldown:
            self.networkState = HKWMentionsCreationNetworkStateReady;
            NSString *pendingQuery = self.pendingQuery;
            if (pendingQuery) {
                [self sendQueryWithKeyString:[pendingQuery copy]
                                  searchType:self.pendingSearchType
                                isWhitespace:self.pendingQueryIsWhitespace
                            controlCharacter:self.pendingControlCharacter];
            } else {
                NSAssert(NO, @"pending query is nil.");
            }
            break;
    }
}

#pragma mark - Table view
// Note: the table view data source and delegate here service the table view embedded within the state machine's
//  entity chooser view.

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0 || indexPath.section == 1,
             @"Entity chooser table view can only have up to 2 sections. Method was called for section %ld.",
             (long)indexPath.section);
    __strong __auto_type delegate = self.delegate;
    if (indexPath.section == 1) {
        // Loading cell
        NSAssert(delegate.loadingCellSupported,
                 @"Table view has 2 sections but the delegate doesn't support a loading cell. This is an error.");
        UITableViewCell *cell = [delegate loadingCellForTableView:tableView];
        cell.userInteractionEnabled = NO;
        return cell;
    }
    NSAssert(indexPath.row >= 0 && (NSUInteger)indexPath.row < [self.entityArray count],
             @"Entity chooser table view requested a cell with an out-of-bounds index path row.");
    id<HKWMentionsEntityProtocol> entity = self.entityArray[(NSUInteger)indexPath.row];
    return [delegate cellForMentionsEntity:entity withMatchString:[self.currentQuery copy] tableView:tableView atIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(__unused UITableView *)tableView {
    return (self.delegate.loadingCellSupported && !self.currentQueryIsComplete) ? 2 : 1;
}

- (NSInteger)tableView:(__unused UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(section == 0 || section == 1,
             @"Entity chooser table view can only have up to 2 sections.");
    if (section == 1) {
        // Loading cell
        return 1;
    }
    return (NSInteger)[self.entityArray count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSAssert(indexPath.section == 0 || indexPath.section == 1,
             @"Entity chooser table view can only have up to 2 sections.");
    __strong __auto_type delegate = self.delegate;
    if (indexPath.section == 1) {
        // Loading cell
        return [delegate heightForLoadingCellInTableView:tableView];
    }
    NSAssert(indexPath.row >= 0 && (NSUInteger)indexPath.row < [self.entityArray count],
             @"Entity chooser table view requested a cell with an out-of-bounds index path row.");
    id<HKWMentionsEntityProtocol> entity = self.entityArray[(NSUInteger)indexPath.row];
    return [delegate heightForCellForMentionsEntity:entity tableView:tableView];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 1) {
        return;
    }
    id<HKWMentionsEntityProtocol> entity = self.entityArray[(NSUInteger)indexPath.row];
    if (entity) {
        __auto_type _Nonnull unwrappedEntity = entity;
        [self.stateMachine handleSelectionForEntity:unwrappedEntity
                                          indexPath:indexPath];
    }
}

@end
