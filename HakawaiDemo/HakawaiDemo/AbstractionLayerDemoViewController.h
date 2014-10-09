//
//  AbstractionLayerDemoViewController.h
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
 View controller demonstrating the text view abstraction layer feature.

 Type in the text view and watch as events are reported in the miniature console window. Tap 'Enable'/'Disable' to allow
 or disallow your typing to change the text view, or 'Clear' to remove all entries from the console window.
 */
@interface AbstractionLayerDemoViewController : UIViewController

- (void)writeTextToConsoleView:(NSString *)text;

@end
