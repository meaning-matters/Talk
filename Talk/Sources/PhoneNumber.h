//
//  PhoneNumber.h
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    PhoneNumberTypeUnknown        =  0,
    PhoneNumberTypeEmergency      =  1,
    PhoneNumberTypeFixedLine      =  2,
    PhoneNumberTypeMobile         =  3,
    PhoneNumberTypePager          =  4,
    PhoneNumberTypePersonalNumber =  5,
    PhoneNumberTypePremiumRate    =  6,
    PhoneNumberTypeSharedCost     =  7,
    PhoneNumberTypeShortCode      =  8,
    PhoneNumberTypeTollFree       =  9,
    PhoneNumberTypeUan            = 10, // Universal Access Number
    PhoneNumberTypeVoiceMail      = 11,
    PhoneNumberTypeVoip           = 12,
} PhoneNumberType;

@interface PhoneNumber : NSObject

@property (nonatomic, readonly) NSString*   baseIsoCountryCode;
@property (nonatomic, readonly) NSString*   numberIsoCountryCode;


+ (void)setDefaultBaseIsoCountryCode:(NSString*)isoCountryCode;

+ (NSString*)defaultBaseIsoCountryCode;

- (id)init;

- (id)initWithNumber:(NSString*)number;

- (id)initWithNumber:(NSString*)number baseIsoCountryCode:(NSString*)isoCountryCode;

@end
