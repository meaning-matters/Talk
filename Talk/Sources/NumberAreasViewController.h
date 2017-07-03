//
//  NumberAreasViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "NumberType.h"
#import "AddressType.h"


@interface NumberAreasViewController : SearchTableViewController

- (instancetype)initWithIsoCountryCode:(NSString*)isoCountryCode
                                 state:(NSDictionary*)state
                        numberTypeMask:(NumberTypeMask)numberTypeMask
                       addressTypeMask:(AddressTypeMask)theAddressTypeMask
                    isFilteringEnabled:(BOOL)isFilteringEnabled;

@end
