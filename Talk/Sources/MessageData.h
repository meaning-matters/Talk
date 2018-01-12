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

@property (nonatomic, assign) float     cost;
@property (nonatomic, assign) int16_t   direction;
@property (nonatomic, retain) NSString* externE164;
@property (nonatomic, retain) NSString* numberE164;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) NSDate*   timestamp;
@property (nonatomic, retain) NSString* uuid;
@property (nonatomic, retain) NSString* contactId;

- (void)createForNumberE164:(NSString*)numberE164
                 externE164:(NSString*)externE164
                       text:(NSString*)text
                   datetime:(NSDate*)datetime
                 completion:(void (^)(NSError* error))completion;

@end
