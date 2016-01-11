//
//  RecordingData.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DestinationData;


@interface RecordingData : NSManagedObject

@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, retain) NSSet*    destinations;

@end


@interface RecordingData (CoreDataGeneratedAccessors)

- (void)addDestinationsObject:(DestinationData*)value;
- (void)removeDestinationsObject:(DestinationData*)value;
- (void)addDestinations:(NSSet*)values;
- (void)removeDestinations:(NSSet*)values;

@end
