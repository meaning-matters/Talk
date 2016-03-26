//
//  NumberAreaCitiesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "AddressData.h"


@interface NumberAreaCitiesViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithCitiesArray:(NSArray*)citiesArray address:(AddressData *)address;

@end
