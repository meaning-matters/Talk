//
//  ForwardingData.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NumberData, RecordingData;

@interface ForwardingData : NSManagedObject

@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* statements; // JSON formatted string.
@property (nonatomic, retain) NSSet*    numbers;
@property (nonatomic, retain) NSSet*    recordings;

@end


@interface ForwardingData (CoreDataGeneratedAccessors)

- (void)addNumbersObject:(NumberData*)value;
- (void)removeNumbersObject:(NumberData*)value;
- (void)addNumbers:(NSSet*)values;
- (void)removeNumbers:(NSSet*)values;

- (void)addRecordingsObject:(RecordingData*)value;
- (void)removeRecordingsObject:(RecordingData*)value;
- (void)addRecordings:(NSSet*)values;
- (void)removeRecordings:(NSSet*)values;

- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion;

@end
