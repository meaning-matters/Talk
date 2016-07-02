//
//  IncomingChargesViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 02/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NumberData;


@interface IncomingChargesViewController : UITableViewController

- (instancetype)initWithArea:(NSDictionary*)area;

- (instancetype)initWithNumber:(NumberData*)number;

+ (BOOL)hasIncomingChargesWithArea:(NSDictionary*)area;

+ (BOOL)hasIncomingChargesWithNumber:(NumberData*)number;

@end
