//
//  AddressViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "ItemViewController.h"
#import "AddressData.h"
#import "NumberType.h"


@interface AddressViewController : ItemViewController

@property (nonatomic, strong) AddressData* address;


- (instancetype)initWithAddress:(AddressData*)address
           managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                 isoCountryCode:(NSString*)isoCountryCode
                       areaCode:(NSString*)areaCode
                 numberTypeMask:(NumberTypeMask)numberTypeMask
                    addressType:(NSString*)addressType
                      proofType:(NSDictionary*)proofType;

@end
