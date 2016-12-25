//
//  IdType.h
//  Talk
//
//  Created by Cornelis van der Bent on 21/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, IdTypeValue)
{
    IdTypeValueNone                   = 0, // No ID type present.
    IdTypeValueDni                    = 1, // Documento Nacional de Identidad: ES.
    IdTypeValueNif                    = 2, // Número de Identificación Fiscal: ES.
    IdTypeValueNie                    = 3, // Número de Identificación de Extranjero: ES.
    IdTypeValueFiscalIdCode           = 4, // General fiscal ID: ES company. (Handled differently in AddressViewController.)
    IdTypeValuePassport               = 5, // Passport number: ES, ZA.
    IdTypeValueNationalIdCard         = 6, // ID card: all countries.
    IdTypeValueBusinessRegistration   = 7, // Business registration: all countries company.
    IdTypeValueZANationalIdCard       = 8, // ID card: ZA.
    IdTypeValueZABusinessRegistration = 9, // Business registration: ZA company.
};


@interface IdType : NSObject

@property (nonatomic, assign) IdTypeValue value;
@property (nonatomic, assign) NSString*   string;
@property (nonatomic, readonly) NSString* localizedString;
@property (nonatomic, readonly) NSString* localizedRule;

- (instancetype)initWithString:(NSString*)string;

- (instancetype)initWithValue:(IdTypeValue)value;

- (BOOL)isValidWithIdString:(NSString*)idString;

+ (IdTypeValue)valueForString:(NSString*)string;

+ (NSString*)localizedStringForValue:(IdTypeValue)value;

+ (NSString*)localizedRuleTextForValue:(IdTypeValue)value;

@end
