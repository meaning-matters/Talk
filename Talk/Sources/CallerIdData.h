//
//  CallerIdData.h
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class E164Data;

@interface CallerIdData : NSManagedObject

@property (nonatomic, retain) NSString* contactId;
@property (nonatomic, retain) E164Data* e164;

@end
