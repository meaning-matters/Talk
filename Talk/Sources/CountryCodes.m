//
//  CountryCodes.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CountryCodes.h"
#import "Common.h"


@implementation CountryCodes

static CountryCodes*    sharedCodes;
static NSDictionary*    codesDictionary;    // Maps MCC to ISO Country Code.


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([CountryCodes class] == self)
    {
        sharedCodes = [self new];
        NSData* data = [Common dataForResource:@"CountryCodes" ofType:@"json"];
        codesDictionary = [Common objectWithJsonData:data];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedCodes && [CountryCodes class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate CountryCodes singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (CountryCodes*)sharedCodes;
{
    return sharedCodes;
}


#pragma mark - Public API Methods

- (NSString*)mccForIcc:(NSString*)isoCountryCode
{
    return [[codesDictionary allKeysForObject:[isoCountryCode uppercaseString]] objectAtIndex:0];
}


- (NSString*)iccForMcc:(NSString*)mobileCountryCode
{
    return [codesDictionary objectForKey:mobileCountryCode];
}

@end
