//
//  CountryCodes.h
//  Talk
//
//  Created by Cornelis van der Bent on 10/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CountryCodes : NSObject

+ (CountryCodes*)sharedCodes;

- (NSString*)mobileForIsoCountryCode:(NSString*)isoCountryCode;

- (NSString*)isoForMobileCountryCode:(NSString*)mobileCountryCode;

@end
