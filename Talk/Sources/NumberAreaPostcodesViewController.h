//
//  NumberAreaPostcodesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"
#import "AddressData.h"


@interface NumberAreaPostcodesViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithCitiesArray:(NSArray*)array address:(AddressData*)address;

@end
