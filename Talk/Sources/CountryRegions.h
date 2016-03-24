//
//  CountryRegions.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

// The regions start at 0 and increment, allowing them to be used as index.
// Do not change that convention without also changing their use.
typedef NS_ENUM(NSUInteger, CountryRegion)
{
    CountryRegionAfrica   = 0,
    CountryRegionAmericas = 1,
    CountryRegionAsia     = 2,
    CountryRegionEurope   = 3,
    CountryRegionOceania  = 4,
    CountryRegionInvalid  = NSNotFound, // This is explicitly made equal to not-found.
};


@interface CountryRegions : NSObject

+ (CountryRegions*)sharedRegions;

- (CountryRegion)regionForIsoCountryCode:(NSString*)isoCountryCode;

- (NSString*)localizedStringForRegion:(CountryRegion)region;

- (NSString*)abbreviatedLocalizedStringForRegion:(CountryRegion)region;

- (NSArray*)isoCountryCodesForRegion:(CountryRegion)region;

@end
