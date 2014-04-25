//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumber.h"
#import "Common.h"
#import "Settings.h"
#import "LibPhoneNumber.h"
#import "CountryNames.h"


@implementation PhoneNumber

@synthesize isoCountryCode = _isoCountryCode;

static NSString*    defaultIsoCountryCode = @"";


+ (void)setDefaultIsoCountryCode:(NSString*)isoCountryCode
{
    defaultIsoCountryCode = isoCountryCode;
}


+ (NSString*)defaultIsoCountryCode
{
    return defaultIsoCountryCode;
}


+ (NSString*)stripNumber:(NSString*)number
{
    NSCharacterSet* stripSet = [NSCharacterSet characterSetWithCharactersInString:@"()-. \u00a0\t\n\r"];

    return [[number componentsSeparatedByCharactersInSet:stripSet] componentsJoinedByString:@""];
}


- (void)setNumber:(NSString*)number
{
    _number = [PhoneNumber stripNumber:number];

    _isoCountryCode = [[LibPhoneNumber sharedInstance] isoCountryCodeOfNumber:self.number
                                                               isoCountryCode:defaultIsoCountryCode];
    if (_isoCountryCode.length == 0)
    {
        _isoCountryCode = defaultIsoCountryCode;
    }
}


#pragma mark - Creation

- (instancetype)init
{
    if (self = [super init])
    {
        _isoCountryCode = defaultIsoCountryCode;
        _number = @"";
    }
    
    return self;
}


- (instancetype)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
        self.number = number ? number : @"";
    }
    
    return self;
}


- (instancetype)initWithNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;
{
    if (self = [super init])
    {
        self.number     = number         ? number         : @"";
        _isoCountryCode = isoCountryCode ? isoCountryCode : defaultIsoCountryCode;
    }
    
    return self;
}


#pragma mark - Public API

- (NSString*)isoCountryCode
{
    return (_isoCountryCode.length > 0) ? _isoCountryCode : defaultIsoCountryCode;
}


