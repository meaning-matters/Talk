//
//  NumberType.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberType.h"

@implementation NumberType

+ (NSString*)stringForNumberType:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
            return @"GEOGRAPHIC";

        case NumberTypeNationalMask:
            return @"NATIONAL";

        case NumberTypeTollFreeMask:
            return @"TOLLFREE";

        case NumberTypeInternationalMask:
            return @"INTERNATIONAL";

        default:
            NSLog(@"Invalid NumberTypeMask.");
            return @"";
    }
}


+ (NumberTypeMask)numberTypeForString:(NSString*)string
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
    else if ([string isEqualToString:@"TOLLFREE"])
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


+ (NSString*)localizedStringForNumberType:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Geographic", nil,
                                                     [NSBundle mainBundle], @"Geographic",
                                                     @"Standard term for geographic phone number (in a certain city)\n"
                                                     @"[iOS standard size].");

        case NumberTypeNationalMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings National", nil,
                                                     [NSBundle mainBundle], @"National",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");

        case NumberTypeTollFreeMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Toll-free", nil,
                                                     [NSBundle mainBundle], @"Toll-free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");

        case NumberTypeInternationalMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings International", nil,
                                                     [NSBundle mainBundle], @"International",
                                                     @"Standard term for international phone number\n"
                                                     @"[iOS standard size].");
    }
}


+ (NSUInteger)numberTypeMaskToIndex:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
            return 0;

        case NumberTypeNationalMask:
            return 1;

        case NumberTypeTollFreeMask:
            return 2;

        case NumberTypeInternationalMask:
            return 3;
    }
}

@end
