//
//  NumberType.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, NumberTypeMask)
{
    NumberTypeGeographicMask    = 1UL << 0,
    NumberTypeNationalMask      = 1UL << 1,
    NumberTypeTollFreeMask      = 1UL << 2,
    NumberTypeMobileMask        = 1UL << 3,
    NumberTypeSharedCostMask    = 1UL << 4,
    NumberTypeSpecialMask       = 1UL << 5,
    NumberTypeInternationalMask = 1UL << 6,
};


@interface NumberType : NSObject

+ (NSString*)stringForNumberType:(NumberTypeMask)mask;

+ (NumberTypeMask)numberTypeMaskForString:(NSString*)string;

+ (NSString*)localizedStringForNumberType:(NumberTypeMask)mask;

+ (NSString*)abbreviatedLocalizedStringForNumberType:(NumberTypeMask)mask;

+ (NSUInteger)numberTypeMaskToIndex:(NumberTypeMask)mask;

@end
