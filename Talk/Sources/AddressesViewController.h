//
//  AddressesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ItemsViewController.h"

@class AddressData;


@interface AddressesViewController : ItemsViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedAddress:(AddressData*)selectedAddress
                                  completion:(void (^)(AddressData* selectedAddress))completion;

@end
