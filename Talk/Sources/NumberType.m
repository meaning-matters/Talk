//
//  NumberType.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberType.h"

@implementation NumberType

+ (NSString*)numberTypeString:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Geographic", nil,
                                                     [NSBundle mainBundle], @"Geographic",
                                                     @"Standard term for geographic phone number (in a certain city)\n"
                                                     @"[iOS standard size].");

        case NumberTypeTollFreeMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings Toll-free", nil,
                                                     [NSBundle mainBundle], @"Toll-free",
                                                     @"Standard term for a free phone number (e.g. starting with 0800)\n"
                                                     @"[iOS standard size].");

        case NumberTypeNationalMask:
            return NSLocalizedStringWithDefaultValue(@"NumberType:Strings National", nil,
                                                     [NSBundle mainBundle], @"National",
                                                     @"Standard term for national phone number (not in a certain city)\n"
                                                     @"[iOS standard size].");
    }
}


+ (NSUInteger)numberTypeMaskToIndex:(NumberTypeMask)mask
{
    switch (mask)
    {
        case NumberTypeGeographicMask:
            return 0;

        case NumberTypeTollFreeMask:
            return 1;

        case NumberTypeNationalMask:
            return 2;
    }
}

@end
