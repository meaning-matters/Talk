//
//  NBPeoplePickerNavigationControllerDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class NBPeoplePickerNavigationController;

@protocol NBPeoplePickerNavigationControllerDelegate <NSObject>

//Called when a person is selected
- (BOOL)peoplePickerNavigationController:(NBPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;

//Called when a person's property is selected
- (BOOL)peoplePickerNavigationController:(NBPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;

//Called when cancel is tapped
- (void)peoplePickerNavigationControllerDidCancel:(NBPeoplePickerNavigationController *)peoplePicker;

@end
