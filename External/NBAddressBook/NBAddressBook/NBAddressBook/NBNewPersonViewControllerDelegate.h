//
//  NBNewPersonViewControllerDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/28/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@class NBNewPersonViewController;

@protocol NBNewPersonViewControllerDelegate <NSObject>
- (void)newPersonViewController:(NBNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person;
@end
