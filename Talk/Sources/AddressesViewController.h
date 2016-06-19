//
//  AddressesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ItemsViewController.h"
#import "NumberType.h"
#import "AddressType.h"

@class AddressData;


@interface AddressesViewController : ItemsViewController

- (instancetype)init;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedAddress:(AddressData*)selectedAddress
                              isoCountryCode:(NSString*)isoCountryCode
                                    areaCode:(NSString*)areaCode
                                  numberType:(NumberTypeMask)numberTypeMask
                                 addressType:(AddressTypeMask)addressTypeMask
                                  proofTypes:(NSDictionary*)proofTypes
                                   predicate:(NSPredicate*)predicate    // Used to select between modes.
                                  completion:(void (^)(AddressData* selectedAddress))completion;

+ (void)loadAddressesPredicateWithAddressType:(AddressTypeMask)addressTypeMask
                               isoCountryCode:(NSString*)isoCountryCode
                                     areaCode:(NSString*)areaCode
                                   numberType:(NumberTypeMask)numberTypeMask
                                 areAvailable:(BOOL)areAvailable // Only addresses that are ready to be used.
                                   completion:(void (^)(NSPredicate* predicate, NSError* error))completion;

@end
