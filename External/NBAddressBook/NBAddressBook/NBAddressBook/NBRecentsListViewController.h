//
//  NBRecentsListViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/18/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "CallRecordData.h"
#import "NBRecentCallCell.h"
#import "NSString+Common.h"
#import "NBAddressBookManager.h"
#import "NBRecentContactViewController.h"
#import "NBRecentUnknownContactViewController.h"
#import "NBAddUnknownContactDelegate.h"


@interface NBRecentsListViewController : UITableViewController <UIActionSheetDelegate, NBAddUnknownContactDelegate, NSFetchedResultsControllerDelegate>
{
    //The navigation bar buttons
    UIBarButtonItem* editButton;
    UIBarButtonItem* doneButton;
    UIBarButtonItem* clearButton;
    
    //Indicate to only do this the first time
    BOOL firstLoad;
    
    //Flag to indicate we have more calls and a reload is required
    int numRecentCalls;
}

- (instancetype)init;

// Gets missed call from server.
- (void)refresh:(id)sender;

@end
