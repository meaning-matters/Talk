//
//  AddressType.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AddressTypeMask)
{
    AddressTypeNoneMask      = 1UL << 0,
    AddressTypeWorldwideMask = 1UL << 1,
    AddressTypeNationalMask  = 1UL << 2,
    AddressTypeLocalMask     = 1UL << 3,
};


@interface AddressType : NSObject

+ (NSString*)stringForAddressTypeMask:(AddressTypeMask)mask;

+ (AddressTypeMask)addressTypeMaskForString:(NSString*)string;

@end
