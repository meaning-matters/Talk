//
//  NBTestDelegate.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/31/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBTestDelegate.h"

@implementation NBTestDelegate

- (void)unknownPersonViewController:(NBUnknownPersonViewController *)unknownPersonView didResolveToPerson:(ABRecordRef)person
{
    
}

- (BOOL)unknownPersonViewController:(NBUnknownPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier
{
    return YES;
}

@end
