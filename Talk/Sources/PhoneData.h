//
//  PhoneData.h
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface PhoneData : NSManagedObject

@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* e164;

@end
