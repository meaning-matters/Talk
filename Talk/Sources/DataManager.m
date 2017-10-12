//
//  CoreDataManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "DataManager.h"
#import "NumberData.h"
#import "DestinationData.h"
#import "PhoneData.h"
#import "AddressData.h"
#import "RecordingData.h"
#import "Common.h"
#import "WebClient.h"
#import "Settings.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "NetworkStatus.h"
#import "AddressStatus.h"
#import "AddressUpdatesHandler.h"
#import "MessageData.h"


@interface DataManager ()
{
    NSURL* storeUrl;
    BOOL   isSynchronizing;
}

@end


@implementation DataManager

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - Singleton Stuff

+ (DataManager*)sharedManager
{
    static DataManager*    sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[DataManager alloc] init];

        sharedInstance->storeUrl = [Common documentUrl:@"Data.sqlite"];

        [[NSNotificationCenter defaultCenter] addObserverForName:AppDelegateRemoteNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if ([note.userInfo[@"synchronize"] boolValue] == YES)
            {
                [sharedInstance synchronizeAll:nil];
            }
        }];

        if ([Settings sharedSettings].needsServerSync == YES)
        {
            __block id observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                                    object:nil
                                                                                     queue:[NSOperationQueue mainQueue]
                                                                                usingBlock:^(NSNotification* note)
            {
                if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCellular ||
                    [NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableWifi)
                {
                    [Settings sharedSettings].needsServerSync = NO;
                    [[NSNotificationCenter defaultCenter] removeObserver:observer];
                    [sharedInstance synchronizeAll:nil];
                }
            }];
        }
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

    NSPersistentStoreCoordinator* coordinator = self.persistentStoreCoordinator;
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

    NSURL* modelURL = [[NSBundle mainBundle] URLForResource:@"Data2.2"
                                              withExtension:@"mom"
                                               subdirectory:@"Data.momd"];

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
    NSDictionary* options = @{NSMigratePersistentStoresAutomaticallyOption: @YES,
                              NSInferMappingModelAutomaticallyOption      : @YES,
                              NSPersistentStoreFileProtectionKey          : NSFileProtectionCompleteUntilFirstUserAuthentication}; // The default, but want to make it explicit.
    NSError*      error   = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeUrl
                                                         options:options
                                                           error:&error])
    {
        [self handleError:error];

        return nil;
    }
    else
    {
        return _persistentStoreCoordinator;
    }
}


#pragma mark - Public API

- (void)saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    @synchronized (self)
    {
        NSError* error = nil;

        managedObjectContext = (managedObjectContext != nil) ? managedObjectContext : self.managedObjectContext;

        if (managedObjectContext != nil)
        {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
            {
                [self handleError:error];
            }

            // Recursively save children up until parent.
            if (managedObjectContext != self.managedObjectContext)
            {
                [self saveManagedObjectContext:managedObjectContext.parentContext];
            }
        }
    }
}


- (void)removeAll
{
    [self.managedObjectContext lock];

    // Make sure that all objects appear in registeredObjects.
    [self fetchEntitiesWithName:@"Address"];
    [self fetchEntitiesWithName:@"CallerId"];
    [self fetchEntitiesWithName:@"CallRecord"];
    [self fetchEntitiesWithName:@"Destination"];
    [self fetchEntitiesWithName:@"Number"];
    [self fetchEntitiesWithName:@"Phone"];
    [self fetchEntitiesWithName:@"Recording"];
    [self fetchEntitiesWithName:@"Message"];

    for (NSManagedObject* object in [self.managedObjectContext registeredObjects])
    {
        [self.managedObjectContext deleteObject:object];
    }

    NSError* error = nil;
    if ([self.managedObjectContext save:&error] == NO)
    {
        [self handleError:error];
    }

    [_managedObjectContext unlock];
}


