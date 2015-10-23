//
//  CoreDataManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DataManager : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext*       managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel*         managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator* persistentStoreCoordinator;

+ (DataManager*)sharedManager;

- (void)saveManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (void)removeAll;

- (NSArray*)fetchEntitiesWithName:(NSString*)entityName
                         sortKeys:(NSArray*)sortKeys
                        predicate:(NSPredicate*)predicate
             managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName
                                            withSortKeys:(NSArray*)keys
                                    managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (void)setSortKeys:(NSArray*)sortKeys ofResultsController:(NSFetchedResultsController*)resultsController;

- (void)synchronizeAll:(void (^)(NSError* error))completion;

// Same as synchronizeAll: but with alert when something went wrong.
- (void)synchronizeWithServer:(void (^)(NSError* error))completion;

@end
