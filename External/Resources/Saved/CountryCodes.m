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
static NSDictionary*    codesArray;    // Maps MCC to ISO Country Code.


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([CountryCodes class] == self)
    {
        sharedCodes = [self new];
        NSData* data = [Common dataForResource:@"CountryCodes" ofType:@"json"];
        codesArray = [Common objectWithJsonData:data];


        [sharedCodes check];
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

- (NSString*)mobileForIsoCountryCode:(NSString*)isoCountryCode
{
    NSString*   mcc = nil;

    for (NSDictionary* item in codesArray)
    {
        if ([[item objectForKey:@"iso"] isEqualToString:isoCountryCode])
        {
            mcc = [item objectForKey:@"mcc"];
            break;
        }
    }
    
    return mcc;
}


- (NSString*)isoForMobileCountryCode:(NSString*)mobileCountryCode
                   mobileNetworkCode:(NSString*)mobileNetworkCode
{
    NSString*   iso = nil;

    for (NSDictionary* item in codesArray)
    {
        if ([[item objectForKey:@"mcc"] isEqualToString:mobileCountryCode] &&
            [[item objectForKey:@"mnc"] isEqualToString:mobileNetworkCode])
        {
            iso = [item objectForKey:@"iso"];
            break;
        }
    }

    return iso;
}


- (void)check
{
    NSDictionary*   mapDictionary;
    NSData* data = [Common dataForResource:@"CountryCodesMap" ofType:@"json"];
    mapDictionary = [Common objectWithJsonData:data];

    for (NSDictionary* item in codesArray)
    {
        BOOL        found = NO;
        NSString*   isoA = [item objectForKey:@"iso"];
        for (NSArray* array in [mapDictionary allValues])
        {
            for (NSString* isoB in array)
            {
                if ([isoA isEqualToString:isoB])
                {
                    found = YES;
                    break;
                }
            }
        }

        if (found == NO)
        {
            NSLog(@"A: %@", isoA);
        }
    }

    for (NSArray* array in [mapDictionary allValues])
    {
        for (NSString* isoB in array)
        {
            BOOL    found = NO;
            for (NSDictionary* item in codesArray)
            {
                NSString*   isoA = [item objectForKey:@"iso"];
                
                if ([isoA isEqualToString:isoB])
                {
                    found = YES;
                    break;
                }
            }

            if (found == NO)
            {
                NSLog(@"B: %@", isoB);
            }
        }
    }
}

@end
