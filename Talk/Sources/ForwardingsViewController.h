//
//  ForwardingsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ItemsViewController.h"


@interface ForwardingsViewController : ItemsViewController

@property (nonatomic, weak) IBOutlet UITableView* recordingsTableView;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
