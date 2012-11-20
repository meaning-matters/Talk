//
//  PhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/10/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "PhoneNumber.h"
#import "Common.h"


@interface PhoneNumber ()
{
}

@end


@implementation PhoneNumber

@synthesize baseIsoCountryCode   = _baseIsoCountryCode;
@synthesize numberIsoCountryCode = _numberIsoCountryCode;

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


- (id)init
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number
{
    if (self = [super init])
    {
        _baseIsoCountryCode = defaultBaseIsoCountryCode;
    }
    
    return self;
}


- (id)initWithNumber:(NSString*)number baseIsoCountryCode:(NSString*)isoCountryCode;
{
    if (self = [super init])
    {
        _baseIsoCountryCode = isoCountryCode;
    }
    
    return self;
}


- (BOOL)isValid
{
    BOOL    valid = NO;
    
    return valid;
}


- (BOOL)isValidForBaseIsoCountryCode
{
    return [self.numberIsoCountryCode isEqualToString:self.baseIsoCountryCode];
}


- (BOOL)isPossible
{
    BOOL    possible = NO;
    
    return possible;
}


- (PhoneNumberType)type
{
    return PhoneNumberTypeUnknown;
}


- (NSString*)e164Format
{
    
}


- (NSString*)originalFormat
{
    
}


- (NSString*)internationalFormat
{
    
}


- (NSString*)nationalFormat
{
    
}


- (NSString*)outOfCountryFormatFromIsoCountryCode:(NSString*)isoCountryCode
{
    
}


- (NSString*)asYouTypeFormat:(NSString*)partialNumber
{
    
}

@end
