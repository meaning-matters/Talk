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

#define MATCH_STATUS(s) if ([@#s isEqualToString:

typedef enum
{
    CallStatusMissed    = 0,
    CallStatusFailed    = 1,
    CallStatusDeclined  = 2,
    CallStatusBusy      = 3,
    CallStatusCancelled = 4,
    CallStatusCallback  = 5,    // Only callback leg was connected.
    CallStatusSuccess   = 6,

    CallStatusNull      = 7,
} CallStatus;

@interface CallRecordData : NSManagedObject

// The number that was dailed.
@property (nonatomic) NSString* dialedNumber;

// Flag if caller ID was shown or not. Used for both incoming and outgoing calls.
@property (nonatomic) NSNumber* privacy;

@property (nonatomic) NSString* callerIdE164;

// The contact (optional).
@property (nonatomic) NSString* contactId;

// Durations of the call.
@property (nonatomic) NSNumber* fromDuration;
@property (nonatomic) NSNumber* toDuration;

// Billable durations of the call.
@property (nonatomic) NSNumber* billableFromDuration;
@property (nonatomic) NSNumber* billableToDuration;

// Whether this was an incoming, outgoing or verification call.
@property (nonatomic) NSNumber* direction;

// The date for these calls.
@property (nonatomic) NSDate*   date;

// The timezone for this call.
@property (nonatomic) NSString* timeZone;

// The status of the call (see CallStatus enum).
@property (nonatomic) NSNumber* status;

// The international numbers.
@property (nonatomic) NSString* fromE164;
@property (nonatomic) NSString* toE164;

// The call UUID.
@property (nonatomic) NSString* uuid;

// The calls cost.
@property (nonatomic) NSNumber* fromCost;
@property (nonatomic) NSNumber* toCost;

@property (nonatomic) NSNumber* isUpToDate;

@end
