//
//  MessageData.h
//  Talk
//
//  Created by Jeroen Kooiker on 2/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MessageDirection.h"

@interface MessageData : NSManagedObject

@property (nonatomic)         float                billed;
@property (nonatomic, retain) NSNumber*            direction;
@property (nonatomic, retain) NSString*            externE164;
@property (nonatomic, retain) NSString*            numberE164;
@property (nonatomic, retain) NSString*            text;
@property (nonatomic, retain) NSDate*              timestamp;
@property (nonatomic, retain) NSString*            uuid;
@property (nonatomic, retain) NSString*            contactId;

- (MessageDirectionEnum)directionRaw;
- (void)setDirectionRaw:(MessageDirectionEnum)direction;

@end
