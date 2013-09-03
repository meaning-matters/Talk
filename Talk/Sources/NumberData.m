//
//  NumberData.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberData.h"

@implementation NumberData

@dynamic name;
@dynamic e164;
@dynamic numberType;
@dynamic areaCode;
@dynamic areaName;
@dynamic numberCountry;     // ISO country code.
@dynamic purchaseDate;
@dynamic renewalDate;

@dynamic salutation;
@dynamic firstName;
@dynamic lastName;
@dynamic company;
@dynamic street;
@dynamic building;
@dynamic city;
@dynamic zipCode;
@dynamic stateName;
@dynamic stateCode;
@dynamic addressCountry;    // ISO country code.
@dynamic proofImage;
@dynamic proofAccepted;

@dynamic forwarding;


- (void)setPurchaseDateWithString:(NSString*)dateString
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d H:m:s"];
    
    self.purchaseDate = [formatter dateFromString:dateString];
}


- (NSString*)stringPurchaseDateTime
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d H:m:s"];
    
    return [formatter stringFromDate:self.purchaseDate];
}


- (void)setRenewalDateWithString:(NSString*)dateString
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d H:m:s"];

    self.renewalDate = [formatter dateFromString:dateString];
}


- (NSString*)stringRenewalDateTime
{
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-M-d H:m:s"];

    return [formatter stringFromDate:self.renewalDate];
}

@end
