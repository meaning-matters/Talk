//
//  AddressViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ItemViewController.h"
#import "AddressData.h"
#import "NumberType.h"
#import "AddressType.h"


@interface AddressViewController : ItemViewController

@property (nonatomic, strong) AddressData* address;


- (instancetype)initWithAddress:(AddressData*)address                       // With nil a new address is created.
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                    addressType:(AddressTypeMask)addressTypeMask
                 isoCountryCode:(NSString*)isoCountryCode
                       areaCode:(NSString*)areaCode
                     numberType:(NumberTypeMask)numberTypeMask
                     proofTypes:(NSDictionary*)proofTypes
                     completion:(void (^)(AddressData* address))completion; // Only if new address was created.

@end
