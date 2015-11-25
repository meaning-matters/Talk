//
//  AddressesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ItemsViewController.h"
#import "NumberType.h"

@class AddressData;


@interface AddressesViewController : ItemsViewController

@property (nonatomic, strong) NSString* headerTitle;
@property (nonatomic, strong) NSString* footerTitle;


- (instancetype)init;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedAddress:(AddressData*)selectedAddress
                              isoCountryCode:(NSString*)isoCountryCode
                                    areaCode:(NSString*)areaCode
                                  numberType:(NumberTypeMask)numberTypeMask
                                 addressType:(NSString*)addressType
                                   proofType:(NSDictionary*)proofType
                                  completion:(void (^)(AddressData* selectedAddress))completion;

@end
