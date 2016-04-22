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
    IdTypeValueNone     = 0, // No ID type present.
    IdTypeValueDni      = 1, // Spain: Documento Nacional de Identidad.
    IdTypeValueNif      = 2, // Spain: Número de Identificación Fiscal.
    IdTypeValueNie      = 3, // Spain: Número de Identificación de Extranjero.
    IdTypeValuePassport = 4, // Passport number.
};


@interface IdType : NSObject

@property (nonatomic, assign) IdTypeValue value;
@property (nonatomic, readonly) NSString* string;
@property (nonatomic, readonly) NSString* localizedString;

- (instancetype)initWithString:(NSString*)string;

- (instancetype)initWithValue:(IdTypeValue)value;

+ (NSString*)localizedStringForValue:(IdTypeValue)value;

@end
