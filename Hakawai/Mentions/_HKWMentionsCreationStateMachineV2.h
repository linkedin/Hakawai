//
//  HKWMentionsCreationStateMachine.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import "_HKWMentionsCreationStateMachine.h"

NS_ASSUME_NONNULL_BEGIN

/*!
 This class represents a state machine that manages the creation of mentions. In this case, 'mentions creation' is
 defined as either an active state in which the editor text view's viewport is locked and a list of potential mentions
 is displayed, or a passive state where mentions creation is stalled but the user is still eligible to resume mentions
 creation. The state machine also manages making requests to the data source and displaying the chooser list. The state
 machine should inform the host when mentions creation is canceled or completed.
 */

@interface HKWMentionsCreationStateMachineV2 : NSObject <HKWMentionsCreationStateMachine>
@end

NS_ASSUME_NONNULL_END
