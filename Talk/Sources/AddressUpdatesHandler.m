//
//  AddressUpdatesHandler.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

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
    NSArray*             addresses      = [[DataManager sharedManager] fetchEntitiesWithName:@"Address"
                                                                                    sortKeys:nil
                                                                                   predicate:nil
                                                                        managedObjectContext:nil];
    NSArray*             addressIds     = [addresses valueForKey:@"addressId"];

    // Convert to binaray representation.
    for (NSString* addressId in dictionary)
    {
        if ([addressIds containsObject:addressId])
        {
            NSDictionary*       addressUpdate = dictionary[addressId];
            AddressStatusMask   addressStatusMask;
            RejectionReasonMask rejectionReasonsMask;

            addressStatusMask    = [AddressStatus addressStatusMaskForString:addressUpdate[@"addressStatus"]];
            rejectionReasonsMask = [AddressStatus rejectionReasonsMaskForArray:addressUpdate[@"rejectionReasons"]];

            addressUpdates[addressId] = @{@"addressStatus"    : @(addressStatusMask),
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
    for (NSString* addressId in [Settings sharedSettings].addressUpdates)
    {
        if (addressUpdates[addressId] == nil)
        {
            addressUpdates[addressId] = [Settings sharedSettings].addressUpdates[addressId];
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
            [self removeAddressUpdateWithId:((AddressData*)object).addressId];
        }
    }
}


- (void)processChangedAddress:(AddressData*)address
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    if (address.addressStatus == AddressStatusVerifiedMask)
    {
        addressUpdates[address.addressId] = @{@"addressStatus"    : @(address.addressStatus)};
    }

    if (address.addressStatus == AddressStatusRejectedMask)
    {
        addressUpdates[address.addressId] = @{@"addressStatus"    : @(address.addressStatus),
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


- (NSDictionary*)addressUpdateWithId:(NSString *)addressId
{
    return [Settings sharedSettings].addressUpdates[addressId];
}


- (void)removeAddressUpdateWithId:(NSString*)addressId
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    addressUpdates[addressId] = nil;

    [self saveAddressUpdates:addressUpdates];
}

@end
