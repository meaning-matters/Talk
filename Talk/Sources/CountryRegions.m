//
//  CountryRegions.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "CountryRegions.h"
#import "Common.h"


@interface CountryRegions ()

@property (nonatomic, strong) NSDictionary* regions;

@end


@implementation CountryRegions

+ (CountryRegions*)sharedRegions
{
    static CountryRegions* sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[CountryRegions alloc] init];

        NSData* data           = [Common dataForResource:@"CountryRegions" ofType:@"json"];
        sharedInstance.regions = [Common objectWithJsonData:data];
    });

    return sharedInstance;
}


- (CountryRegion)regionForIsoCountryCode:(NSString*)isoCountryCode
{
    CountryRegion region = CountryRegionInvalid;

    for (NSString* regionName in self.regions)
    {
        NSArray* countries = self.regions[regionName];

        if ([countries containsObject:isoCountryCode])
        {
            region = [self regionForName:regionName];
            break;
        }
    }

    return region;
}


- (CountryRegion)regionForName:(NSString*)regionName
{
    NSArray* regionNames = @[@"Africa", @"Americas", @"Asia", @"Europe", @"Oceania"];

    return [regionNames indexOfObject:regionName]; // May return NSNotFound == CountryRegionInvalid.
}


- (NSString*)localizedStringForRegion:(CountryRegion)region
{
    NSString* regionName;

    switch (region)
    {
        case CountryRegionAfrica:
        {
            regionName = NSLocalizedStringWithDefaultValue(@"CountryRegions Africa", nil, [NSBundle mainBundle],
                                                           @"Africa",
                                                           @"World region name");
            break;
        }
        case CountryRegionAmericas:
        {
            regionName = NSLocalizedStringWithDefaultValue(@"CountryRegions Americas", nil, [NSBundle mainBundle],
                                                           @"Americas",
                                                           @"World region name");
            break;
        }
        case CountryRegionAsia:
        {
            regionName = NSLocalizedStringWithDefaultValue(@"CountryRegions Asia", nil, [NSBundle mainBundle],
                                                           @"Asia",
                                                           @"World region name");
            break;
        }
        case CountryRegionEurope:
        {
            regionName = NSLocalizedStringWithDefaultValue(@"CountryRegions Europe", nil, [NSBundle mainBundle],
                                                           @"Europe",
                                                           @"World region name");
            break;
        }
        case CountryRegionOceania:
        {
            regionName = NSLocalizedStringWithDefaultValue(@"CountryRegions Oceania", nil, [NSBundle mainBundle],
                                                           @"Oceania",
                                                           @"World region name");
            break;
        }
        default:
        {
            regionName = @"---";
        }
    }

    return regionName;
}


- (NSString*)abbreviatedLocalizedStringForRegion:(CountryRegion)region
{
    NSString* abbreviation;

    switch (region)
    {
        case CountryRegionAfrica:
        {
            abbreviation = NSLocalizedStringWithDefaultValue(@"CountryRegions AfricaAbbreviated", nil, [NSBundle mainBundle],
                                                             @"Afric",
                                                             @"Few character abbreviation of world region");
            break;
        }
        case CountryRegionAmericas:
        {
            abbreviation = NSLocalizedStringWithDefaultValue(@"CountryRegions AmericasAbbreviated", nil, [NSBundle mainBundle],
                                                             @"Americ",
                                                             @"Few character abbreviation of world region");
            break;
        }
        case CountryRegionAsia:
        {
            abbreviation = NSLocalizedStringWithDefaultValue(@"CountryRegions AsiaAbbreviated", nil, [NSBundle mainBundle],
                                                             @"Asia",
                                                             @"Few character abbreviation of world region");
            break;
        }
        case CountryRegionEurope:
        {
            abbreviation = NSLocalizedStringWithDefaultValue(@"CountryRegions EuropeAbbreviated", nil, [NSBundle mainBundle],
                                                             @"Europ",
                                                             @"Few character abbreviation of world region");
            break;
        }
        case CountryRegionOceania:
        {
            abbreviation = NSLocalizedStringWithDefaultValue(@"CountryRegions OceaniaAbbreviated", nil, [NSBundle mainBundle],
                                                             @"Ocean",
                                                             @"Few character abbreviation of world region");
            break;
        }
        default:
        {
            abbreviation = @"---";
        }
    }

    return abbreviation;
}


- (NSArray*)isoCountryCodesForRegion:(CountryRegion)region
{
    for (NSString* regionName in self.regions)
    {
        if ([self regionForName:regionName] == region)
        {
            return self.regions[regionName];
        }
    }

    return nil;
}

@end


