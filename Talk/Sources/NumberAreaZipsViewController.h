//
//  NumberAreaZipsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"


@interface NumberAreaZipsViewController : SearchTableViewController <UITableViewDelegate>

- (instancetype)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info;

@end
