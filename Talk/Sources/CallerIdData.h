//
//  CallerIdData.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CallableData;

@interface CallerIdData : NSManagedObject

@property (nonatomic, retain) NSString*     contactId;
@property (nonatomic, retain) CallableData* callable;

@end
