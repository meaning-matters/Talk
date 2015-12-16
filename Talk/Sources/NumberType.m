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
        case NumberTypeTollFreeMask:
        {
            return @"TOLL_FREE";
        }
        case NumberTypeMobileMask:
        {
            return @"MOBILE";
        }
        case NumberTypeSharedCostMask:
        {
            return @"SHARED_COST";
        }
        case NumberTypeSpecialMask:
        {
            return @"SPECIAL";
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
    else if ([string isEqualToString:@"TOLL_FREE"])
    {
        mask = NumberTypeTollFreeMask;
    }
    else if ([string isEqualToString:@"MOBILE"])
    {
        mask = NumberTypeMobileMask;
    }
    else if ([string isEqualToString:@"SHARED_COST"])
    {
        mask = NumberTypeSharedCostMask;
    }
    else if ([string isEqualToString:@"SPECIAL"])
    {
        mask = NumberTypeSpecialMask;
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
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Geographic", nil,
                                                     [NSBundle mainBundle], @"Geographic",
                                                     @"Standard term for geographic phone number (in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeNationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings National", nil,
                                                     [NSBundle mainBundle], @"National",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeTollFreeMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Toll-free", nil,
                                                     [NSBundle mainBundle], @"Toll-free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeMobileMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Mobile", nil,
                                                     [NSBundle mainBundle], @"Mobile",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeSharedCostMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Shared-cost", nil,
                                                     [NSBundle mainBundle], @"Shared-cost",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeSpecialMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Special", nil,
                                                     [NSBundle mainBundle], @"Special",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeInternationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings International", nil,
                                                     [NSBundle mainBundle], @"International",
                                                     @"Standard term for international phone number\n"
                                                     @"[iOS standard size].");
        }
    }
}


+ (NSString*)abbreviatedLocalizedStringForNumberTypeMask:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Geographic", nil,
                                                     [NSBundle mainBundle], @"Geo",
                                                     @"Standard term for geographic phone number (in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeNationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated National", nil,
                                                     [NSBundle mainBundle], @"Nat",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeTollFreeMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Toll-free", nil,
                                                     [NSBundle mainBundle], @"Free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeMobileMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Mobile", nil,
                                                     [NSBundle mainBundle], @"Mob",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeSharedCostMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Shared-cost", nil,
                                                     [NSBundle mainBundle], @"Share",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");
        }
        case NumberTypeSpecialMask:
        {
            return NSLocalizedStringWithDefaultValue(@"NumberType:StringsAbbreviated Special", nil,
                                                     [NSBundle mainBundle], @"Spec",
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
