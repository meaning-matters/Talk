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
    PhoneNumberTypeUan               = 11, // Universal Access Number
    PhoneNumberTypeVoiceMail         = 12,
    PhoneNumberTypeVoip              = 13,
} PhoneNumberType;

@interface PhoneNumber : NSObject

@property (nonatomic, readonly) NSString*   baseIsoCountryCode;
@property (nonatomic, readonly) NSString*   numberIsoCountryCode;
@property (nonatomic, strong) NSString*     number;                 // As entered (no formatting).


+ (void)setDefaultBaseIsoCountryCode:(NSString*)isoCountryCode;

+ (NSString*)defaultBaseIsoCountryCode;

- (id)init;

- (id)initWithNumber:(NSString*)number;

- (id)initWithNumber:(NSString*)number baseIsoCountryCode:(NSString*)isoCountryCode;

- (NSString*)callCountryCode;

- (NSString*)isoCountryCode;

- (BOOL)isValid;

- (BOOL)isValidForBaseIsoCountryCode;

- (BOOL)isPossible;

- (PhoneNumberType)type;

- (NSString*)originalFormat;

- (NSString*)e164Format;

- (NSString*)internationalFormat;

- (NSString*)nationalFormat;

- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode;

- (NSString*)asYouTypeFormat;

@end