- (NSArray*)fetchEntitiesWithName:(NSString*)entityName
                         sortKeys:(NSArray*)sortKeys
                        predicate:(NSPredicate*)predicate
             managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSError*        error;
    NSFetchRequest* fetchRequest;
    NSArray*        objects;

    managedObjectContext = (managedObjectContext != nil) ? managedObjectContext : self.managedObjectContext;
    fetchRequest         = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [self setSortKeys:sortKeys ofFetchRequest:fetchRequest];
    [fetchRequest setPredicate:predicate];

    objects = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if (objects == nil)
    {
        [self handleError:error];
    }

    return objects;
}


- (NSArray*)fetchEntitiesWithName:(NSString*)entityName
{
    return [self fetchEntitiesWithName:entityName sortKeys:nil predicate:nil managedObjectContext:nil];
}


- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName
                                            withSortKeys:(NSArray*)sortKeys
                                    managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    NSFetchedResultsController* resultsController;
    NSFetchRequest*             fetchRequest;

    managedObjectContext = (managedObjectContext != nil) ? managedObjectContext : self.managedObjectContext;
    fetchRequest         = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [self setSortKeys:sortKeys ofFetchRequest:fetchRequest];

    resultsController    = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                               managedObjectContext:managedObjectContext
                                                                 sectionNameKeyPath:nil
                                                                          cacheName:nil];

    NSError* error;
    if ([resultsController performFetch:&error] == YES)
    {
        return resultsController;
    }
    else
    {
        [self handleError:error];

        return nil;
    }
}


- (void)setSortKeys:(NSArray*)sortKeys ofFetchRequest:(NSFetchRequest*)fetchRequest
{
    NSMutableArray* sortDescriptors = [NSMutableArray array];
    
    for (NSString* sortKey in sortKeys)
    {
        [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:sortKey ascending:YES]];
    }

    [fetchRequest setSortDescriptors:sortDescriptors];
}


- (void)setSortKeys:(NSArray*)sortKeys ofResultsController:(NSFetchedResultsController*)resultsController
{
    NSError* error;

    [self setSortKeys:sortKeys ofFetchRequest:resultsController.fetchRequest];

    if ([resultsController performFetch:&error] == NO)
    {
        [self handleError:error];
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
                completion ? completion(error) : 0;
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (CallableData*)lookupCallableForE164:(NSString*)e164
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
    NSArray*     callables = [self fetchEntitiesWithName:@"Callable"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];
    
    return [callables firstObject];
}


- (PhoneData*)lookupPhoneForE164:(NSString*)e164
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
    NSArray*     phones    = [self fetchEntitiesWithName:@"Phone"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];

    return [phones firstObject];
}


- (NumberData*)lookupNumberForE164:(NSString*)e164
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
    NSArray*     numbers   = [self fetchEntitiesWithName:@"Number"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];

    return [numbers firstObject];
}


- (AddressData*)lookupAddressWithUuid:(NSString*)uuid
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    NSArray*     addresses = [self fetchEntitiesWithName:@"Address"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];

    return [addresses firstObject];
}


- (DestinationData*)lookupDestinationWithUuid:(NSString*)uuid
{
    NSPredicate* predicate    = [NSPredicate predicateWithFormat:@"uuid == %@", uuid];
    NSArray*     destinations = [self fetchEntitiesWithName:@"Destination"
                                                   sortKeys:@[@"name"]
                                                  predicate:predicate
                                       managedObjectContext:nil];

    return [destinations firstObject];
}


- (DestinationData*)lookupDestinationWithName:(NSString*)name
{
    NSPredicate* predicate    = [NSPredicate predicateWithFormat:@"name == %@", name];
    NSArray*     destinations = [self fetchEntitiesWithName:@"Destination"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];

    return [destinations firstObject];
}


#pragma mark - Helpers

