//
//  NBNewFieldTableViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/5/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Class used to select a field to add to the Name-section of a person

#import <UIKit/UIKit.h>
#import "NBContactStructureManager.h"
#import "NBPersonCellInfo.h"
#import "NBPersonViewDelegate.h"

@interface NBNewFieldTableViewController : UITableViewController

@property (nonatomic) id<NBPersonViewDelegate>personViewDelegate;
@property (nonatomic) NBContactStructureManager * structureManager;
@end
