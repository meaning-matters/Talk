//
//  CallerIdViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CallableData;


@interface CallerIdViewController : UITableViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            selectedCallable:(CallableData*)selectedCallable
                                  completion:(void (^)(CallableData*  selectedCallable))completion;

@end
