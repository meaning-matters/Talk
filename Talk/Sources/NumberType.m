//
//  NumberType.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberType.h"
#import "Common.h"


@implementation NumberType

+ (NSString*)stringForNumberTypeMask:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
        {
            return @"GEOGRAPHIC";
        }
        case NumberTypeNationalMask:
        {
            return @"NATIONAL";
        }
        case NumberTypeMobileMask:
        {
            return @"MOBILE";
        }
        case NumberTypeTollFreeMask:
        {
            return @"TOLL_FREE";
        }
        case NumberTypeInternationalMask:
        {
            return @"INTERNATIONAL";
        }
        default:
        {
            NBLog(@"Invalid NumberTypeMask.");
            return @"";
        }
    }
}


+ (NumberTypeMask)numberTypeMaskForString:(NSString*)string
{
    NumberTypeMask mask;
    
    if ([string isEqualToString:@"GEOGRAPHIC"])
    {
        mask = NumberTypeGeographicMask;
    }
    else if ([string isEqualToString:@"NATIONAL"])
    {
        mask = NumberTypeNationalMask;
    }
    else if ([string isEqualToString:@"MOBILE"])
    {
        mask = NumberTypeMobileMask;
    }
    else if ([string isEqualToString:@"TOLL_FREE"])
    {
        mask = NumberTypeTollFreeMask;
    }
    else if ([string isEqualToString:@"INTERNATIONAL"])
    {
        mask = NumberTypeInternationalMask;
    }
    else
    {
        mask = 0;   //### We should never get here.
    }

    return mask;
}


+ (NSString*)localizedStringForNumberTypeMask:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Local", nil, [NSBundle mainBundle],
                                                     @"Local",
                                                     @"Standard term for local phone number (in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeNationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings National", nil, [NSBundle mainBundle],
                                                     @"National",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeMobileMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Mobile", nil, [NSBundle mainBundle],
                                                     @"Mobile",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeTollFreeMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Toll-free", nil, [NSBundle mainBundle],
                                                     @"Toll-free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeInternationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings International", nil, [NSBundle mainBundle],
                                                     @"International",
                                                     @"Standard term for international phone number\n"
                                                     @"[iOS standard size].");
        }
        default:
        {
            return @"---";
        }
    }
}


+ (NSString*)abbreviatedLocalizedStringForNumberTypeMask:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Local", nil,
                                                     [NSBundle mainBundle], @"Local",
                                                     @"Standard term for local phone number (in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeNationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated National", nil,
                                                     [NSBundle mainBundle], @"National",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeMobileMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Mobile", nil,
                                                     [NSBundle mainBundle], @"Mobile",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeTollFreeMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Toll-free", nil,
                                                     [NSBundle mainBundle], @"Toll-free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeInternationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated International", nil,
                                                     [NSBundle mainBundle], @"Intl",
                                                     @"Standard term for international phone number\n"
                                                     @"[iOS standard size].");
        }
    }
}


+ (NSUInteger)numberTypeMaskToIndex:(NumberTypeMask)mask
{
    return [Common bitIndexOfMask:mask];
}

@end
