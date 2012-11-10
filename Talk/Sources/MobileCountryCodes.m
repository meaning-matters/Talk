//
//  MobileCountryCodes.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "MobileCountryCodes.h"
#import "Common.h"


@implementation MobileCountryCodes

static MobileCountryCodes*  sharedCodes;
static NSDictionary*        codesDictionary;    // Maps MCC to ISO Country Code.


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([MobileCountryCodes class] == self)
    {
        sharedCodes = [self new];
        NSData* data = [Common dataForResource:@"MobileCountryCodes" ofType:@"json"];
        codesDictionary = [Common objectWithJsonData:data];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedCodes && [MobileCountryCodes class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate MobileCountryCodes singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (MobileCountryCodes*)sharedCodes;
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
