//
//  LIREEntityChooserView.h
//  LIEditorLibrary
//
//  Created by Ethan Goldblum on 11/10/13.
//  Copyright (c) 2013 LinkedIn. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "LIREAbstractChooserView.h"
#import "LIREChooserBorderView.h"

@interface LIREEntityChooserView : LIREAbstractChooserView <LIREChooserBorderViewProtocol>

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic) BOOL insertionPointMarkerEnabled;

@end
