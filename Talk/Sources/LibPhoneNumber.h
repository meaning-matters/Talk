//
//  LibPhoneNumber.h
//  Talk
//
//  Created by Cornelis van der Bent on 21/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PhoneNumber.h" // Needed for PhoneNumberType.  Circular dependency; but not a big deal.


@interface LibPhoneNumber : NSObject <UIWebViewDelegate>

+ (LibPhoneNumber*)sharedInstance;

- (NSString*)callCountryCodeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)isoCountryCodeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (BOOL)isValidNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (BOOL)isValidNumber:(NSString*)number forIsoCountryCode:(NSString*)isoCountryCode;//### See code what's different with previous.

- (BOOL)isPossibleNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (BOOL)isEmergencyNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (PhoneNumberType)typeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)originalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)e164FormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)internationalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)nationalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

- (NSString*)outOfCountryFormatOfNumber:(NSString*)number
                         isoCountryCode:(NSString*)isoCountryCode       // ISO country code of number.
                    outOfIsoCountryCode:(NSString*)outOfIsoCountryCode; // ISO country code from which to call.

- (NSString*)asYouTypeFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode;

@end
