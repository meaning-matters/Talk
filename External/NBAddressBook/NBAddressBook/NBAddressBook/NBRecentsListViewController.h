//
//  NBRecentsListViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/18/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "NBAppDelegate.h"
#import "NBRecentContactEntry.h"
#import "NBRecentCallCell.h"
#import "NSString+Common.h"
#import "NBAddressBookManager.h"
#import "NBRecentContactViewController.h"
#import "NBRecentUnknownContactViewController.h"
#import "NBAddUnknownContactDelegate.h"

@interface NBRecentsListViewController : UITableViewController <UIActionSheetDelegate, NBAddUnknownContactDelegate, NSFetchedResultsControllerDelegate>
{
    //The navigation bar buttons
    UIBarButtonItem * editButton;
    UIBarButtonItem * doneButton;
    UIBarButtonItem * clearButton;
    
    //The action sheet to clear the contacts
    UIActionSheet * clearActionSheet;
    
    //The recent contacts-datasource with grouping (date-sorted array with arrays (1..*) of recent entries)
    NSMutableArray * dataSource;
    
    //Flag to indicate we're displaying missed calls only
    BOOL missedCallsOnly;
    
    //Indicate to only do this the first time
    BOOL firstLoad;
    
    //Flag to indicate we have more calls and a reload is required
    int numRecentCalls;
}

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
