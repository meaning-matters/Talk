//
//  NBGroupsTableViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/2/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Displaying the existing groups and selecting/deselecting them

#import <UIKit/UIKit.h>
#import <AddressBook/AddressBook.h>
#import "NBAddressBookManager.h"
#import "NBGroup.h"

@interface NBGroupsTableViewController : UITableViewController
{
    NSArray* groupsDatasource;
}

- (void)setGroupsDatasource:(NSArray*)groupsDictionary;

@end
