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

#pragma mark - Singleton Stuff

+ (RingbackTones*)sharedTones;
{
    static RingbackTones*   sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[RingbackTones alloc] init];

        NSData* data = [Common dataForResource:@"RingbackTones" ofType:@"json"];
        sharedInstance.tonesDictionary = [Common objectWithJsonData:data];
    });

    return sharedInstance;
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

    NBLog(@"Countries without ringback tone:");
    int count = 0;
    for (NSString* country in countries)
    {
        if (self.tonesDictionary[country] == nil)
        {
            NBLog(@">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> %3d: %@ :  %@", ++count, country, [[CountryNames sharedNames] nameForIsoCountryCode:country]);
        }
    }

    NBLog(@"Ringback tones without country:");
    count = 0;
    for (NSString* tone in tones)
    {
        if ([CountryNames sharedNames].namesDictionary[tone] == nil)
        {
            NBLog(@"++++++++++++++++++++++++++++++++ %3d: %@", ++count, tone);
        }
    }

}

@end
