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
    NumberTypeMobileMask        = 1UL << 2,
    NumberTypeTollFreeMask      = 1UL << 3,
    NumberTypeInternationalMask = 1UL << 4,
};


@interface NumberType : NSObject

+ (NSString*)stringForNumberTypeMask:(NumberTypeMask)mask;

+ (NumberTypeMask)numberTypeMaskForString:(NSString*)string;

+ (NSString*)localizedStringForNumberTypeMask:(NumberTypeMask)mask;

+ (NSString*)abbreviatedLocalizedStringForNumberTypeMask:(NumberTypeMask)mask;

+ (NSUInteger)numberTypeMaskToIndex:(NumberTypeMask)mask;

@end
