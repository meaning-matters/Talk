//
//  CountryNames.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  The following countries were deleted (including their flags) because there's
//  no country calling code available in LibPhoneNumber: PN TF UM AQ EH BV HM GS.
//
//  For localization look here: http://en.wikipedia.org/wiki/List_of_country_names_in_various_languages
//  and/or here: http://cldr.unicode.org

#import "CountryNames.h"
#import "Common.h"


@implementation CountryNames

static CountryNames*    sharedNames;


#pragma mark - Singleton Stuff

+ (void)initialize
{
#warning Implement/Replace this class using:  (but need to sort out locales first: We don't want countries to be in other locale than app texts.
    NSMutableArray *countries = [NSMutableArray arrayWithCapacity: [[NSLocale ISOCountryCodes] count]];
    for (NSString *countryCode in [NSLocale ISOCountryCodes])
    {
        NSString *identifier = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode
                                                                                                    forKey:NSLocaleCountryCode]];
        NSString *country = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:identifier];
        [countries addObject:country];
    }

    if ([CountryNames class] == self)
    {
        sharedNames = [self new];
        NSData* data = [Common dataForResource:@"CountryNames" ofType:@"json"];
        sharedNames.namesDictionary = [Common objectWithJsonData:data];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedNames && [CountryNames class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate CountryNames singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (CountryNames*)sharedNames;
{
    return sharedNames;
}


#pragma mark - Public API Methods

- (NSString*)nameForIsoCountryCode:(NSString*)isoCountryCode
{
    return self.namesDictionary[[isoCountryCode uppercaseString]];
}


- (NSString*)isoCountryCodeForName:(NSString*)name
{
    return [self.namesDictionary allKeysForObject:name][0];
}

@end
