//
//  PhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhoneData.h"


@interface PhoneViewController : UITableViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) PhoneData* phone;

- (instancetype)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                                           phone:(PhoneData*)phone;

@end
