//
//  NumberData.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberData.h"
#import "WebClient.h"

@implementation NumberData

@dynamic numberType;
@dynamic addressType;
@dynamic areaCode;
@dynamic areaName;
@dynamic isoCountryCode;
@dynamic purchaseDate;
@dynamic expiryDate;
@dynamic autoRenew;

@dynamic stateName;
@dynamic stateCode;
@dynamic proofTypes;

@dynamic fixedRate;
@dynamic fixedSetup;
@dynamic mobileRate;
@dynamic mobileSetup;
@dynamic payphoneRate;
@dynamic payphoneSetup;

@dynamic monthFee;
@dynamic renewFee;

@dynamic destination;
@dynamic address;


- (NSInteger)daysToSoonExpiry
{
    NSCalendar*       calendar   = [NSCalendar currentCalendar];
    NSDateComponents* components = [NSDateComponents new];  // Below adding to `day` also works around New Year.
    NSDate*           daysDate;

    components.day = 1;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 1;
    }

    components.day = 3;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 3;
    }

    components.day = 7;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 7;
    }

    return 0;
}

@end
