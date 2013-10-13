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
    PhoneNumberTypeUnknown           =  0,
    PhoneNumberTypeEmergency         =  1,
    PhoneNumberTypeFixedLine         =  2,
    PhoneNumberTypeMobile            =  3,
    PhoneNumberTypeFixedLineOrMobile =  4,
    PhoneNumberTypePager             =  5,
    PhoneNumberTypePersonalNumber    =  6,
    PhoneNumberTypePremiumRate       =  7,
    PhoneNumberTypeSharedCost        =  8,
    PhoneNumberTypeShortCode         =  9,
    PhoneNumberTypeTollFree          = 10,
    PhoneNumberTypeUan               = 11,          // Universal Access Number
    PhoneNumberTypeVoiceMail         = 12,
    PhoneNumberTypeVoip              = 13,
} PhoneNumberType;


#define PhoneNumberMinimumLength        7           // Minimum length of a local phone number.


@interface PhoneNumber : NSObject

@property (nonatomic, readonly) NSString* isoCountryCode;
@property (nonatomic, strong) NSString*   number;   // As entered (no formatting).


+ (void)setDefaultIsoCountryCode:(NSString*)isoCountryCode;

+ (NSString*)defaultIsoCountryCode;

- (instancetype)init;

- (instancetype)initWithNumber:(NSString*)number;

- (instancetype)initWithNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)callCountryCode;

- (BOOL)isValid;

- (BOOL)isValidForBaseIsoCountryCode:(NSString*)isoCountryCode;

- (BOOL)isPossible;

- (BOOL)isInternational;

- (BOOL)isEmergency;

- (PhoneNumberType)type;

- (NSString*)typeString;

- (NSString*)infoString;

- (NSString*)originalFormat;

- (NSString*)e164Format;

- (NSString*)e164FormatWithoutPlus;

- (NSString*)internationalFormat;

- (NSString*)nationalFormat;

- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode;

- (NSString*)asYouTypeFormat;

@end
