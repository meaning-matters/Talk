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


@interface CountryNames ()

@property (nonatomic, strong) NSMutableDictionary* namesDictionary;

@end


@implementation CountryNames

#pragma mark - Singleton Stuff

+ (CountryNames*)sharedNames;
{
    static CountryNames*   sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[CountryNames alloc] init];

        // Make sure the locale matches the language of the app (see main.mm).
        NSDictionary* localeInfo = @{NSLocaleLanguageCode : [[NSLocale preferredLanguages] objectAtIndex:0]};
        NSLocale*     locale     = [[NSLocale alloc] initWithLocaleIdentifier:[NSLocale localeIdentifierFromComponents:localeInfo]];

        sharedInstance.namesDictionary = [NSMutableDictionary dictionary];
        for (NSString* countryCode in [NSLocale ISOCountryCodes])
        {
            NSString* identifier  = [NSLocale localeIdentifierFromComponents:[NSDictionary dictionaryWithObject:countryCode
                                                                                                         forKey:NSLocaleCountryCode]];
            NSString* countryName = [locale displayNameForKey:NSLocaleIdentifier value:identifier];
            [sharedInstance.namesDictionary setValue:countryName forKey:countryCode];
        }

        // Add countries not supported by iOS.
        NSString* countryName;
        countryName = NSLocalizedStringWithDefaultValue(@"Country:AC", nil, [NSBundle mainBundle], @"Ascension Island", @"AC");
        [sharedInstance.namesDictionary setValue:countryName forKey:@"AC"];
        countryName = NSLocalizedStringWithDefaultValue(@"Country:AN", nil, [NSBundle mainBundle], @"Netherlands Antilles", @"AN");
        [sharedInstance.namesDictionary setValue:countryName forKey:@"AN"];
    });
    
    return sharedInstance;
}


#pragma mark - Public API Methods

- (NSString*)nameForIsoCountryCode:(NSString*)isoCountryCode
{
    NSString* countryName = self.namesDictionary[[isoCountryCode uppercaseString]];

    if (countryName != nil)
    {
        return countryName;
    }
    else
    {
        NSLog(@"No country name available for code %@.", isoCountryCode);

        return nil;
    }
}


- (NSString*)isoCountryCodeForName:(NSString*)countryName
{
    NSArray*  keys = [self.namesDictionary allKeysForObject:countryName];

    if (keys.count != 0)
    {
        return keys[0];
    }
    else
    {
        NSLog(@"No country code available for name %@.", countryName);

        return nil;
    }
}

@end
