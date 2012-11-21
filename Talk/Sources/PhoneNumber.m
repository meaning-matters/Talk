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


+ (void)initialize
{
}


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


#pragma mark - Utility Methods

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


- (PhoneNumberType)type
{
    return [[LibPhoneNumber sharedInstance] typeOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)originalFormat
{
    return [[LibPhoneNumber sharedInstance] originalFormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
}


- (NSString*)e164Format
{
    return [[LibPhoneNumber sharedInstance] e164FormatOfNumber:self.number isoCountryCode:self.baseIsoCountryCode];
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
