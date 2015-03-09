//
//  NBUnknownPersonViewController.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class NBUnknownPersonViewController;

@protocol NBUnknownPersonViewControllerDelegate <NSObject>

- (void)unknownPersonViewController:(NBUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person;
- (BOOL)unknownPersonViewController:(NBUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;

@end
