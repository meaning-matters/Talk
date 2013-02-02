//
//  RingbackTones.m
//  Talk
//
//  Created by Cornelis van der Bent on 21/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "RingbackTones.h"
#import "Common.h"

#import "CountryNames.h"

@implementation RingbackTones

static RingbackTones*   sharedTones;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([RingbackTones class] == self)
    {
        sharedTones = [self new];
        NSData* data = [Common dataForResource:@"RingbackTones" ofType:@"json"];
        sharedTones.tonesDictionary = [Common objectWithJsonData:data];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedTones && [RingbackTones class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate RingbackTones singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (RingbackTones*)sharedTones;
{
    return sharedTones;
}


#pragma mark - Public API Methods

- (NSDictionary*)toneForIsoCountryCode:(NSString*)isoCountryCode
{
    NSDictionary*   tone = self.tonesDictionary[[isoCountryCode uppercaseString]];

    if (tone == nil)
    {
        tone = @{ @"name"       : @"Default",
                  @"frequency1" :  @425,
                  @"frequency1" :    @0,
                  @"on"         : @1000,
                  @"off"        : @4000,
                  @"count"      :    @1,
                  @"interval"   : @4000 };
    }

    return tone;
}


- (void)check
{
    // Print countries that have no tone.
    NSArray*    countries = [[CountryNames sharedNames].namesDictionary allKeys];
    NSArray*    tones = [self.tonesDictionary allKeys];

    NSLog(@"Countries without ringback tone:");
    int count = 0;
    for (NSString* country in countries)
    {
        if (self.tonesDictionary[country] == nil)
        {
            NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> %3d: %@ :  %@", ++count, country, [[CountryNames sharedNames] nameForIsoCountryCode:country]);
        }
    }

    NSLog(@"Ringback tones without country:");
    count = 0;
    for (NSString* tone in tones)
    {
        if ([CountryNames sharedNames].namesDictionary[tone] == nil)
        {
            NSLog(@"++++++++++++++++++++++++++++++++ %3d: %@", ++count, tone);
        }
    }

}

@end
