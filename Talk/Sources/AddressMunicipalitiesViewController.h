//
//  AddressMunicipalitiesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 11/06/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "AddressData.h"

@interface AddressMunicipalitiesViewController : SearchTableViewController

- (instancetype)initWithMunicipalitiesArray:(NSArray*)municipalitiesArray address:(AddressData*)address;

@end
