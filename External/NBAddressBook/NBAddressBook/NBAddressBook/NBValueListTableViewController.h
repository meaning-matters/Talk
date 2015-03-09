//
//  NBValueListTableViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/6/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Class for selecting a new label or ringtone value

#import <UIKit/UIKit.h>
#import "NBContactStructureManager.h"
#import "NBCustomValueTableViewController.h"

@interface NBValueListTableViewController : UITableViewController
{
    NSArray * defaultLabels;
    NSMutableArray * customLabels;
}

//The used structure
@property (nonatomic) NBContactStructureManager * structureManager;

+ (void)setLabelType:(LabelType)labelTypeParam;
+ (void)setTargetIndexPath:(NSIndexPath*)indexPathParam;
+ (NSIndexPath*)getTargetIndexPath;
@end