//
//  CoreDataManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "DataManager.h"
#import "Common.h"

@implementation DataManager

static DataManager* sharedManager;

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([DataManager class] == self)
    {
        sharedManager = [self new];

        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            [sharedManager saveContext];
        }];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedManager && [DataManager class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate CoreDataManager singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (DataManager*)sharedManager
{
    return sharedManager;
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
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
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

    NSURL*      storeURL = [Common documentPath:@"Data.sqlite"];
    NSError*    error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:self.managedObjectModel];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
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
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]

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

@end
