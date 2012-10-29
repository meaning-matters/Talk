//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumber.h"
#import "Common.h"

@interface PhoneNumber ()
{
    NSDictionary*   metaData;
    NSDictionary*   countryCodeMap;
}

@end


@implementation PhoneNumber

- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {        
        metaData       = [Common objectWithJsonData:[Common dataForResource:@"PhoneNumberMetaData" ofType:@"json"]];
        countryCodeMap = [Common objectWithJsonData:[Common dataForResource:@"CountryCodeMap"      ofType:@"json"]];
    }
    
    return self;
}

@end
