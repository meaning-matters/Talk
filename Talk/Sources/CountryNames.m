//
//  CountryNames.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CountryNames.h"
#import "Common.h"


@implementation CountryNames

static CountryNames*    sharedNames;
static NSDictionary*    namesDictionary;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([CountryNames class] == self)
    {
        sharedNames = [self new];
        NSData* data = [Common dataForResource:@"CountryNames" ofType:@"json"];
        namesDictionary = [Common objectWithJsonData:data];
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

- (NSString*)nameForIcc:(NSString*)isoCountryCode
{
    return [namesDictionary objectForKey:[isoCountryCode uppercaseString]];
}

@end
