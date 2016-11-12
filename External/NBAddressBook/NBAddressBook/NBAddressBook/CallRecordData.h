//
//  CallRecordData.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "NBContact.h"
#import "Call.h"    // Has its own/identical definition of CallDirection.

typedef enum
{
    CallStatusMissed    = 0,
    CallStatusFailed    = 1,
    CallStatusDeclined  = 2,
    CallStatusBusy      = 3,
    CallStatusCancelled = 4,
    CallStatusCallback  = 5,    // Only callback leg was connected.
    CallStatusSuccess   = 6,
} CallStatus;


@interface CallRecordData : NSManagedObject

// The number that was dailed
@property (nonatomic) NSString* dialedNumber;

// The contact (optional)
@property (nonatomic) NSString* contactID;

// Duration of the call.
@property (nonatomic) NSNumber* fromDuration;
@property (nonatomic) NSNumber* toDuration;

// Wether this was an incoming or outgoing call
@property (nonatomic) NSNumber* direction;

// The date for these calls
@property (nonatomic) NSDate*   date;

// The timezone for this call
@property (nonatomic) NSString* timeZone;

// The status of the call
@property (nonatomic) NSNumber* status;

// The international numbers
@property (nonatomic) NSString* fromE164;
@property (nonatomic) NSString* toE164;

// The callback UUID
@property (nonatomic) NSString* uuid;

// The calls cost.
@property (nonatomic) NSNumber* fromCost;
@property (nonatomic) NSNumber* toCost;

@end
