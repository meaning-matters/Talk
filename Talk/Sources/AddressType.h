//
//  AddressType.h
//  Talk
//
//  Created by Cornelis van der Bent on 16/12/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Salutation.h"

typedef NS_ENUM(NSUInteger, AddressTypeMask)
{
    AddressTypeWorldwideMask = 1UL << 0,
    AddressTypeNationalMask  = 1UL << 1,
    AddressTypeLocalMask     = 1UL << 2,
    AddressTypeExtranational = 1UL << 3,
};


@interface AddressType : NSObject

+ (NSString*)stringForAddressTypeMask:(AddressTypeMask)mask;

+ (NSString*)localizedStringForAddressTypeMask:(AddressTypeMask)mask;

+ (AddressTypeMask)addressTypeMaskForString:(NSString*)string;

@end
