//
//  NumberAreaTitlesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 18/08/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddressData.h"


@interface NumberAreaTitlesViewController : UITableViewController

- (instancetype)initWithAddress:(AddressData*)address;

@end
