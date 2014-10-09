//
//  MentionsDemoViewController.h
//  HakawaiDemo
//
//  Copyright (c) 2014 LinkedIn Corp. All rights reserved.
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with
//  the License. You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on
//  an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//

#import <UIKit/UIKit.h>

/*!
 View controller demonstrating the mentions plug-in.
 
 To create a mention, type a '@' or '+' into the text view and select an entry from the pop-up list. When the list is
 showing, you may continue typing or tap in the text view to cancel the mentions creation process. You can also type
 the first three letters of a person's name to cause the list to show up.
 
 Tap the 'List Mentions' button to log to console the current mentions in the text view.
 */
@interface MentionsDemoViewController : UIViewController
@end
