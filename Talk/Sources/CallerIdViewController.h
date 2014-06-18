//
//  CallerIdViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PhoneData;
@class NumberData;


@interface CallerIdViewController : UITableViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                               selectedPhone:(PhoneData*)selectedPhone
                              selectedNumber:(NumberData*)selectedNumber
                                  completion:(void (^)(PhoneData*  selectedPhone,
                                                       NumberData* selectedNumber))completion;

@end
