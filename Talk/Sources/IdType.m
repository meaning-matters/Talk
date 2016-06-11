//
//  IdType.m
//  Talk
//
//  Created by Cornelis van der Bent on 21/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "IdType.h"

@implementation IdType

- (instancetype)initWithString:(NSString*)string
{
    if (self = [super init])
    {
        _value = [IdType valueForString:string];
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


#pragma mark - Properties

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
        case IdTypeValueFiscalIdCode:
        {
            return @"FISCAL_ID_CODE";
        }
        case IdTypeValuePassport:
        {
            return @"PASSPORT";
        }
        case IdTypeValueNationalIdCard:
        {
            return @"NATIONAL_ID_CARD";
        }
        case IdTypeValueBusinessRegistration:
        {
            return @"BUSINESS_REGISTRATION";
        }
    }
}


- (void)setString:(NSString *)string
{
    _value = [IdType valueForString:string];
}


- (NSString*)localizedString
{
    return [IdType localizedStringForValue:self.value];
}


- (NSString*)localizedRule
{
    return [IdType localizedRuleTextForValue:self.value];
}


+ (IdTypeValue)valueForString:(NSString*)string
{
    IdTypeValue value = IdTypeValueNone;

    if (string == nil)
    {
        value = IdTypeValueNone;
    }

    if ([string isEqualToString:@"DNI"])
    {
        value = IdTypeValueDni;
    }

    if ([string isEqualToString:@"NIF"])
    {
        value = IdTypeValueNif;
    }

    if ([string isEqualToString:@"NIE"])
    {
        value = IdTypeValueNie;
    }

    if ([string isEqualToString:@"FISCAL_ID_CODE"])
    {
        value = IdTypeValueFiscalIdCode;
    }

    if ([string isEqualToString:@"PASSPORT"])
    {
        value = IdTypeValuePassport;
    }

    if ([string isEqualToString:@"NATIONAL_ID_CARD"])
    {
        value = IdTypeValueNationalIdCard;
    }

    if ([string isEqualToString:@"BUSINESS_REGISTRATION"])
    {
        value = IdTypeValueBusinessRegistration;
    }

    return value;
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
        case IdTypeValueFiscalIdCode:
        {
            return NSLocalizedStringWithDefaultValue(@"Company Fiscal ID Code", nil, [NSBundle mainBundle],
                                                     @"Fiscal ID (NIF/CIF)",
                                                     @"...");
        }
        case IdTypeValuePassport:
        {
            return NSLocalizedStringWithDefaultValue(@"ID Type Passport", nil, [NSBundle mainBundle],
                                                     @"Passport",
                                                     @"International travel document.\n"
                                                     @"[One line].");
        }
        case IdTypeValueNationalIdCard:
        {
            return NSLocalizedStringWithDefaultValue(@"ID Type ...", nil, [NSBundle mainBundle],
                                                     @"National ID Card",
                                                     @"....\n"
                                                     @"[One line].");
        }
        case IdTypeValueBusinessRegistration:
        {
            return NSLocalizedStringWithDefaultValue(@"ID Type ...", nil, [NSBundle mainBundle],
                                                     @"Business Registration",
                                                     @"....\n"
                                                     @"[One line].");
        }
    }
}


+ (NSString*)localizedRuleTextForValue:(IdTypeValue)value
{
    switch (value)
    {
        case IdTypeValueNone:
        {
            return NSLocalizedStringWithDefaultValue(@"...", nil, [NSBundle mainBundle],
                                                     @"The ID type is unknown or not selected.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueDni:
        {
            return NSLocalizedStringWithDefaultValue(@"Spanish DNI number rule", nil, [NSBundle mainBundle],
                                                     @"Starting with 8 digits and ending with 1 letter except "
                                                     @"I, O or U.\n\nNo other characters or space.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueNif:
        {
            return NSLocalizedStringWithDefaultValue(@"Spanish NIF number rule", nil, [NSBundle mainBundle],
                                                     @"Starting with 8 digits and ending with 1 letter except "
                                                     @"I, O or U.\n\nNo other characters or space.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueNie:
        {
            return NSLocalizedStringWithDefaultValue(@"Spanish NIE number rule", nil, [NSBundle mainBundle],
                                                     @"Starting with X, Y or Z, followed by 7 digits, and ending with "
                                                     @"1 letter except I, O or U.\n\nNo other characters or space.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueFiscalIdCode:
        {
            return NSLocalizedStringWithDefaultValue(@"Spanish other company fiscal ID code rule", nil, [NSBundle mainBundle],
                                                     @"Starting with 0 or 1 letter, followed by 7 or 8 digits, "
                                                     @"and ending with 0 or 1 letter.\n\n"
                                                     @"No other characters or space.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValuePassport:
        {
            return NSLocalizedStringWithDefaultValue(@"Passport number rule", nil, [NSBundle mainBundle],
                                                     @"Between 7 and 9 digits and letters.\n\n"
                                                     @"No other characters or space.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueNationalIdCard:
        {
            return NSLocalizedStringWithDefaultValue(@"ID Card number rule", nil, [NSBundle mainBundle],
                                                     @"Preferably the 13-digit (0-9) South African identification "
                                                     @"number, or otherwise between 7 and 20 characters.",
                                                     @".\n"
                                                     @"....");
        }
        case IdTypeValueBusinessRegistration:
        {
            return NSLocalizedStringWithDefaultValue(@"South Aftican business number rule", nil, [NSBundle mainBundle],
                                                     @"Preferably the 12-digit South African company registration "
                                                     @"number (xxxx/xxxxxx/xx), or otherwise between 7 and 20 "
                                                     @"characters.",
                                                     @".\n"
                                                     @"....");
        }
    }
}


#pragma mark - Public API

- (BOOL)isValidWithIdString:(NSString*)idString
{
    NSString* regex;

    switch (self.value)
    {
        case IdTypeValueNone:                 regex = @"\\S+";                                          break;
        case IdTypeValueDni:                  regex = @"[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKET]{1}";         break;
        case IdTypeValueNif:                  regex = @"[0-9]{8}[TRWAGMYFPDXBNJZSQVHLCKET]{1}";         break;
        case IdTypeValueNie:                  regex = @"[XYZ]{1}[0-9]{7}[TRWAGMYFPDXBNJZSQVHLCKET]{1}"; break;
        case IdTypeValueFiscalIdCode:         regex = @"[A-Z]{0,1}[0-9]{7,8}[A-Z]{0,1}";                break;
        case IdTypeValuePassport:             regex = @"[A-Z0-9]{7,9}";                                 break;
        case IdTypeValueNationalIdCard:       regex = @".{7,20}";                                       break;
        case IdTypeValueBusinessRegistration: regex = @".{7,20}";                                       break;
    }

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];

    return [predicate evaluateWithObject:idString];
}

@end
