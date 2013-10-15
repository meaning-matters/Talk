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

    // Performing automatic lightweight migration by passing the following dictionary as the options parameter.
    // But, lightweight migration will only work for a limited set of schema changes; consult the
    // "Core Data Model Versioning and Data Migration Programming Guide" for details.
    // See also: https://developer.apple.com/library/mac/#documentation/Cocoa/Conceptual/CoreDataVersioning/Articles/Introduction.html#//apple_ref/doc/uid/TP40004399-CH1-SW1
    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES};
    NSError*      error   = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeUrl
                                                         options:options
                                                           error:&error])
    {
        NSLog(@"Unresolved CoreData error %@, %@", error, [error userInfo]);
        [self handleError];

        return nil;
    }
    else
    {
        return _persistentStoreCoordinator;
    }
}


#pragma mark - Public API

- (void)saveContext
{
    NSError* error = nil;

    if (self.managedObjectContext != nil)
    {
        if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error])
        {
            NSLog(@"Unresolved CoreData error %@, %@", error, [error userInfo]);
            [self handleError];
        }
    }
}


- (void)removeAll
{
    for (NSManagedObject* object in [self.managedObjectContext registeredObjects])
    {
        [self.managedObjectContext deleteObject:object];
    }

    [self saveContext];
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
            message = NSLocalizedStringWithDefaultValue(@"DataManager SynchronizeFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while synchronizing over internet: "
                                                        @"%@\n\nPlease try again later.",
                                                        @"Message telling that loading data over internet failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
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


- (void)handleError
{
    [[NSFileManager defaultManager] removeItemAtURL:storeUrl error:nil];

    NSString* title;
    NSString* message;
    NSString* button;

    title   = NSLocalizedStringWithDefaultValue(@"DataManager DatabaseErrorTitle", nil,
                                                [NSBundle mainBundle], @"Database Problem",
                                                @"Alert title: App's internal database has problem.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"DataManager DatabaseErrorMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Due to a problem, the internal database will be recreated.  "
                                                @"Your call history and favorites will be lost."
                                                @"\nSynchronize to reload your numbers and forwardings.",
                                                @"Message telling that App's internal database has problem\n"
                                                @"[iOS alert message size]");
    button  = NSLocalizedStringWithDefaultValue(@"DataManager DatabaseErrorButtonTitle", nil,
                                                [NSBundle mainBundle],
                                                @"Exit App",
                                                @"Exit app button title\n"
                                                @"[iOS button title size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        UILocalNotification* notification = [[UILocalNotification alloc] init];
        NSString*            body;
        NSString*            action;

        body   = NSLocalizedStringWithDefaultValue(@"DataManager DatabaseErrorNotificationMessage",
                                                   nil, [NSBundle mainBundle],
                                                   @"Open the app, and your numbers and forwardings will be "
                                                   @"reloaded.",
                                                   @"Message telling ...\n"
                                                   @"[iOS alert message size]");
        action = NSLocalizedStringWithDefaultValue(@"DataManager DatabaseErrorNotificationButton",
                                                   nil, [NSBundle mainBundle],
                                                   @"Open",
                                                   @"Message telling ...\n"
                                                   @"[iOS alert message size]");

        notification.fireDate    = [NSDate dateWithTimeIntervalSinceNow:1.0];
        notification.alertBody   = body;
        notification.alertAction = action;
        notification.userInfo    = @{@"source" : @"databaseError"};
        [[UIApplication sharedApplication] scheduleLocalNotification:notification];

        abort();
    }
                         cancelButtonTitle:button
                         otherButtonTitles:nil];
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
    [[WebClient sharedClient] retrieveNumberList:^(NSError* webError, NSArray* array)
    {
        if (webError == nil)
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
            else
            {
                completion(error);

                return;
            }

            __block int count = array.count;
            for (NSString* e164 in array)
            {
                [[WebClient sharedClient] retrieveNumberForE164:e164
                                                   currencyCode:[Settings sharedSettings].currencyCode
                                                          reply:^(NSError* webError, NSDictionary* dictionary)
                {
                    if (error == nil && webError == nil)
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
                        error = webError;
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
            completion(webError);
        }
    }];
}


- (void)synchronizeForwardings:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveIvrList:^(NSError* webError, NSArray* array)
    {
        if (webError == nil)
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
            else
            {
                completion(error);

                return;
            }

            __block int  count   = array.count;
            for (NSString* uuid in array)
            {
                [[WebClient sharedClient] retrieveIvrForUuid:uuid
                                                       reply:^(NSError* webError, NSString* name, NSArray* statements)
                {
                    if (error == nil && webError == nil)
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

                        forwarding.uuid       = uuid;
                        forwarding.name       = name;
                        forwarding.statements = [Common jsonStringWithObject:statements];
                    }
                    else if (error == nil)
                    {
                        error = webError;
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
            completion(webError);
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
        [[WebClient sharedClient] retrieveIvrOfE164:number.e164 reply:^(NSError* webError, NSString* uuid)
        {
            if (error == nil && webError == nil)
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
                error = webError;
            }

            if (--count == 0)
            {
                completion(error);
            }
        }];
    }
}

@end
