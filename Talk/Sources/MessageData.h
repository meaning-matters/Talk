//
//  MessageData.h
//  Talk
//
//  Created by Jeroen Kooiker on 2/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MessageData : NSManagedObject

@property (nonatomic)         float     billed;
@property (nonatomic, retain) NSString* direction;
@property (nonatomic, retain) NSString* extern_e164;
@property (nonatomic, retain) NSString* number_e164;
@property (nonatomic, retain) NSString* text;
@property (nonatomic, retain) NSDate*   timestamp;
@property (nonatomic, retain) NSString* uuid;

@end
