//
//  AddressType.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressType.h"


@implementation AddressType

+ (NSString*)stringForAddressTypeMask:(AddressTypeMask)mask
{
    switch (mask)
    {
        case AddressTypeWorldwideMask:
        {
            return @"WORLDWIDE";
        }
        case AddressTypeNationalMask:
        {
            return @"NATIONAL";
        }
        case AddressTypeLocalMask:
        {
            return @"LOCAL";
        }
        case AddressTypeExtranational:
        {
            return @"EXTRANATIONAL";
        }
        default:
        {
            NBLog(@"Invalid AddressTypeMask.");
            return @"";
        }
    }
}


+ (NSString*)localizedStringForAddressTypeMask:(AddressTypeMask)mask
{
    switch (mask)
    {
        case AddressTypeWorldwideMask:
        {
            return NSLocalizedStringWithDefaultValue(@"AddressType Worldwide", nil, [NSBundle mainBundle],
                                                     @"Worldwide",
                                                     @"Terms used for an address that can be anywhere in the world");
        }
        case AddressTypeNationalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"AddressType National", nil, [NSBundle mainBundle],
                                                     @"National",
                                                     @"Terms used for an address that has to be in a certain country");
        }
        case AddressTypeLocalMask:
        {
            return NSLocalizedStringWithDefaultValue(@"AddressType Local", nil, [NSBundle mainBundle],
                                                     @"Local",
                                                     @"Terms used for an address that has to be in a certain city");
        }
        case AddressTypeExtranational:
        {
            return NSLocalizedStringWithDefaultValue(@"AddressType Extranational", nil, [NSBundle mainBundle],
                                                     @"Extranational",
                                                     @"Terms used for an address has to be outside a certain country"
                                                     @"(not so good, but shorter, alternative is 'Outside')");
        }
        default:
        {
            NBLog(@"Invalid AddressTypeMask.");
            return @"";
        }
    }
}


+ (AddressTypeMask)addressTypeMaskForString:(NSString*)string
{
    AddressTypeMask mask;
    
    if ([string isEqualToString:@"NONE"])
    {
        mask = AddressTypeWorldwideMask;
        NSLog(@"//### Remove NONE once server no longer sends it.");
    }
    else if ([string isEqualToString:@"WORLDWIDE"])
    {
        mask = AddressTypeWorldwideMask;
    }
    else if ([string isEqualToString:@"NATIONAL"])
    {
        mask = AddressTypeNationalMask;
    }
    else if ([string isEqualToString:@"LOCAL"])
    {
        mask = AddressTypeLocalMask;
    }
    else if ([string isEqualToString:@"EXTRANATIONAL"])
    {
        mask = AddressTypeExtranational;
    }
    else
    {
        mask = 0;   //### We should never get here.
    }
    
    return mask;
}

@end
