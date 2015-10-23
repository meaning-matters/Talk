//
//  ForwardingViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//


#import <UIKit/UIKit.h>
#import "ForwardingData.h"
#import "ItemViewController.h"


@interface ForwardingViewController : ItemViewController <UITextFieldDelegate>

@property (nonatomic, strong) ForwardingData* forwarding;
@property (nonatomic, strong) NSMutableArray* sequenceArray;

- (instancetype)initWithForwarding:(ForwardingData*)forwarding
              managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
