//
//  AddressUpdatesHandler.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//
//  Address updates are stored in Settings in order to remember which updates
//  have been seen by the user.

#import "AddressUpdatesHandler.h"
#import "AppDelegate.h"
#import "Settings.h"
#import "AddressData.h"
#import "AddressStatus.h"
#import "DataManager.h"

NSString* const AddressUpdatesNotification = @"AddressUpdatesNotification";


@implementation AddressUpdatesHandler

+ (AddressUpdatesHandler*)sharedHandler
{
    static AddressUpdatesHandler* sharedInstance;
    static dispatch_once_t        onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[AddressUpdatesHandler alloc] init];
    });

    return sharedInstance;
}


- (void)processChangedAddress:(AddressData*)address
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    if (address.addressStatus == AddressStatusVerifiedMask)
    {
        addressUpdates[address.uuid] = @{@"addressStatus"    : @(address.addressStatus)};
    }

    if (address.addressStatus == AddressStatusRejectedMask)
    {
        addressUpdates[address.uuid] = @{@"addressStatus"    : @(address.addressStatus),
                                         @"rejectionReasons" : @(address.rejectionReasons)};
    }

    if (address.addressStatus == AddressStatusDisabledMask)
    {
        addressUpdates[address.uuid] = @{@"addressStatus"    : @(address.addressStatus)};
    }

    [self saveAddressUpdates:addressUpdates];
}


- (void)saveAddressUpdates:(NSDictionary*)addressUpdates
{
    [Settings sharedSettings].addressUpdates = addressUpdates;

    [[NSNotificationCenter defaultCenter] postNotificationName:AddressUpdatesNotification
                                                        object:self
                                                      userInfo:addressUpdates];
}


#pragma Public

- (NSUInteger)badgeCount
{
    NSUInteger badgeCount = 0;
    NSArray* addresses = [[DataManager sharedManager] fetchEntitiesWithName:@"Address"];
    for (AddressData* address in addresses)
    {
        NSDictionary* addressUpdate = [[AddressUpdatesHandler sharedHandler] addressUpdateWithUuid:address.uuid];
        switch (address.addressStatus)
        {
            case AddressStatusVerificationNotRequiredMask:
            {
                badgeCount += (addressUpdate == nil) ? 0 : 1;
                break;
            }
            case AddressStatusVerifiedMask:
            {
                badgeCount += (addressUpdate == nil) ? 0 : 1;
                break;
            }
            case AddressStatusRejectedMask:
            {
                badgeCount++;
                break;
            }
            case AddressStatusDisabledMask:
            {
                badgeCount++;
                break;
            }
        }
    }

    return badgeCount;
}


- (NSDictionary*)addressUpdateWithUuid:(NSString*)uuid
{
    return [Settings sharedSettings].addressUpdates[uuid];
}


- (void)removeAddressUpdateWithUuid:(NSString*)uuid
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    addressUpdates[uuid] = nil;

    [self saveAddressUpdates:addressUpdates];
}

@end