- (NSString*)callCountryCode
{
    return [[LibPhoneNumber sharedInstance] callCountryCodeOfNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (BOOL)isValid
{
    return [[LibPhoneNumber sharedInstance] isValidNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (BOOL)isValidForBaseIsoCountryCode:(NSString*)isoCountryCode;
{
    return [[LibPhoneNumber sharedInstance] isValidNumber:self.number forIsoCountryCode:isoCountryCode];
}


- (BOOL)isPossible
{
    return [[LibPhoneNumber sharedInstance] isPossibleNumber:self.number isoCountryCode:self.isoCountryCode];
}


// Used when no ISO country code --which LibPhoneNumber requires-- has been set.
// It checks if the number has a calling country code.
- (BOOL)isInternational
{
    BOOL         international;
    PhoneNumber* nlPhoneNumber = [[PhoneNumber alloc] initWithNumber:self.number isoCountryCode:@"NL"];
    PhoneNumber* bePhoneNumber = [[PhoneNumber alloc] initWithNumber:self.number isoCountryCode:@"BE"];

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
    return [[LibPhoneNumber sharedInstance] isEmergencyNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (PhoneNumberType)type
{
    return [[LibPhoneNumber sharedInstance] typeOfNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (NSString*)typeString
{
    NSString* string = @"";

    switch ([self type])
    {
        case PhoneNumberTypeUnknown:
            // Useless for user to see 'unknown'.
            break;

        case PhoneNumberTypeEmergency:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Emergency", nil,
                                                       [NSBundle mainBundle], @"emergency",
                                                       @"Indicates that this is an emergency phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeFixedLine:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType FixedLine", nil,
                                                       [NSBundle mainBundle], @"fixed",
                                                       @"Indicates that this is a fixed-line (or landline) phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeMobile:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Mobile", nil,
                                                       [NSBundle mainBundle], @"mobile",
                                                       @"Indicates that this is a mobile phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeFixedLineOrMobile:
            // Not interesting for user to see 'fixed or mobile' because it does not add much.
            break;

        case PhoneNumberTypePager:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType Pager", nil,
                                                       [NSBundle mainBundle], @"pager",
                                                       @"Indicates that this is a pager phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypePersonalNumber:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType PersonalNumber", nil,
                                                       [NSBundle mainBundle], @"personal",
                                                       @"Indicates that this is a personal phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypePremiumRate:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType PresmiumRate", nil,
                                                       [NSBundle mainBundle], @"premium",
                                                       @"Indicates that this is a premium-rate (one that costs extra) phone number\n"
                                                       @"[0.5 line small font].");
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
                                                       [NSBundle mainBundle], @"access",
                                                       @"Indicates that this is a universal access phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeVoiceMail:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType VoiceMail", nil,
                                                       [NSBundle mainBundle], @"voicemail",
                                                       @"Indicates that this is a voicemail phone number\n"
                                                       @"[0.5 line small font].");
            break;

        case PhoneNumberTypeVoip:
            string = NSLocalizedStringWithDefaultValue(@"General:NumberType VoIP", nil,
                                                       [NSBundle mainBundle], @"internet",
                                                       @"Indicates that this is a over internet phone number\n"
                                                       @"[0.5 line small font - abbreviated: 'internet'].");
            break;
    }

    return string;
}


- (NSString*)infoString
{
    NSString* string = @"";

    if (self.isEmergency)
    {
        string = [NSString stringWithFormat:@"%@", [self typeString]];
    }
    else if (self.isValid)
    {
        NSString*   impossible;
        NSString*   country = [[CountryNames sharedNames] nameForIsoCountryCode:[self isoCountryCode]];
        if ([country length] > 0)
        {
            country = [NSString stringWithFormat:@"%@%@", country, ([self typeString].length > 0) ? @" - " : @""];
        }
        else
        {
            country = @"";
        }

        if (self.isPossible == NO)
        {
            impossible = NSLocalizedStringWithDefaultValue(@"General:Number Impossible", nil, [NSBundle mainBundle],
                                                           @"impossible",
                                                           @"Indicates that the phone number is impossible (i.e. can't exist)\n"
                                                           @"[0.5 line small font].");

            string = [NSString stringWithFormat:@"%@%@ (%@)", country, [self typeString], impossible];
        }
        else
        {
            string = [NSString stringWithFormat:@"%@%@", country, [self typeString]];
        }
    }
    else if ([self.number isEqualToString:[Settings sharedSettings].testNumber])
    {
        NSString* test;
        test = NSLocalizedStringWithDefaultValue(@"General:Number Test", nil, [NSBundle mainBundle],
                                                 @"test",
                                                 @"Indicator of test phone number\n"
                                                 @"[0.5 line small font].");
        string = [NSString stringWithFormat:@"NumberBay - %@", test];
    }
    else
    {
        NSString* isoCountryCode = [[LibPhoneNumber sharedInstance] isoCountryCodeOfNumber:self.number
                                                                            isoCountryCode:[self isoCountryCode]];
        string = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
    }

    return string;
}


- (NSString*)originalFormat
{
    return [[LibPhoneNumber sharedInstance] originalFormatOfNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (NSString*)e164Format
{
    NSString* format;

    format = [[LibPhoneNumber sharedInstance] e164FormatOfNumber:self.number isoCountryCode:self.isoCountryCode];
    if ([format isEqualToString:@"invalid"])
    {
        format = self.number;
        NBLog(@"Invalid E164: %@.", self.number);
    }

    return format;
}


- (NSString*)e164FormatWithoutPlus
{
    NSString*   format;

    format = [self e164Format];
    if ([format isEqualToString:@"invalid"])
    {
        format = nil;
    }
    else
    {
        format = [format substringFromIndex:1];
    }

    return format;
}


- (NSString*)internationalFormat
{
#warning Handle LibPhoneNumber returning "invalid" (here, or in LibPhoneNumber).  Also localize!  (May apply for other methods as well.)
    return [[LibPhoneNumber sharedInstance] internationalFormatOfNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (NSString*)nationalFormat
{
    return [[LibPhoneNumber sharedInstance] nationalFormatOfNumber:self.number isoCountryCode:self.isoCountryCode];
}


- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode
{
    return [[LibPhoneNumber sharedInstance] outOfCountryFormatOfNumber:self.number isoCountryCode:self.isoCountryCode
                                                   outOfIsoCountryCode:isoCountryCode];
}


- (NSString*)asYouTypeFormat
{
    return [[LibPhoneNumber sharedInstance] asYouTypeFormatOfNumber:self.number isoCountryCode:self.isoCountryCode];
}

@end
