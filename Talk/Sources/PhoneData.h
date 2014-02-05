//
//  PhoneData.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class ForwardingData;

@interface PhoneData : NSManagedObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* e164;
@property (nonatomic, retain) NSSet*    forwardings;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion;

@end


@interface PhoneData (CoreDataGeneratedAccessors)

- (void)addForwardingsObject:(ForwardingData *)value;
- (void)removeForwardingsObject:(ForwardingData *)value;
- (void)addForwardings:(NSSet *)values;
- (void)removeForwardings:(NSSet *)values;

@end
