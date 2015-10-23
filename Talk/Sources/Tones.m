//
//  Tones.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "Tones.h"
#import "Common.h"


@implementation Tones

#pragma mark - Singleton Stuff

+ (Tones*)sharedTones;
{
    static Tones*           sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Tones alloc] init];

        NSData* data = [Common dataForResource:@"Tones" ofType:@"json"];
        sharedInstance.tonesDictionary = [Common objectWithJsonData:data];
    });

    return sharedInstance;
}


#pragma mark - Public API Methods

- (NSDictionary*)tonesForIsoCountryCode:(NSString*)isoCountryCode
{
    NSDictionary*   tones = self.tonesDictionary[[isoCountryCode uppercaseString]];

    if (tones == nil)
    {
        // The default.  But should not be selected, because there should be tones for
        // every supported country.
        NBLog(@"//### Default tones were selected.");
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
