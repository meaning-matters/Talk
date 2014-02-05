//
//  CoreDataManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DataManager : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext*         managedObjectContext;
@property (nonatomic, strong, readonly) NSManagedObjectModel*           managedObjectModel;
@property (nonatomic, strong, readonly) NSPersistentStoreCoordinator*   persistentStoreCoordinator;

+ (DataManager*)sharedManager;

- (void)saveContext;

- (void)removeAll;

- (NSArray*)fetchEntitiesWithName:(NSString*)entityName
                         sortKeys:(NSArray*)sortKeys
                        predicate:(NSPredicate*)predicate
                            error:(NSError**)error;

- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName
                                            withSortKeys:(NSArray*)keys
                                                   error:(NSError**)error;

- (BOOL)setSortKeys:(NSArray*)sortKeys
ofResultsController:(NSFetchedResultsController*)resultsController
              error:(NSError**)error;

- (void)synchronizeWithServer:(void (^)(NSError* error))completion;

- (void)synchronizePhones:(void (^)(NSError* error))completion;

- (void)handleError;

@end
