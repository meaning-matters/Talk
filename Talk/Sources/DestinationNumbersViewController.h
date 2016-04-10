//
//  DestinationNumbersViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemsViewController.h"

@class DestinationData;


@interface DestinationNumbersViewController : UITableViewController

- (instancetype)initWithDestination:(DestinationData*)destination;

@end
