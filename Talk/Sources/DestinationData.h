//
//  DestinationData.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class NumberData, RecordingData, PhoneData;

@interface DestinationData : NSManagedObject

@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* action; // JSON formatted string.
@property (nonatomic, retain) NSSet*    numbers;
@property (nonatomic, retain) NSSet*    recordings;
@property (nonatomic, retain) NSSet*    phones;

- (void)deleteWithCompletion:(void (^)(BOOL succeeded))completion;

@end


@interface DestinationData (CoreDataGeneratedAccessors)

- (void)addNumbersObject:(NumberData*)value;
- (void)removeNumbersObject:(NumberData*)value;
- (void)addNumbers:(NSSet*)values;
- (void)removeNumbers:(NSSet*)values;

- (void)addRecordingsObject:(RecordingData*)value;
- (void)removeRecordingsObject:(RecordingData*)value;
- (void)addRecordings:(NSSet*)values;
- (void)removeRecordings:(NSSet*)values;

- (void)addPhonesObject:(PhoneData*)value;
- (void)removePhonesObject:(PhoneData*)value;
- (void)addPhones:(NSSet*)values;
- (void)removePhones:(NSSet*)values;

@end
