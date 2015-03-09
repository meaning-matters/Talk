//
//  NBAddressBookManager.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//
//  Single point of access management to the iOS address book

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "NSString+Common.h"

@class NBRecentContactEntry;


@protocol AddressBookDelegate <NSObject>

- (NSString*)formatNumber:(NSString*)number;

- (UIColor*)tintColor;

- (UIColor*)deleteTintColor;

- (void)saveContext;

- (NSString*)localizedFormattedPrice2ExtraDigits:(float)price;

- (void)updateRecent:(NBRecentContactEntry*)recent completion:(void (^)(BOOL success, BOOL ended))completion;

- (BOOL)matchRecent:(NBRecentContactEntry*)recent withNumber:(NSString*)number;

@end



@interface NBAddressBookManager : NSObject
{
    ABAddressBookRef addressBook;
}


@property (nonatomic, weak) id<AddressBookDelegate> delegate;


//Singleton-addressbook available across the app
+ (NBAddressBookManager*)sharedManager;

//Reload the address book
- (void)reloadAddressBook;

//Retrieve, save and delete from and to the address book
- (ABAddressBookRef)getAddressBook;

@end
