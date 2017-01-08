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


@interface DataManager ()
{
    NSURL* storeUrl;
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

    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Data2.2"
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
                              NSInferMappingModelAutomaticallyOption      : @YES};
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


- (AddressData*)lookupAddressWithId:(NSString*)addressId
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"addressId == %@", addressId];
    NSArray*     addresses = [self fetchEntitiesWithName:@"Address"
                                                sortKeys:@[@"name"]
                                               predicate:predicate
                                    managedObjectContext:nil];

    return [addresses firstObject];
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
    [self synchronizeAddresses:^(NSError *error)
    {
        if (error == nil)
        {
            [self synchronizePhones:^(NSError* error)
            {
                if (error == nil)
                {
                    [self synchronizeNumbers:^(NSError* error, NSArray* expiredNumbers)
                    {
                        if (error == nil)
                        {
                            [self synchronizeDestinations:^(NSError* error)
                            {
                                if (error == nil)
                                {
                                    [self synchronizeRecordings:^(NSError *error)
                                    {
                                        if (error == nil)
                                        {
                                            [self synchronizeNumberDestinations:expiredNumbers completion:^(NSError* error)
                                            {
                                                if (error == nil)
                                                {
                                                    [self.managedObjectContext save:&error];
                                                    if (error == nil)
                                                    {
                                                        [self updateDefaultDestinations];

                                                        [self saveManagedObjectContext:nil];

                                                        completion ? completion(nil) : 0;
                                                    }
                                                    else
                                                    {
                                                        [self handleError:error];

                                                        return;
                                                    }
                                                }
                                                else
                                                {
                                                    [self.managedObjectContext rollback];
                                                    completion ? completion(error) : 0;
                                                }
                                            }];
                                        }
                                        else
                                        {
                                            [self.managedObjectContext rollback];
                                            completion ? completion(error) : 0;
                                        }
                                    }];
                                }
                                else
                                {
                                    [self.managedObjectContext rollback];
                                    completion ? completion(error) : 0;
                                }
                            }];
                        }
                        else
                        {
                            [self.managedObjectContext rollback];
                            completion ? completion(error) : 0;
                        }
                    }];
                }
                else
                {
                    [self.managedObjectContext rollback];
                    completion ? completion(error) : 0;
                }
            }];
        }
        else
        {
            [self.managedObjectContext rollback];
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeAddresses:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveAddressesForIsoCountryCode:nil
                                                        areaCode:nil
                                                      numberType:0
                                                 isExtranational:NO
                                                           reply:^(NSError *error, NSArray *addressIds)
    {
        if (error == nil)
        {
            // Delete Addresses that are no longer on the server.
            NSFetchRequest* request     = [NSFetchRequest fetchRequestWithEntityName:@"Address"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (addressId IN %@)) OR (addressId == nil)", addressIds]];
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
            [complement minusSet:[NSSet setWithArray:addressIds]];
            for (NSString* addressId in [complement allObjects])
            {
                [[AddressUpdatesHandler sharedHandler] removeAddressUpdateWithId:addressId];
            }

            __block NSUInteger count = addressIds.count;
            if (count == 0)
            {
                completion ? completion(nil) : 0;
                
                return;
            }
            
            for (NSString* addressId in addressIds)
            {
                [[WebClient sharedClient] retrieveAddressWithId:addressId
                                                          reply:^(NSError*            error,
                                                                  NSString*           name,
                                                                  NSString*           salutation,
                                                                  NSString*           firstName,
                                                                  NSString*           lastName,
                                                                  NSString*           companyName,
                                                                  NSString*           companyDescription,
                                                                  NSString*           street,
                                                                  NSString*           buildingNumber,
                                                                  NSString*           buildingLetter,
                                                                  NSString*           city,
                                                                  NSString*           postcode,
                                                                  NSString*           isoCountryCode,
                                                                  NSString*           areaCode,
                                                                  BOOL                hasProof,
                                                                  NSString*           idType,
                                                                  NSString*           idNumber,
                                                                  NSString*           fiscalIdCode,
                                                                  NSString*           streetCode,
                                                                  NSString*           municipalityCode,
                                                                  AddressStatusMask   addressStatus,
                                                                  RejectionReasonMask rejectionReasons)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Address"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"addressId == %@", addressId]];

                        AddressData* address = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (address == nil)
                            {
                                address = [NSEntityDescription insertNewObjectForEntityForName:@"Address"
                                                                        inManagedObjectContext:self.managedObjectContext];
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        address.addressId          = addressId;
                        address.name               = name;
                        address.salutation         = salutation;
                        address.firstName          = firstName;
                        address.lastName           = lastName;
                        address.companyName        = companyName;
                        address.companyDescription = companyDescription;
                        address.street             = street;
                        address.buildingNumber     = buildingNumber;
                        address.buildingLetter     = buildingLetter;
                        address.city               = city;
                        address.postcode           = postcode;
                        address.isoCountryCode     = isoCountryCode;
                        address.areaCode           = areaCode;
                        address.hasProof           = hasProof;
                        address.idType             = idType;
                        address.idNumber           = idNumber;
                        address.fiscalIdCode       = fiscalIdCode;
                        address.streetCode         = streetCode;
                        address.municipalityCode   = municipalityCode;
                        address.addressStatus      = addressStatus;
                        address.rejectionReasons   = rejectionReasons;
                    }
                    else
                    {
                        completion ? completion(error) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        completion ? completion(nil) : 0;
                    }
                }];
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

    [[WebClient sharedClient] retrieveNumbersList:^(NSError* error, NSArray* uuids)
    {
        if (error == nil)
        {
            // Delete Numbers that are no longer on the server, except expired Numbers to allow
            // an alert to appear; these will be deleted when the user sees the alert.
            NSFetchRequest*  request     = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", uuids]];
            NSArray*         deleteArray = [self.managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NumberData* number in deleteArray)
                {
                    if (![number hasExpired] || [number isPending])
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

            __block NSUInteger count = uuids.count;
            if (count == 0)
            {
                completion ? completion(nil, expiredNumbers) : 0;

                return;
            }

            for (NSString* uuid in uuids)
            {
                [[WebClient sharedClient] retrieveNumberWithUuid:uuid
                                                           reply:^(NSError*        error,
                                                                   NSString*       e164,
                                                                   NSString*       name,
                                                                   NSString*       numberType,
                                                                   NSString*       areaCode,
                                                                   NSString*       areaName,
                                                                   NSString*       stateCode,
                                                                   NSString*       stateName,
                                                                   NSString*       isoCountryCode,
                                                                   NSString*       addressId,
                                                                   AddressTypeMask addressType,
                                                                   NSDictionary*   proofTypes,
                                                                   NSDate*         purchaseDate,
                                                                   NSDate*         expiryDate,
                                                                   BOOL            autoRenew,
                                                                   float           fixedRate,
                                                                   float           fixedSetup,
                                                                   float           mobileRate,
                                                                   float           mobileSetup,
                                                                   float           payphoneRate,
                                                                   float           payphoneSetup,
                                                                   float           monthFee,
                                                                   float           renewFee)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        NumberData* number = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (number == nil)
                            {
                                number = [NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                                                       inManagedObjectContext:self.managedObjectContext];
                                number.notifiedExpiryDays = INT16_MAX;  // Not notified yet.
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        number.uuid           = uuid;
                        number.name           = name;
                        number.e164           = e164;
                        number.numberType     = numberType;
                        number.areaCode       = areaCode;
                        number.stateCode      = stateCode;
                        number.stateName      = stateName;
                        number.isoCountryCode = isoCountryCode;
                        number.address        = [self lookupAddressWithId:addressId]; // May return nil.
                        number.addressType    = [AddressType stringForAddressTypeMask:addressType];
                        number.proofTypes     = proofTypes;
                        number.purchaseDate   = purchaseDate;
                        number.expiryDate     = expiryDate;
                        number.autoRenew      = autoRenew;
                        number.fixedRate      = fixedRate;
                        number.fixedSetup     = fixedSetup;
                        number.mobileRate     = mobileRate;
                        number.mobileSetup    = mobileSetup;
                        number.payphoneRate   = payphoneRate;
                        number.payphoneSetup  = payphoneSetup;
                        number.monthFee       = monthFee;
                        number.renewFee       = renewFee;

                        // For non-geograpic numbers, areaName is <null>.
                        if ([areaName isEqual:[NSNull null]] || areaName.length == 0)
                        {
                            number.areaName = nil;
                        }
                        else
                        {
                            number.areaName = [Common capitalizedString:areaName];
                        }
                    }
                    else
                    {
                        completion ? completion(error, nil) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        completion ? completion(nil, expiredNumbers) : 0;
                    }
                }];
            }
        }
        else
        {
            completion ? completion(error, nil) : 0;
        }
    }];
}


- (void)synchronizeDestinations:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveDestinationsList:^(NSError* error, NSArray* uuids)
    {
        if (error == nil)
        {
            // Delete Destinations that are no longer on the server.
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

            __block NSUInteger count = uuids.count;
            if (count == 0)
            {
                completion ? completion(nil) : 0;

                return;
            }

            for (NSString* uuid in uuids)
            {
                [[WebClient sharedClient] retrieveDestinationForUuid:uuid
                                                               reply:^(NSError* error, NSString* name, NSDictionary* action)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Destination"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        DestinationData* destination;
                        destination = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (destination == nil)
                            {
                                destination = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                                            inManagedObjectContext:self.managedObjectContext];
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        destination.uuid   = uuid;
                        destination.name   = name;
                        destination.action = [Common jsonStringWithObject:action];
                    }
                    else
                    {
                        completion ? completion(error) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        completion ? completion(nil) : 0;
                    }
                }];
            }
        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeRecordings:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrieveAudioList:^(NSError* error, NSArray* list)
    {
        if (error == nil)
        {
            // Delete Recordings that are no longer on the server.
            NSFetchRequest* request     = [NSFetchRequest fetchRequestWithEntityName:@"Recording"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"(NOT (uuid IN %@)) OR (uuid == nil)", list]];
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

            __block NSUInteger count = list.count;
            if (count == 0)
            {
                completion ? completion(nil) : 0;

                return;
            }

            for (NSString* uuid in list)
            {
                /*
                [[WebClient sharedClient] retrieveAudioForUuid:uuid
                                                         reply:^(NSError *error, NSString *name, NSData *data)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Recording"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        RecordingData* recording;
                        recording = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (recording == nil)
                            {
                                recording = [NSEntityDescription insertNewObjectForEntityForName:@"Recording"
                                                                          inManagedObjectContext:self.managedObjectContext];
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        recording.name = name;
                        //#### Save file on disk, or even better in the DB (like the proofImage): Change DB: remove URL
                        // recording.urlString, and add NSData.
                    }
                    else
                    {
                        completion ? completion(error) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        completion ? completion(nil) : 0;
                    }
                }];
                 *///### temp
            }
            completion ? completion(nil) : 0;//#### temp

        }
        else
        {
            completion ? completion(error) : 0;
        }
    }];
}


- (void)synchronizeNumberDestinations:(NSArray*)expiredNumbers completion:(void (^)(NSError* error))completion
{
    NSError*        error   = nil;
    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
    NSArray*        array   = [self.managedObjectContext executeFetchRequest:request error:&error];

    if (error != nil)
    {
        completion ? completion(error) : 0;

        return;
    }

    __block NSUInteger count = array.count;
    if (count == 0)
    {
        completion ? completion(nil) : 0;

        return;
    }

    for (NumberData* number in array)
    {
        // Skip expired Numbers, because they are no longer on the server. We're keeping them until
        // the user has seen an alert that they were actually expired.
        if ([expiredNumbers indexOfObject:number] != NSNotFound)
        {
            continue;
        }

        [[WebClient sharedClient] retrieveDestinationOfNumberWithUuid:number.uuid
                                                                reply:^(NSError* error, NSString* destinationUuid)
        {
            if (error == nil)
            {
                if (destinationUuid == nil)
                {
                    number.destination = nil;
                }
                else
                {
                    // Lookup the destination.
                    NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Destination"];
                    [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", destinationUuid]];

                    DestinationData* destination = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                    if (error == nil)
                    {
                        if (destination != nil)
                        {
                            number.destination = destination;
                        }
                    }
                    else
                    {
                        [self handleError:error];

                        return;
                    }
                }
            }
            else
            {
                completion ? completion(error) : 0;

                return;
            }

            if (--count == 0)
            {
                completion ? completion(nil) : 0;
            }
        }];
    }
}


- (void)synchronizePhones:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] retrievePhonesList:^(NSError* error, NSArray* uuids)
    {
        if (error == nil)
        {
            // Delete Phones that are no longer on the server.
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

            __block NSUInteger count = uuids.count;
            if (count == 0)
            {
                completion ? completion(nil) : 0;

                return;
            }

            for (NSString* uuid in uuids)
            {
                [[WebClient sharedClient] retrievePhoneWithUuid:uuid reply:^(NSError* error, NSString* e164, NSString* name)
                {
                    if (error == nil)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Phone"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        PhoneData* phone;
                        phone = [[self.managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (error == nil)
                        {
                            if (phone == nil)
                            {
                                phone = [NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                                      inManagedObjectContext:self.managedObjectContext];
                            }
                        }
                        else
                        {
                            [self handleError:error];

                            return;
                        }

                        phone.uuid = uuid;
                        phone.e164 = e164;
                        phone.name = name;
                    }
                    else
                    {
                        completion ? completion(error) : 0;

                        return;
                    }

                    if (--count == 0)
                    {
                        completion ? completion(nil) : 0;
                    }
                }];
            }
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
