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
}

@end


@implementation PhoneNumber

static NSDictionary*    numberMetaData;
static NSDictionary*    countryCodesMap;
static NSString*        baseIsoCountryCode;

+ (void)initialize
{
    numberMetaData  = [Common objectWithJsonData:[Common dataForResource:@"NumberMetaData"  ofType:@"json"]];
    countryCodesMap = [Common objectWithJsonData:[Common dataForResource:@"CountryCodesMap" ofType:@"json"]];
}


- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
    }
    
    return self;
}


+ (void)setBaseIsoCountryCode:(NSString*)isoCountryCode
{
    
}

@end
