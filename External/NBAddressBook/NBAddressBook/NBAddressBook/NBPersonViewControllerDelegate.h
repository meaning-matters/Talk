//
//  NBPersonViewControllerDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class NBPersonViewController;

@protocol NBPersonViewControllerDelegate <NSObject>
- (BOOL)personViewController:(NBPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue;
@end
