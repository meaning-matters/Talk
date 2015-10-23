//
//  CallRatesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 05/04/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "PhoneNumber.h"


@interface CallRatesViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithCallbackPhoneNumber:(PhoneNumber*)callbackPhoneNumber;

@end
