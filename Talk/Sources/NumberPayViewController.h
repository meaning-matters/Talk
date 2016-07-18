//
//  NumberPayViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 18/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NumberPayCell.h"

@interface NumberPayViewController : UITableViewController

@property (nonatomic, assign) int payMonths;


- (instancetype)initWithMonthFee:(float)monthFee oneTimeFee:(float)oneTimeFee;

- (NSString*)oneTimeTitle;

- (void)payNumber;

- (void)leaveViewController;

@end
