//
//  HKWDefaultChooserView.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <UIKit/UIKit.h>

#import "HKWAbstractChooserView.h"
#import "HKWDefaultChooserBorderView.h"

@interface HKWDefaultChooserView : HKWAbstractChooserView <HKWDefaultChooserBorderViewProtocol>

@property (nonatomic, readonly) UITableView *tableView;
@property (nonatomic) BOOL insertionPointMarkerEnabled;

@end
