//
//  IdType.m
//  Talk
//
//  Created by Cornelis van der Bent on 21/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//
//###  TODO: Check entered data using regex:
//  https://www.oecd.org/tax/automatic-exchange/crs-implementation-and-assistance/tax-identification-numbers/SPAIN-TIN.pdf
//  DNI: NIF without closing letter?
//  NIF: /^[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKET]{1}$/i
//  NIE: /^[XYZ]{1}[0-9]{7}[TRWAGMYFPDXBNJZSQVHLCKET]{1}$/i
//  Passport: (between ? and) 9 characters A-Z0-9
//

#import "IdType.h"


@implementation IdType

- (instancetype)initWithString:(NSString*)string
{
    if (self = [super init])
    {
        if (string == nil)
        {
            _value = IdTypeValueNone;
        }

        if ([string isEqualToString:@"DNI"])
        {
            _value = IdTypeValueDni;
        }

        if ([string isEqualToString:@"NIF"])
        {
            _value = IdTypeValueNif;
        }

        if ([string isEqualToString:@"NIE"])
        {
            _value = IdTypeValueNie;
        }

        if ([string isEqualToString:@"PASSPORT"])
        {
            _value = IdTypeValuePassport;
        }
    }

    return self;
}


- (instancetype)initWithValue:(IdTypeValue)value
{
    if (self = [super init])
    {
        _value = value;
    }

    return self;
}


- (NSString*)string
{
    switch (self.value)
    {
        case IdTypeValueNone:
        {
            return nil;
        }
        case IdTypeValueDni:
        {
            return @"DNI";
        }
        case IdTypeValueNif:
        {
            return @"NIF";
        }
        case IdTypeValueNie:
        {
            return @"NIE";
        }
        case IdTypeValuePassport:
        {
            return @"PASSPORT";
        }
    }
}


- (NSString*)localizedString
{
    return [IdType localizedStringForValue:self.value];
}


+ (NSString*)localizedStringForValue:(IdTypeValue)value
{
    switch (value)
    {
        case IdTypeValueNone:
        {
            return @"";
        }
        case IdTypeValueDni:
        {
            return @"DNI";
        }
        case IdTypeValueNif:
        {
            return @"NIF";
        }
        case IdTypeValueNie:
        {
            return @"NIE";
        }
        case IdTypeValuePassport:
        {
            return NSLocalizedStringWithDefaultValue(@"ID Type Passport", nil, [NSBundle mainBundle],
                                                     @"Passport",
                                                     @"International travel document.\n"
                                                     @"[One line].");
        }
    }
}

@end