- (void)handleError:(NSError*)error
{
    NBLog(@"CoreData error: %@.", error);

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
                                                @"Due to a problem, the internal database must be recreated.\n\n"
                                                @"Your call history and favorites will be lost. Sorry!",
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
                                                   @"Open app to reload numbers, destinations, and phones.",
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

        [Settings sharedSettings].needsServerSync = YES;

        abort();
    }
                         cancelButtonTitle:button
                         otherButtonTitles:nil];
}


#pragma mark - Server Refresh

- (void)synchronizeAll:(void (^)(NSError* error))completion
{
    if (isSynchronizing == YES)
    {
        completion ? completion(nil) : 0;

        return;
    }

    isSynchronizing = YES;

    [self saveManagedObjectContext:nil];

    [self synchronizeAddresses:^(NSError* error)
    {
        if (error == nil)
        {
            [self synchronizePhones:^(NSError* error)
            {
                if (error == nil)
                {
                    [self synchronizeDestinations:^(NSError* error)
                    {
                        if (error == nil)
                        {
                            [self synchronizeNumbers:^(NSError* error, NSArray* expiredNumbers)
                            {
                                if (error == nil)
                                {
                                    [self synchronizeRecordings:^(NSError* error)
                                    {
                                        if (error == nil)
                                        {
                                            [self synchronizeMessages:^(NSError* error)
                                            {
                                                if (error == nil)
                                                {
                                                    [self.managedObjectContext save:&error];
                                                    if (error == nil)
                                                    {
                                                        [self updateDefaultDestinations];
                                                         
                                                        [self saveManagedObjectContext:nil];
                                                         
                                                        dispatch_async(dispatch_get_main_queue(), ^
                                                        {
                                                            completion ? completion(nil) : 0;
                                                                            
                                                            isSynchronizing = NO;
                                                        });
                                                    }
                                                    else
                                                    {
                                                        [self handleError:error];
                                                         
                                                        isSynchronizing = NO;
                                                         
                                                        return;
                                                    }
                                                }
                                                else
                                                {
                                                    [self.managedObjectContext rollback];
                                                    completion ? completion(error) : 0;
                                                     
                                                    isSynchronizing = NO;
                                                }
                                            }];
                                        }
                                        else
                                        {
                                            [self.managedObjectContext rollback];
                                            completion ? completion(error) : 0;

                                            isSynchronizing = NO;
                                        }
                                    }];
                                }
                                else
                                {
                                    [self.managedObjectContext rollback];
                                    completion ? completion(error) : 0;

                                    isSynchronizing = NO;
                                }
                            }];
                        }
                        else
                        {
                            [self.managedObjectContext rollback];
                            completion ? completion(error) : 0;

                            isSynchronizing = NO;
                        }
                    }];
                }
                else
                {
                    [self.managedObjectContext rollback];
                    completion ? completion(error) : 0;

                    isSynchronizing = NO;
                }
            }];
        }
        else
        {
            [self.managedObjectContext rollback];
            completion ? completion(error) : 0;

            isSynchronizing = NO;
        }
    }];
}


