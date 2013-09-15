//
//  CoreDataManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "DataManager.h"
#import "NumberData.h"
#import "ForwardingData.h"
#import "Common.h"
#import "WebClient.h"
#import "Settings.h"
#import "Base64.h"
#import "BlockAlertView.h"
#import "Strings.h"


@interface DataManager ()
{
    NSURL*  storeUrl;
}

@end


@implementation DataManager

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - Singleton Stuff

+ (DataManager*)sharedManager
{
    static DataManager*     sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[DataManager alloc] init];

        sharedInstance->storeUrl = [Common documentUrl:@"Data.sqlite"];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [sharedInstance saveContext];
         }];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
         {
             [sharedInstance saveContext];
         }];
    });
    
    return sharedInstance;
}


#pragma mark - Core Data

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext*)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return _managedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel*)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Data" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

    return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }

    NSError*    error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeUrl
                                                         options:nil
                                                           error:&error])
    {
        /* abort() causes the application to generate a crash log and terminate. You should not use this
         function in a shipping application, although it may be useful during development.

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path.
         Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil]

         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}

         Lightweight migration will only work for a limited set of schema changes; consult
         "Core Data Model Versioning and Data Migration Programming Guide" for details.
         */
#warning //### Implement migration https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/Introduction.html#//apple_ref/doc/uid/TP40004399-CH1-SW1

        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}


#pragma mark - Public API

- (void)saveContext
{
    NSError*                error = nil;
    NSManagedObjectContext* managedObjectContext = self.managedObjectContext;

    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
#warning    //### Replace this implementation with code to handle the error appropriately.
            //    abort() causes the application to generate a crash log and terminate.
            //    You should not use this function in a shipping application, although it
            //    may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (void)removeAll
{
    [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];

    for (NSManagedObject* object in [self.managedObjectContext registeredObjects])
    {
        [self.managedObjectContext deleteObject:object];
    }

    _managedObjectModel         = nil;
    _managedObjectContext       = nil;
    _persistentStoreCoordinator = nil;
}


- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName withSortKey:(NSString*)key error:(NSError**)error
{
    NSFetchedResultsController* resultsController;
    NSFetchRequest*             fetchRequest;
    NSSortDescriptor*           nameDescriptor;
    NSArray*                    sortDescriptors;

    fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:entityName];
    nameDescriptor  = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
    sortDescriptors = [[NSArray alloc] initWithObjects:nameDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                            managedObjectContext:self.managedObjectContext
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];

    *error = nil;
    if ([resultsController performFetch:error] == YES)
    {
        return resultsController;
    }
    else
    {
        return nil;
    }
}


- (void)synchronizeWithServer:(void (^)(NSError* error))completion
{
    [self synchronizeAll:^(NSError* error)
    {
        if (error != nil)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"DataManager SynchronizeFailedTitle", nil,
                                                        [NSBundle mainBundle], @"Synchronization Failed",
                                                        @"Alert title: Data could not be loaded.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyCredit SynchronizeFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while synchronizing over internet: "
                                                        @"%@.\n\nPlease try again later.",
                                                        @"Message telling that loading data over internet failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [error localizedDescription]];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                completion(error);
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else
        {
            completion(error);
        }
    }];
}


#pragma mark - Server Refresh

- (void)synchronizeAll:(void (^)(NSError* error))completion
{
    [self synchronizeNumbers:^(NSError* error)
    {
        if (error == nil)
        {
            [self synchronizeForwardings:^(NSError* error)
            {
                if (error == nil)
                {
                    [self synchronizeIvrs:^(NSError* error)
                    {
                        if (error == nil)
                        {
                            error = nil;
                            [self.managedObjectContext save:&error];
                            completion(error);
                        }
                        else
                        {
                            [self.managedObjectContext rollback];
                            completion(error);
                        }
                    }];
                }
                else
                {
                    [self.managedObjectContext rollback];
                    completion(error);
                }
            }];
        }
        else
        {
            [self.managedObjectContext rollback];
            completion(error);
        }
    }];
}


