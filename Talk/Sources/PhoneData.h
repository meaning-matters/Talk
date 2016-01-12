//
//  PhoneData.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CallableData.h"

@class DestinationData;


@interface PhoneData : CallableData

@property (nonatomic, retain) NSSet* destinations;

- (NSString*)cantDeleteMessage;

- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion;

@end


@interface PhoneData (CoreDataGeneratedAccessors)

- (void)addDestinationsObject:(DestinationData*)value;
- (void)removeDestinationsObject:(DestinationData*)value;
- (void)addDestinations:(NSSet*)values;
- (void)removeDestinations:(NSSet*)values;

@end
