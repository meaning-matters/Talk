//
//  ForwardingViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ForwardingData.h"


@interface ForwardingViewController : UITableViewController <UITextFieldDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) ForwardingData*   forwarding;
@property (nonatomic, strong) NSMutableArray*   sequenceArray;

- (instancetype)initWithForwarding:(ForwardingData*)forwarding
              managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