- (void)synchronizeAddresses:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveAddressesForIsoCountryCode:nil
                                                        areaCode:nil
                                                      numberType:0
                                                 isExtranational:NO
                                                           reply:^(NSError* error, NSArray* addresses)
    {
        if (error == nil)
        {
            // Delete Addresses that are no longer on the server.
            NSArray*        uuids       = [addresses valueForKey:@"uuid"];
            NSFetchRequest* request     = [NSFetchRequest fetchRequestWithEntityName:@"Address"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*        deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object]; // This notifies AddressUpdatesHandler.
                }
            }
            else
            {
                [self handleError:error];
                
                return;
            }

            // Delete Address Updates that are no longer on server.
            NSMutableSet* complement = [NSMutableSet setWithArray:[[Settings sharedSettings].addressUpdates allKeys]];
            [complement minusSet:[NSSet setWithArray:uuids]];
            for (NSString* uuid in [complement allObjects])
            {
                [[AddressUpdatesHandler sharedHandler] removeAddressUpdateWithUuid:uuid];
            }

            if (addresses.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });

                return;
            }

            __block int loadImagesCount = 0;
            for (NSDictionary* dictionary in addresses)
            {
                BOOL            loadImages = NO;
                NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Address"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", dictionary[@"uuid"]]];

                AddressData* object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                if (error == nil)
                {
                    if (object == nil)
                    {
                        object = [NSEntityDescription insertNewObjectForEntityForName:@"Address"
                                                               inManagedObjectContext:self.managedObjectContext];
                    }

                    if (dictionary[@"addressProofMd5"] != nil && loadImages == NO)
                    {
                        loadImages = ![object.addressProofMd5  isEqualToString:dictionary[@"addressProofMd5"]] ||
                        object.addressProof == nil;
                    }

                    if (dictionary[@"identityProofMd5"] != nil && loadImages == NO)
                    {
                        loadImages = ![object.identityProofMd5 isEqualToString:dictionary[@"identityProofMd5"]] ||
                        object.identityProof == nil;
                    }
                }
                else
                {
                    [self handleError:error];

                    return;
                }

                object.uuid               = dictionary[@"uuid"];
                object.name               = dictionary[@"name"];
                object.salutation         = dictionary[@"salutation"];
                object.firstName          = dictionary[@"firstName"];
                object.lastName           = dictionary[@"lastName"];
                object.companyName        = dictionary[@"companyName"];
                object.companyDescription = dictionary[@"companyDescription"];
                object.street             = dictionary[@"street"];
                object.buildingNumber     = dictionary[@"buildingNumber"];
                object.buildingLetter     = dictionary[@"buildingLetter"];
                object.city               = dictionary[@"city"];
                object.postcode           = dictionary[@"postcode"];
                object.isoCountryCode     = dictionary[@"isoCountryCode"];
                object.areaCode           = dictionary[@"areaCode"];
                object.addressProofMd5    = dictionary[@"addressProofMd5"];
                object.identityProofMd5   = dictionary[@"identityProofMd5"];
                object.idType             = dictionary[@"idType"];
                object.idNumber           = dictionary[@"idNumber"];
                object.fiscalIdCode       = dictionary[@"fiscalIdCode"];
                object.streetCode         = dictionary[@"streetCode"];
                object.municipalityCode   = dictionary[@"municipalityCode"];
                object.rejectionReasons   = [AddressStatus rejectionReasonsMaskForArray:dictionary[@"rejectionReasons"]];
                if (object.addressStatus != [AddressStatus addressStatusMaskForString:dictionary[@"addressStatus"]])
                {
                    object.addressStatus  = [AddressStatus addressStatusMaskForString:dictionary[@"addressStatus"]];

                    [[AddressUpdatesHandler sharedHandler] processChangedAddress:object];
                }

                if (object.changedValues.count == 0)
                {
                    [object.managedObjectContext refreshObject:object mergeChanges:NO];
                }

                if (loadImages)
                {
                    loadImagesCount++;

                    [object loadProofImagesWithCompletion:^(NSError* error)
                    {
                        if (error == nil)
                        {
                            if (--loadImagesCount == 0)
                            {
                                dispatch_async(dispatch_get_main_queue(), ^
                                {
                                    completion ? completion(nil) : 0;
                                });
                            }
                        }
                        else
                        {
                            if (--loadImagesCount == 0)
                            {
                                completion ? completion(error) : 0;
                            }
                        }
                    }];
                }
            }

            if (loadImagesCount == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });
            }
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeNumbers:(void (^)(NSError* error, NSArray* expiredNumbers))completion
{
    NSMutableArray* expiredNumbers = [NSMutableArray array];

    [[WebClient sharedClient] retrieveNumbers:^(NSError* error, NSArray* numbers)
    {
        if (error == nil)
        {
            // Delete Numbers that are no longer on the server, except expired Numbers to allow
            // an alert to appear; these will be deleted when the user sees the alert.
            NSArray*         uuids       = [numbers valueForKey:@"uuid"];
            NSFetchRequest*  request     = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*         deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NumberData* number in deleteArray)
                {
                    if (![number hasExpired] || number.isPending)
                    {
                        [self.managedObjectContext deleteObject:number];
                    }
                    else
                    {
                        [expiredNumbers addObject:number];
                    }
                }
            }
            else
            {
                [self handleError:error];

                return;
            }

            if (numbers.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil, expiredNumbers) : 0;
                });

                return;
            }

            for (NSDictionary* dictionary in numbers)
            {
                NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", dictionary[@"uuid"]]];

                NumberData* object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                if (error == nil)
                {
                    if (object == nil)
                    {
                        object = [NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                                               inManagedObjectContext:self.managedObjectContext];
                        object.notifiedExpiryDays = INT16_MAX;  // Not notified yet.
                    }
                }
                else
                {
                    [self handleError:error];

                    return;
                }

                object.uuid           = dictionary[@"uuid"];
                object.name           = dictionary[@"name"];
                object.e164           = dictionary[@"e164"] ? [@"+" stringByAppendingString:dictionary[@"e164"]] : nil;
                object.numberType     = dictionary[@"numberType"];
                object.areaCode       = dictionary[@"areaCode"];
                object.areaId         = dictionary[@"areaId"];
                object.stateCode      = dictionary[@"stateCode"];
                object.stateName      = dictionary[@"stateName"];
                object.isoCountryCode = dictionary[@"isoCountryCode"];
                object.address        = [self lookupAddressWithUuid:dictionary[@"addressUuid"]]; // May return nil.
                object.addressType    = dictionary[@"addressType"];
                object.purchaseDate   = [Common dateWithString:dictionary[@"purchaseDateTime"]];
                object.expiryDate     = [Common dateWithString:dictionary[@"expiryDateTime"]];
                object.autoRenew      = [dictionary[@"autoRenew"] boolValue];
                object.destination    = [self lookupDestinationWithUuid:dictionary[@"destinationUuid"]];
                object.fixedRate      = [dictionary[@"fixedRate"] floatValue];
                object.fixedSetup     = [dictionary[@"fixedSetup"] floatValue];
                object.mobileRate     = [dictionary[@"mobileRate"] floatValue];
                object.mobileSetup    = [dictionary[@"mobileSetup"] floatValue];
                object.payphoneRate   = [dictionary[@"payphoneRate"] floatValue];
                object.payphoneSetup  = [dictionary[@"payphoneSetup"] floatValue];
                object.monthFee       = [dictionary[@"monthFee"] floatValue];
                object.renewFee       = [dictionary[@"renewFee"] floatValue];

                // For non-geograpic numbers, areaName is <null>.
                NSString* areaName = dictionary[@"areaName"];
                if ([areaName isEqual:[NSNull null]] || areaName.length == 0)
                {
                    object.areaName = nil;
                }
                else
                {
                    object.areaName = [Common capitalizedString:areaName];
                }

                if (object.changedValues.count == 0)
                {
                    [object.managedObjectContext refreshObject:object mergeChanges:NO];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion ? completion(nil, expiredNumbers) : 0;
            });
        }
        else
        {
            completion ? completion(error, nil) : 0;
        }
    }];
}


