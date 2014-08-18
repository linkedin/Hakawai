//
//  HKWChooserViewProtocol.h
//  Hakawai
//
//  Copyright (c) 2014 LinkedIn
//  Released under the terms of the MIT License
//

#import <UIKit/UIKit.h>

@protocol HKWChooserViewProtocol <NSObject>

+ (instancetype)chooserViewWithFrame:(CGRect)frame
                            delegate:(id<UITableViewDelegate>)delegate
                          dataSource:(id<UITableViewDataSource>)dataSource;

@optional

@property (nonatomic) UIEdgeInsets dataViewScrollIndicatorInsets;
@property (nonatomic) UIEdgeInsets dataViewContentInset;

@property (nonatomic) BOOL insertionPointMarkerEnabled;
- (void)moveInsertionPointMarkerToXPosition:(CGFloat)position;

@end
