//
//  Tones.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Tones.h"
#import "Common.h"


@implementation Tones

static Tones*   sharedTones;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Tones class] == self)
    {
        sharedTones = [self new];
        NSData* data = [Common dataForResource:@"Tones" ofType:@"json"];
        sharedTones.tonesDictionary = [Common objectWithJsonData:data];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedTones && [Tones class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate Tones singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (Tones*)sharedTones;
{
    return sharedTones;
}


#pragma mark - Public API Methods

- (NSDictionary*)tonesForIsoCountryCode:(NSString*)isoCountryCode
{
    NSDictionary*   tones = self.tonesDictionary[[isoCountryCode uppercaseString]];

    if (tones == nil)
    {
        // The default.  But should not be selected, because there should be tones for
        // every supported country.
        NSLog(@"//### Default tones were selected.");
        tones = @{
                    @"ringing" :
                    @[
                        @{
                            @"frequency1" : @425,
                            @"frequency2" : @0,
                            @"on" : @1000,
                            @"off" : @4000,
                        }
                    ],
                    @"busy" :
                    @[
                        @{
                            @"frequency1" : @425,
                            @"frequency2" : @0,
                            @"on" : @1000,
                            @"off" : @1000,
                        }
                    ],
                    @"congestion" :
                    @[
                        @{
                            @"frequency1" : @425,
                            @"frequency2" : @0,
                            @"on" : @500,
                            @"off" : @500,
                        }
                    ]
                };
    }

    return tones;
}

@end
