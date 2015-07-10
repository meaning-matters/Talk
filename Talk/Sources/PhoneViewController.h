//
//  PhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PhoneData.h"
#import "ItemViewController.h"


@interface PhoneViewController : ItemViewController <UITextFieldDelegate>

@property (nonatomic, strong) PhoneData* phone;

- (instancetype)initWithPhone:(PhoneData*)phone
         managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
