//
//  PhoneViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ItemViewController.h"
#import "PhoneData.h"


@interface PhoneViewController : ItemViewController

@property (nonatomic, strong) PhoneData* phone;


- (instancetype)initWithPhone:(PhoneData*)phone
         managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
