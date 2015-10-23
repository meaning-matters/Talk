//
//  PhonesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemsViewController.h"

@class PhoneData;


@interface PhonesViewController : ItemsViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                               selectedPhone:(PhoneData*)selectedPhone
                                  completion:(void (^)(PhoneData* selectedPhone))completion;

@end
