//
//  CallableData.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CallerIdData;

@interface CallableData : NSManagedObject

@property (nonatomic, retain) NSString*     e164;
@property (nonatomic, retain) NSString*     name;
@property (nonatomic, retain) CallerIdData* callerId;

@end
