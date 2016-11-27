//
//  CallRecordData.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/20/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "CallRecordData.h"

@implementation CallRecordData

@dynamic contactId;
@dynamic dialedNumber;
@dynamic privacy;
@dynamic callerIdE164;
@dynamic fromDuration;
@dynamic toDuration;
@dynamic billableFromDuration;
@dynamic billableToDuration;
@dynamic direction;
@dynamic date;
@dynamic timeZone;
@dynamic status;
@dynamic fromE164;
@dynamic toE164;
@dynamic uuid;
@dynamic fromCost;
@dynamic toCost;
@dynamic isUpToDate;


/*
 Coming API #17 with frequency numbers.

 NORMAL_CLEARING        12851 - CallStatusSuccess
 <null>                  2268 - Probably old NumberBay system.
 ORIGINATOR_CANCEL       1395 - CallStatusCancelled
 USER_BUSY                458 - CallStatusBusy
 UNALLOCATED_NUMBER       356 -
 NO_USER_RESPONSE         287 -
 CALL_REJECTED            138 -
 NORMAL_UNSPECIFIED       132 -
 NORMAL_TEMPORARY_FAILURE 116 -
 INVALID_NUMBER_FORMAT    113 -
 RECOVERY_ON_TIMER_EXPIRE  97
 NONE                      54
 ALLOTTED_TIMEOUT          44
 NO_ROUTE_DESTINATION      40
 NO_ANSWER                 38
 UNKNOWN                   34
 DESTINATION_OUT_OF_ORDER  23
 INCOMPATIBLE_DESTINATION  15
 MANDATORY_IE_MISSING      13
 NETWORK_OUT_OF_ORDER      12
 MEDIA_TIMEOUT             12
 INTERWORKING               6
 EXCHANGE_ROUTING_ERROR     6
 SERVICE_UNAVAILABLE        5
 SERVICE_NOT_IMPLEMENTED    5
 LOSE_RACE                  5
 NORMAL_CIRCUIT_CONGESTION  3
 */

- (CallStatus)callStatusForString:(NSString*)string
{
    if ([string isEqual:[NSNull null]] || string.length == 0)  return @(CallStatusNull);
    if ([string isEqualToString:@"NORMAL_CLEARING"])           return @(CallStatusSuccess);
    if ([string isEqualToString:@"ORIGINATOR_CANCEL"])         return @(CallStatusCancelled);
    if ([string isEqualToString:@"USER_BUSY"])                 return @(CallStatusBusy);

    NSLog(@"Different call status: %@", string);
    if ([string isEqualToString:@"UNALLOCATED_NUMBER"])        return  @(8); //### IS @() needed??? or is this done by @dynamic???
    if ([string isEqualToString:@"NO_USER_RESPONSE"])          return  @(9);
    if ([string isEqualToString:@"CALL_REJECTED"])             return @(10);
    if ([string isEqualToString:@"NORMAL_UNSPECIFIED"])        return @(10);
    if ([string isEqualToString:@"NORMAL_TEMPORARY_FAILURE"])  return @(12);
    if ([string isEqualToString:@"INVALID_NUMBER_FORMAT"])     return @(13);
    if ([string isEqualToString:@"RECOVERY_ON_TIMER_EXPIRE"])  return @(14);
    if ([string isEqualToString:@"NONE"])                      return @(15);
    if ([string isEqualToString:@"ALLOTTED_TIMEOUT"])          return @(16);
    if ([string isEqualToString:@"NO_ROUTE_DESTINATION"])      return @(17);
    if ([string isEqualToString:@"NO_ANSWER"])                 return @(18);
    if ([string isEqualToString:@"UNKNOWN"])                   return @(19);
    if ([string isEqualToString:@"INCOMPATIBLE_DESTINATION"])  return @(20);
    if ([string isEqualToString:@"MANDATORY_IE_MISSING"])      return @(21);
    if ([string isEqualToString:@"NETWORK_OUT_OF_ORDER"])      return @(22);
    if ([string isEqualToString:@"MEDIA_TIMEOUT"])             return @(23);
    if ([string isEqualToString:@"INTERWORKING"])              return @(24);
    if ([string isEqualToString:@"EXCHANGE_ROUTING_ERROR"])    return @(25);
    if ([string isEqualToString:@"SERVICE_UNAVAILABLE"])       return @(26);
    if ([string isEqualToString:@"SERVICE_NOT_IMPLEMENTED"])   return @(27);
    if ([string isEqualToString:@"LOSE_RACE"])                 return @(28);
    if ([string isEqualToString:@"NORMAL_CIRCUIT_CONGESTION"]) return @(29);

    NSLog(@"Unknown call status: %@", string);
    return 30;
}

@end
