//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumber.h"
#import "Common.h"
#import "LibPhoneNumber.h"


@interface PhoneNumber ()
{
}

@end


@implementation PhoneNumber

@synthesize baseIsoCountryCode   = _baseIsoCountryCode;
@synthesize numberIsoCountryCode = _numberIsoCountryCode;
@synthesize number               = _number;


static NSString*        defaultBaseIsoCountryCode;


+ (void)setDefaultBaseIsoCountryCode:(NSString*)isoCountryCode
{
    defaultBaseIsoCountryCode = isoCountryCode;
}


+ (NSString*)defaultBaseIsoCountryCode
{
    return defaultBaseIsoCountryCode;
}


#pragma mark - Creation

- (id)init
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
        _number = @"";
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
        _number = number;
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number baseIsoCountryCode:(NSString*)isoCountryCode;
{
    if (self = [super init])
    {
        _baseIsoCountryCode = isoCountryCode;
        _number = number;
    }
    
    return self;
}


#pragma mark - Public API

- (NSString*)callCountryCode
{
    return [[LibPhoneNumber sharedInstance] callCountryCodeOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)isoCountryCode
{
    return [[LibPhoneNumber sharedInstance] isoCountryCodeOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (BOOL)isValid
{
    return [[LibPhoneNumber sharedInstance] isValidNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (BOOL)isValidForBaseIsoCountryCode
{
    return [[LibPhoneNumber sharedInstance] isValidNumber:self.number forBaseIsoCountryCode:self.baseIsoCountryCode];
}


- (BOOL)isPossible
{
    return [[LibPhoneNumber sharedInstance] isPossibleNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


// Used when no ISO country code --which LibPhoneNumber requires-- has been set.
// It checks if the number has a calling country code.
- (BOOL)isInternational
{
    BOOL            international;
    PhoneNumber*    nlPhoneNumber = [[PhoneNumber alloc] initWithNumber:self.number baseIsoCountryCode:@"NL"];
    PhoneNumber*    bePhoneNumber = [[PhoneNumber alloc] initWithNumber:self.number baseIsoCountryCode:@"BE"];

    if ([nlPhoneNumber isValid] && [bePhoneNumber isValid])
    {
        if ([[nlPhoneNumber callCountryCode] isEqualToString:[bePhoneNumber callCountryCode]])
        {
            international = YES;
        }
        else
        {
            international = NO;
        }
    }
    else
    {
        international = NO;
    }

    return international;
}


- (BOOL)isEmergency
{
    return [[LibPhoneNumber sharedInstance] isEmergencyNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (PhoneNumberType)type
{
    return [[LibPhoneNumber sharedInstance] typeOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)typeString
{
    NSString*   string = @"";

    switch ([self type])
    {
        case PhoneNumberTypeUnknown:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Unknown", nil,
                                                       [NSBundle mainBundle], @"unknown",
                                                       @"Indicates that the type of the phone number is unknown\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeEmergency:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Emergency", nil,
                                                       [NSBundle mainBundle], @"emergency",
                                                       @"Indicates that this is an emergency phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeFixedLine:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType FixedLine", nil,
                                                       [NSBundle mainBundle], @"fixed-line",
                                                       @"Indicates that this is a fixed-line (or landline) phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'fixed'].");
            break;

        case PhoneNumberTypeMobile:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Mobile", nil,
                                                       [NSBundle mainBundle], @"mobile",
                                                       @"Indicates that this is a mobile phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeFixedLineOrMobile:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType FixedLineOrMobile", nil,
                                                       [NSBundle mainBundle], @"fixed-line or mobile",
                                                       @"Indicates that this is a either a fixed-line or mobile phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'fixed or mobile' or 'landline or mobile'].");
            break;

        case PhoneNumberTypePager:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Pager", nil,
                                                       [NSBundle mainBundle], @"pager",
                                                       @"Indicates that this is a pager phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypePersonalNumber:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType PersonalNumber", nil,
                                                       [NSBundle mainBundle], @"personal number",
                                                       @"Indicates that this is a personal phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'personal'].");
            break;

        case PhoneNumberTypePremiumRate:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType PresmiumRate", nil,
                                                       [NSBundle mainBundle], @"premium-rate",
                                                       @"Indicates that this is a premium-rate (one that costs extra) phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'premium'].");
            break;

        case PhoneNumberTypeSharedCost:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType SharedCost", nil,
                                                       [NSBundle mainBundle], @"shared-cost",
                                                       @"Indicates that this is a shared-cost phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeShortCode:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType ShortCode", nil,
                                                       [NSBundle mainBundle], @"short-code",
                                                       @"Indicates that this is a short-code phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeTollFree:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType TollFree", nil,
                                                       [NSBundle mainBundle], @"toll-free",
                                                       @"Indicates that this is a toll-free phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'free'].");
            break;

        case PhoneNumberTypeUan: // Universal Access Number
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType UniversalAccessNumber", nil,
                                                       [NSBundle mainBundle], @"universal access",
                                                       @"Indicates that this is an universal access phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'access'].");
            break;

        case PhoneNumberTypeVoiceMail:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType VoiceMail", nil,
                                                       [NSBundle mainBundle], @"voicemail",
                                                       @"Indicates that this is a voicemail phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeVoip:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType VoIP", nil,
                                                       [NSBundle mainBundle], @"over-internet",
                                                       @"Indicates that this is a over internet phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'internet'].");
            break;
    }

    return string;
}


- (NSString*)originalFormat
{
    return [[LibPhoneNumber sharedInstance] originalFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)e164Format
{
    NSString*   format;

    format = [[LibPhoneNumber sharedInstance] e164FormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];

    if ([format isEqualToString:@"invalid"])
    {
        format = nil;
    }

    return format;
}


- (NSString*)internationalFormat
{
    return [[LibPhoneNumber sharedInstance] internationalFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)nationalFormat
{
    return [[LibPhoneNumber sharedInstance] nationalFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode
{
    return [[LibPhoneNumber sharedInstance] outOfCountryFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode
                                                   outOfIsoCountryCode:isoCountryCode];
}


- (NSString*)asYouTypeFormat
{
    return [[LibPhoneNumber sharedInstance] asYouTypeFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}

@end
