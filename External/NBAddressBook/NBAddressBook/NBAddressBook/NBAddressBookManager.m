//
//  NBAddressBookManager.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import "NBAddressBookManager.h"
#import "Common.h"


@interface NBAddressBookManager () <ABUnknownPersonViewControllerDelegate>

@property (nonatomic, strong) UIViewController* addToContactViewController;

@end


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
                if (granted)
                {
                    // Reloading contacts happens on another thread. To prevent conflicts that may lead to a crash,
                    // we must first add the company address, and after that request a contacts reload.

                    [Common addCompanyToAddressBook:addressBook];

                    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
                }
            });
        });
    }
}


#pragma mark - Adding Number To Contact

- (void)addNumber:(NSString*)number toContactAsType:(NSString*)type viewController:(UIViewController*)viewController
{
    self.addToContactViewController = viewController;

    ABRecordRef            contactRef  = ABPersonCreate();
    ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
    CFStringRef            typeLabel   = (type.length == 0) ? kABOtherLabel : CFBridgingRetain(type);
    ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)number, typeLabel, NULL);
    ABRecordSetValue(contactRef, kABPersonPhoneProperty, numberMulti, nil);

    ABUnknownPersonViewController* personViewController = [[ABUnknownPersonViewController alloc] init];
    personViewController.unknownPersonViewDelegate = self;
    personViewController.displayedPerson = contactRef;
    CFRelease(personViewController.displayedPerson);

    personViewController.title = NSLocalizedStringWithDefaultValue(@"Keypad AddToContact", nil, [NSBundle mainBundle],
                                                                   @"Add to Contacts",
                                                                   @"Title.\n"
                                                                   @"[].");

    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc] initWithRootViewController:personViewController];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAddToContact)];
    personViewController.navigationItem.rightBarButtonItem = cancelButton;

    [viewController presentViewController:navigationController animated:YES completion:nil];
}


- (void)cancelAddToContact
{
    [self.addToContactViewController dismissViewControllerAnimated:YES completion:nil];
    self.addToContactViewController = nil;
}


#pragma mark - ABUnknownPersonViewControllerDelegate

- (void)unknownPersonViewController:(ABUnknownPersonViewController*)unknownPersonView
                 didResolveToPerson:(ABRecordRef)person
{
    [self.addToContactViewController dismissViewControllerAnimated:YES completion:nil];
    self.addToContactViewController = nil;
}


- (BOOL)unknownPersonViewController:(ABUnknownPersonViewController*)unknownPersonViewController
shouldPerformDefaultActionForPerson:(ABRecordRef)person
                           property:(ABPropertyID)property
                         identifier:(ABMultiValueIdentifier)identifier
{
    // We don't want to allow default action while adding to contact,
    // as this may result in the user leaving the app.
    return NO;
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
