//
//  RecordingData.h
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ForwardingData;

@interface RecordingData : NSManagedObject

@property (nonatomic, retain) NSString* hashString;
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* urlString;
@property (nonatomic, retain) NSSet*    forwardings;

@end

@interface RecordingData (CoreDataGeneratedAccessors)

- (void)addForwardingsObject:(ForwardingData*)value;
- (void)removeForwardingsObject:(ForwardingData*)value;
- (void)addForwardings:(NSSet*)values;
- (void)removeForwardings:(NSSet*)values;

@end
