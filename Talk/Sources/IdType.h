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
    IdTypeValueNone                 = 0, // No ID type present.
    IdTypeValueDni                  = 1, // Documento Nacional de Identidad: SP.
    IdTypeValueNif                  = 2, // Número de Identificación Fiscal: SP.
    IdTypeValueNie                  = 3, // Número de Identificación de Extranjero: SP.
    IdTypeValuePassport             = 4, // Passport number: SP, ZA.
    IdTypeValueFiscalIdCode         = 5, // Fiscal ID code or CIF: SP company.
    IdTypeValueNationalIdCard       = 6, // ID card: ZA.
    IdTypeValueBusinessRegistration = 7, // Business registration: ZA company.
};


@interface IdType : NSObject

@property (nonatomic, assign) IdTypeValue value;
@property (nonatomic, readonly) NSString* string;
@property (nonatomic, readonly) NSString* localizedString;
@property (nonatomic, readonly) NSString* localizedRule;

- (instancetype)initWithString:(NSString*)string;

- (instancetype)initWithValue:(IdTypeValue)value;

- (BOOL)isValidWithIdString:(NSString*)idString;

+ (IdTypeValue)valueForString:(NSString*)string;

+ (NSString*)localizedStringForValue:(IdTypeValue)value;

+ (NSString*)localizedRuleTextForValue:(IdTypeValue)value;

@end
