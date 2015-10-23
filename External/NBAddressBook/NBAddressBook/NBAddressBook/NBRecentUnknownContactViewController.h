//
//  NBRecentUnknownContactViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBUnknownPersonViewController.h"
#import "NBRecentContactEntry.h"
#import "NBRecentContactViewController.h"
#import "NBAddressBookManager.h"
#import <AddressBook/AddressBook.h>
#import "NBAppDelegate.h"
#import "NSString+Common.h"
#import "NBCallsView.h"
#import "NBAddUnknownContactDelegate.h"

@interface NBRecentUnknownContactViewController : NBUnknownPersonViewController
{
}

@property (nonatomic) id<NBAddUnknownContactDelegate>addUnknownContactDelegate;

//The array of recent entries
- (void)setRecentEntryArray:(NSArray*)entryArray;

@end
