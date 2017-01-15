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

        [[NSNotificationCenter defaultCenter] addObserverForName:AppDelegateRemoteNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if (note.userInfo[@"addressUpdates"] != nil)
            {
                [sharedInstance processAddressUpdatesNotificationDictionary:note.userInfo[@"addressUpdates"]];
            }
        }];
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            [sharedInstance processDataUpdatesNotificationDictionary:note.userInfo];
        }];
    });

    return sharedInstance;
}


- (void)processAddressUpdatesNotificationDictionary:(NSDictionary*)dictionary
{
    NSMutableDictionary* addressUpdates = [NSMutableDictionary dictionary];
    NSArray*             addresses      = [[DataManager sharedManager] fetchEntitiesWithName:@"Address"];
    NSArray*             uuids          = [addresses valueForKey:@"uuid"];

    // Convert to binaray representation.
    for (NSString* uuid in dictionary)
    {
        if ([uuids containsObject:uuid])
        {
            NSDictionary*       addressUpdate = dictionary[uuid];
            AddressStatusMask   addressStatusMask;
            RejectionReasonMask rejectionReasonsMask;

            addressStatusMask    = [AddressStatus addressStatusMaskForString:addressUpdate[@"addressStatus"]];
            rejectionReasonsMask = [AddressStatus rejectionReasonsMaskForArray:addressUpdate[@"rejectionReasons"]];

            addressUpdates[uuid] = @{@"addressStatus"    : @(addressStatusMask),
                                     @"rejectionReasons" : @(rejectionReasonsMask)};
        }
        else
        {
            NBLog(@"//### Received notification about address that's unknown to app.");
        }
    }

    // Settings contains the up-to-date state of address updates seen by user.
    // The server however only sends updates once, so the new set of updates
    // received by a notification must be combined with the local set.
    for (NSString* uuid in [Settings sharedSettings].addressUpdates)
    {
        if (addressUpdates[uuid] == nil)
        {
            addressUpdates[uuid] = [Settings sharedSettings].addressUpdates[uuid];
        }
    }

    [self saveAddressUpdates:addressUpdates];
}


- (void)processDataUpdatesNotificationDictionary:(NSDictionary*)dictionary
{
    NSSet*           insertedObjects = dictionary[NSInsertedObjectsKey];
    NSSet*           updatedObjects  = dictionary[NSUpdatedObjectsKey];
    NSSet*           deletedObjects  = dictionary[NSDeletedObjectsKey];
    NSManagedObject* object;

    for (object in [insertedObjects allObjects])
    {
        if ([object.entity.name isEqualToString:@"Address"])
        {
            [self processChangedAddress:(AddressData*)object];
        }
    }

    for (object in [updatedObjects allObjects])
    {
        if ([object.entity.name isEqualToString:@"Address"])
        {
            [self processChangedAddress:(AddressData*)object];
        }
    }

    for (object in [deletedObjects allObjects])
    {
        if ([object.entity.name isEqualToString:@"Address"])
        {
            [self removeAddressUpdateWithUuid:((AddressData*)object).uuid];
        }
    }
}


- (void)processChangedAddress:(AddressData*)address
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    if (address.addressStatus == AddressStatusVerifiedMask)
    {
        addressUpdates[address.uuid] = @{@"addressStatus"    : @(address.addressStatus)};
    }

    if (address.addressStatus == AddressStatusRejectedMask || address.addressStatus == AddressStatusStagedRejectedMask)
    {
        addressUpdates[address.uuid] = @{@"addressStatus"    : @(address.addressStatus),
                                         @"rejectionReasons" : @(address.rejectionReasons)};
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

- (NSUInteger)addressUpdatesCount
{
    return [[Settings sharedSettings].addressUpdates allKeys].count;
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
