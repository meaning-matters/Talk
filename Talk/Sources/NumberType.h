//
//  NumberType.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
    NumberTypeGeographicMask = 1UL << 0,
    NumberTypeTollFreeMask   = 1UL << 1,
    NumberTypeNationalMask   = 1UL << 2,
} NumberTypeMask;


@interface NumberType : NSObject

+ (NSString*)numberTypeString:(NumberTypeMask)mask;

@end
