//
//  CountryNames.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  The following countries were deleted (including their flags) because there's
//  no country calling code available in LibPhoneNumber: PN TF UM AQ EH BV HM GS.


#import "CountryNames.h"
#import "Common.h"


@implementation CountryNames

static CountryNames*    sharedNames;


#pragma mark - Singleton Stuff

@synthesize namesDictionary = _namesDictionary;


+ (void)initialize
{
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
    return [self.namesDictionary objectForKey:[isoCountryCode uppercaseString]];
}


- (NSString*)isoCountryCodeForName:(NSString*)name
{
    return [[self.namesDictionary allKeysForObject:name] objectAtIndex:0];
}

@end
