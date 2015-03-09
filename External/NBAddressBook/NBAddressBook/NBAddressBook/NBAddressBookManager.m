//
//  NBAddressBookManager.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBAddressBookManager.h"
#ifndef NB_STANDALONE
#import "Common.h"
#endif

@implementation NBAddressBookManager

#pragma mark - Singleton

+ (NBAddressBookManager*)sharedManager
{
    static NBAddressBookManager* instance;
    static dispatch_once_t       onceToken;

    dispatch_once(&onceToken, ^
    {
        instance = [[self alloc] init];
    });

    return instance;
}


- (instancetype)init
{
    if (self = [super init])
    {
        //Register for external updating
        ABAddressBookRegisterExternalChangeCallback([self getAddressBook], addressBookChanged, (__bridge void *)(self));
    }

    return self;
}


#pragma mark - Reload the address book (external changes)
- (void)reloadAddressBook
{
    CFErrorRef error;
    addressBook = ABAddressBookCreateWithOptions(nil, &error);

    if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
    {
        ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error)
        {
            // ABAddressBook doesn't guarantee execution of this block on main thread, so we'll force it.
            dispatch_async(dispatch_get_main_queue(), ^
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];

#ifndef NB_STANDALONE
                if (granted)
                {
                    [Common addCompanyToAddressBook:addressBook];
                }
#endif
            });
        });
    }
}


#pragma mark - Get address book
- (ABAddressBookRef)getAddressBook
{
    if (addressBook == nil)
    {
        [self reloadAddressBook];
    }

    return addressBook;
}

#pragma mark - Address book callback
void addressBookChanged(ABAddressBookRef reference, CFDictionaryRef dictionary, void *context)
{
    //The address book is dirty, reload it
    [[NBAddressBookManager sharedManager] reloadAddressBook];
    if ([[NBAddressBookManager sharedManager] getAddressBook] != nil)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
    }
}

#pragma mark - Cleanup
- (void)dealloc
{
    ABAddressBookUnregisterExternalChangeCallback([self getAddressBook], addressBookChanged, (__bridge void *)(self));
}

@end