- (void)synchronizeDestinations:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveDestinations:^(NSError* error, NSArray* destinations)
    {
        if (error == nil)
        {
            // Delete Destinations that are no longer on the server.
            NSArray*        uuids       = [destinations valueForKey:@"uuid"];
            NSFetchRequest* request     = [NSFetchRequest fetchRequestWithEntityName:@"Destination"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*        deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object];
                }
            }
            else
            {
                [self handleError:error];

                return;
            }

            if (destinations.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });

                return;
            }

            for (NSDictionary* dictionary in destinations)
            {
                NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Destination"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", dictionary[@"uuid"]]];

                DestinationData* object;
                object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                if (error == nil)
                {
                    if (object == nil)
                    {
                        object = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                                    inManagedObjectContext:self.managedObjectContext];
                    }
                }
                else
                {
                    [self handleError:error];

                    return;
                }

                object.uuid = dictionary[@"uuid"];
                object.name = dictionary[@"name"];

                NSDictionary* action = dictionary[@"action"];
                action = [[WebClient sharedClient] restoreE164InAction:action];
                object.action = [Common jsonStringWithObject:action];

                if (object.changedValues.count == 0)
                {
                    [object.managedObjectContext refreshObject:object mergeChanges:NO];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion ? completion(nil) : 0;
            });
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeRecordings:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveAudios:^(NSError* error, NSArray* audios)
    {
        if (error == nil)
        {
            // Delete Recordings that are no longer on the server.
            NSArray*        uuids       = [audios valueForKey:@"uuid"];
            NSFetchRequest* request     = [NSFetchRequest fetchRequestWithEntityName:@"Recording"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*        deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object];
                }
            }
            else
            {
                [self handleError:error];

                return;
            }

            __block NSUInteger count = uuids.count;
            if (count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });

                return;
            }

            for (NSDictionary* dictionary in audios)
            {
                /*
                [[WebClient sharedClient] retrieveAudioForUuid:uuid
                                                         reply:^(NSError* error, NSString* name, NSData* data)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Recording"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        RecordingData* object;
                        object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (object == nil)
                            {
                                object = [NSEntityDescription insertNewObjectForEntityForName:@"Recording"
                                                                        inManagedObjectContext:self.managedObjectContext];
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        object = name;
                        //#### Save file on disk, or even better in the DB (like the proofImage): Change DB: remove URL
                        // object.urlString, and add NSData.
                 
                        if (object.changedValues.count == 0)
                        {
                            [object.managedObjectContext refreshObject:object mergeChanges:NO];
                        }
                    }
                    else
                    {
                        completion ? completion(error) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^
                        {
                            completion ? completion(nil) : 0;
                        });
                    }
                }];
                 *///### temp
            }

            //#### temp
            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion ? completion(nil) : 0;
            });

        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizePhones:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrievePhones:^(NSError* error, NSArray* phones)
    {
        if (error == nil)
        {
            // Delete Phones that are no longer on the server.
            NSArray* uuids = [phones valueForKey:@"uuid"];
            NSFetchRequest*  request     = [NSFetchRequest fetchRequestWithEntityName:@"Phone"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*         deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self checkDeletedPhone:(PhoneData*)object];
                    [self.managedObjectContext deleteObject:object];
                }
            }
            else
            {
                completion ? completion(error) : 0;

                return;
            }

            if (phones.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });

                return;
            }

            for (NSDictionary* dictionary in phones)
            {
                NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Phone"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", dictionary[@"uuid"]]];

                PhoneData* object;
                object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                if (error == nil)
                {
                    if (object == nil)
                    {
                        object = [NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                               inManagedObjectContext:self.managedObjectContext];
                    }
                }
                else
                {
                    [self handleError:error];

                    return;
                }

                object.uuid = dictionary[@"uuid"];
                object.e164 = dictionary[@"e164"] ? [@"+" stringByAppendingString:dictionary[@"e164"]] : nil;
                object.name = dictionary[@"name"];

                if (object.changedValues.count == 0)
                {
                    [object.managedObjectContext refreshObject:object mergeChanges:NO];
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion ? completion(nil) : 0;
            });
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeMessages:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveMessages:^(NSError* error, NSArray* messages)
    {
        if (error == nil)
        {
            // Delete Messages that are no longer on the server.
            NSArray* uuids = [messages valueForKey:@"uuid"];
            NSFetchRequest*  request     = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*         deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [self.managedObjectContext deleteObject:object];
                }
            }
            else
            {
                [self handleError:error];
                
                return;
            }
            
            if (messages.count == 0)
            {
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    completion ? completion(nil) : 0;
                });
                
                return;
            }
            
            for (NSDictionary* dictionary in messages)
            {
                NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Message"];
                [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", dictionary[@"uuid"]]];
                
                NSLog(@"%@", request);
                
                MessageData* object;
                object = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                if (error == nil)
                {
                    if (object == nil)
                    {
                        object = [NSEntityDescription insertNewObjectForEntityForName:@"Message"
                                                               inManagedObjectContext:self.managedObjectContext];
                    }
                }
                else
                {
                    [self handleError:error];
                    
                    return;
                }
                
                object.uuid = dictionary[@"uuid"];
                object.direction = @"IN";// [dictionary[@"direction"] isEqualToString:@"1"] ? @"OUT" : @"IN";
                object.extern_e164 = dictionary[@"extern_e164"];
                object.number_e164 = dictionary[@"number_e164"];
                object.text = dictionary[@"text"];
                //                 object.timestamp = @"TIME>>";// dictionary[@"timestamp"];
                object.timestamp = [[[NSCalendar alloc] initWithCalendarIdentifier: NSCalendarIdentifierGregorian] dateBySettingHour:10 minute:0 second:0 ofDate:[NSDate date] options:0];
                object.uuid = dictionary[@"uuid"];
                
                if (object.changedValues.count == 0)
                {
                    [object.managedObjectContext refreshObject:object mergeChanges:NO];
                }
            }
            
            dispatch_async(dispatch_get_main_queue(), ^
            {
                completion ? completion(nil) : 0;
            });
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)checkDeletedPhone:(PhoneData*)phone
{
    if ([phone.e164 isEqualToString:[Settings sharedSettings].callbackE164] ||
        [phone.e164 isEqualToString:[Settings sharedSettings].callerIdE164])
    {
        NSString* title;
        NSString* message;
        title   = NSLocalizedStringWithDefaultValue(@"PhonesView PhoneWasDeletedTitle", nil,
                                                    [NSBundle mainBundle],
                                                    @"Used Phone Deleted",
                                                    @"...\n"
                                                    @"[1 line larger font].");
        message = NSLocalizedStringWithDefaultValue(@"PhonesView PhoneWasDeletedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The Phone \"%@\" (%@), used as callback number and/or caller ID, "
                                                    @"was deleted from another iOS device, and is no longer available.\n\n"
                                                    @"To make calls, select another Phone on the Settings tab.",
                                                    @"....\n"
                                                    @"[multi-line small font].");
        message = [NSString stringWithFormat:message, phone.name, [[PhoneNumber alloc] initWithNumber:phone.e164].asYouTypeFormat];

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }

    if ([phone.e164 isEqualToString:[Settings sharedSettings].callbackE164])
    {
        [Settings sharedSettings].callbackE164 = nil;
    }

    if ([phone.e164 isEqualToString:[Settings sharedSettings].callerIdE164])
    {
        [Settings sharedSettings].callerIdE164 = nil;
    }
}


// We ignore errors in this method with the idea that if server access fails this time, it will succeed at some point
// in a next synchronisation.
- (void)updateDefaultDestinations
{
    // Delete default Destinations that no longer have a matching Phone.
    for (DestinationData* destination in [self fetchEntitiesWithName:@"Destination"])
    {
        if ([destination.name hasPrefix:@"+"] && [self lookupPhoneForE164:destination.name] == nil)
        {
            [destination deleteWithCompletion:nil];
        }
    }

    // Make sure all Phones have a default Destination.
    for (PhoneData* phone in [self fetchEntitiesWithName:@"Phone"])
    {
        if ([self lookupDestinationWithName:phone.e164] == nil)
        {
            DestinationData* destination = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                                         inManagedObjectContext:self.managedObjectContext];

            NSString* name = [NSString stringWithFormat:@"%@", phone.e164];
            [destination createForE164:phone.e164 name:name showCalledId:false completion:nil];
        }
    }
}

@end
