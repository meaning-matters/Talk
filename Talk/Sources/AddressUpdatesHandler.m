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
                [sharedInstance processAddressUpdatesNotificationArray:note.userInfo[@"addressUpdates"]];
            }
        }];
    });

    return sharedInstance;
}


- (void)processAddressUpdatesNotificationArray:(NSArray*)array
{
    // Address updates are received as an array of dictionaries.  We convert
    // this to one dictionary because that's an easier to handle form in the app.
    NSMutableDictionary* addressUpdates = [self mutableDictionaryWithArray:array];

    // Settings contains the up-to-date state of address updates seen by user.
    // The server however only sends updates once, so the new set of updates
    // received by a notification must be OR-ed with the local set.
    for (NSString* addressId in [[Settings sharedSettings].addressUpdates allKeys])
    {
        if (addressUpdates[addressId] == nil)
        {
            addressUpdates[addressId] = [Settings sharedSettings].addressUpdates[addressId];
        }
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


- (void)removeAddressUpdate:(NSString*)addressId
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    addressUpdates[addressId] = nil;

    [self saveAddressUpdates:addressUpdates];
}


- (NSDictionary*)addressUpdates
{
    return [Settings sharedSettings].addressUpdates;
}


- (NSUInteger)addressUpdatesCount
{
    return [[Settings sharedSettings].addressUpdates allKeys].count;
}


- (NSMutableDictionary*)mutableDictionaryWithArray:(NSArray*)array
{
    NSMutableDictionary* mutableDictionary = [NSMutableDictionary dictionary];

    for (NSDictionary* dictionary in array)
    {
        [mutableDictionary addEntriesFromDictionary:dictionary];
    }

    return mutableDictionary;
}

@end
