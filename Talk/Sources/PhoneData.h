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

@class ForwardingData;


@interface PhoneData : CallableData

@property (nonatomic, retain) NSSet* forwardings;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion;

@end


@interface PhoneData (CoreDataGeneratedAccessors)

- (void)addForwardingsObject:(ForwardingData*)value;
- (void)removeForwardingsObject:(ForwardingData*)value;
- (void)addForwardings:(NSSet*)values;
- (void)removeForwardings:(NSSet*)values;

@end