- (void)synchronizeNumbers:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveNumberList:^(WebClientStatus status, NSArray* array)
    {
        if (status == WebClientStatusOk)
        {
            // Delete Numbers that are no longer on the server.
            __block NSError* error        = nil;
            NSFetchRequest*  request      = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"NOT (e164 IN %@)", array]];
            NSArray*         deleteArray  = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object];
                }
            }

            if (error != nil)
            {
                completion(error);
                return;
            }

            __block int count = array.count;
            for (NSString* e164 in array)
            {
                [[WebClient sharedClient] retrieveNumberForE164:e164
                                                   currencyCode:[Settings sharedSettings].currencyCode
                                                          reply:^(WebClientStatus status, NSDictionary* dictionary)
                {
                    if (error == nil && status == WebClientStatusOk)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"e164 == %@", dictionary[@"e164"]]];

                        NumberData* number = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (number == nil)
                        {
                            number = (NumberData*)[NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                                                                inManagedObjectContext:self.managedObjectContext];
                        }

                        number.name           = dictionary[@"name"];
                        number.e164           = dictionary[@"e164"];
                        number.numberType     = dictionary[@"numberType"];
                        number.areaCode       = dictionary[@"areaCode"];
                        number.areaName       = dictionary[@"areaName"];
                        number.numberCountry  = dictionary[@"isoCountryCode"];
                        [number setPurchaseDateWithString:dictionary[@"purchaseDateTime"]];
                        [number setRenewalDateWithString:dictionary[@"renewalDateTime"]];
                        number.salutation     = dictionary[@"info"][@"salutation"];
                        number.firstName      = dictionary[@"info"][@"firstName"];
                        number.lastName       = dictionary[@"info"][@"lastName"];
                        number.company        = dictionary[@"info"][@"company"];
                        number.street         = dictionary[@"info"][@"street"];
                        number.building       = dictionary[@"info"][@"building"];
                        number.city           = dictionary[@"info"][@"city"];
                        number.zipCode        = dictionary[@"info"][@"zipCode"];
                        number.stateName      = dictionary[@"info"][@"stateName"];
                        number.stateCode      = dictionary[@"info"][@"stateCode"];
                        number.addressCountry = dictionary[@"info"][@"isoCountryCode"];
                        number.proofImage     = [Base64 decode:dictionary[@"info"][@"proofImage"]];
                    }
                    else if (error == nil)
                    {
                        error = [Common errorWithCode:status description:[WebClient localizedStringForStatus:status]];
                    }

                    if (--count == 0)
                    {
                        completion(error);
                    }
                }];
            }
        }
        else
        {
            completion([Common errorWithCode:status description:[WebClient localizedStringForStatus:status]]);
        }
    }];
}


- (void)synchronizeForwardings:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveIvrList:^(WebClientStatus status, NSArray* array)
    {
        if (status == WebClientStatusOk)
        {
            // Delete IVRs that are no longer on the server.
            __block NSError* error       = nil;
            NSFetchRequest* request      = [NSFetchRequest fetchRequestWithEntityName:@"Forwarding"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"NOT (uuid IN %@)", array]];
            NSArray*        deleteArray  = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object];
                }
            }

            if (error != nil)
            {
                completion(error);
                return;
            }

            __block int  count   = array.count;
            for (NSString* uuid in array)
            {
                [[WebClient sharedClient] retrieveIvrForUuid:uuid
                                                       reply:^(WebClientStatus status, NSString* name, NSArray* statements)
                {
                    if (error == nil && status == WebClientStatusOk)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Forwarding"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        ForwardingData* forwarding;
                        forwarding = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        //### Handle error.
                        if (forwarding == nil)
                        {
                            forwarding = (ForwardingData*)[NSEntityDescription insertNewObjectForEntityForName:@"Forwarding"
                                                                                        inManagedObjectContext:self.managedObjectContext];
                        }

                        forwarding.uuid = uuid;
                        forwarding.name = name;
                        forwarding.statements = [Common jsonStringWithObject:statements];
                    }
                    else if (error == nil)
                    {
                        error = [Common errorWithCode:status description:[WebClient localizedStringForStatus:status]];
                    }

                    if (--count == 0)
                    {
                        completion(error);
                    }
                }];
            }
        }
        else
        {
            completion([Common errorWithCode:status description:[WebClient localizedStringForStatus:status]]);
        }
    }];
}


- (void)synchronizeIvrs:(void (^)(NSError* error))completion
{
    __block NSError* error   = nil;
    NSFetchRequest*  request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
    NSArray*         array   = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (error != nil)
    {
        completion(error);
        return;
    }

    __block int count = array.count;
    for (NumberData* number in array)
    {
        [[WebClient sharedClient] retrieveIvrOfE164:number.e164
                                              reply:^(WebClientStatus status, NSString* uuid)
        {
            if (error == nil && status == WebClientStatusOk)
            {
                if (uuid == nil)
                {
                    number.forwarding = nil;
                }
                else
                {
                    // Lookup the forwarding.
                    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Forwarding"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                    ForwardingData* forwarding = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                    if (forwarding != nil)
                    {
                        number.forwarding = forwarding;
                    }
                }
            }
            else if (error == nil)
            {
                error = [Common errorWithCode:status description:[WebClient localizedStringForStatus:status]];
            }

            if (--count == 0)
            {
                completion(error);
            }
        }];
    }
}

@end
