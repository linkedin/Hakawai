//
//  LIREChooserViewProtocol.h
//  LIRichEditorLib
//
//  Created by Austin Zheng on 7/4/14.
//  Copyright (c) 2014 LinkedIn. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LIREChooserViewProtocol <NSObject>

+ (instancetype)chooserViewWithFrame:(CGRect)frame
                            delegate:(id<UITableViewDelegate>)delegate
                          dataSource:(id<UITableViewDataSource>)dataSource;

@optional

@property (nonatomic) UIEdgeInsets dataViewScrollIndicatorInsets;
@property (nonatomic) UIEdgeInsets dataViewContentInset;

@property (nonatomic) BOOL insertionPointMarkerEnabled;
- (void)moveInsertionPointMarkerToXPosition:(CGFloat)position;

@end
