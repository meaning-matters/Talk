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
    else
    {
        mask = 0;   //### We should never get here.
    }
    
    return mask;
}

@end
