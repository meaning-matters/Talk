//
//  LibPhoneNumber.m
//  Talk
//
//  Created by Cornelis van der Bent on 21/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  Look in External/LibPhoneNumber/wrapper/wrapper.js for the JavaScript functions
//  called here.
//
//  Documentation is here: http://libphonenumber.googlecode.com/svn/trunk/javadoc/com/google/i18n/phonenumbers/PhoneNumberUtil.html
//


#import "LibPhoneNumber.h"


@interface LibPhoneNumber ()
{
    UIWebView*  webView;
}

@end


@implementation LibPhoneNumber

#pragma mark - Singleton Stuff

+ (LibPhoneNumber*)sharedInstance
{
    static LibPhoneNumber*  sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[LibPhoneNumber alloc] init];

        [sharedInstance setUp];
    });

    return sharedInstance;
}


- (void)setUp
{
    webView = [[UIWebView alloc] initWithFrame:CGRectZero];
    webView.delegate = self;
    
    [webView loadHTMLString:@"<script src='LibPhoneNumber.js'></script>"
                    baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];

    // Start a run-loop to create a maximum 5s app delay for loading Javascript.
    if (CFRunLoopRunInMode(kCFRunLoopDefaultMode, 5.0, NO) != kCFRunLoopRunStopped)
    {
        NSLog(@"//### Javascript not fully loaded in time.");
    }
}


#pragma mark - UIwebView Delegate

- (void)webViewDidFinishLoad:(UIWebView*)aWebView
{
    // Stop the Javascript loading run-loop.
	CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
}


- (void)webView:(UIWebView*)webView didFailLoadWithError:(NSError*)error
{
    // Stop the Javascript loading run-loop.
    CFRunLoopStop([[NSRunLoop currentRunLoop] getCFRunLoop]);
    
    NSLog(@"Loading Javascript error: %@", error.localizedDescription);
}


#pragma mark - Public API (RegionCode "NL", CountryCode "31")

#warning //### Check with Java doc above, which isoCountryCode parameter can be removed.

- (NSString*)callCountryCodeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getCountryCode('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return result;
}


- (NSString*)isoCountryCodeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getRegionCodeForNumber('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return result;
}


//### Check if number is valid in itself (does not look at ISO code???)
- (BOOL)isValidNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"isValidNumber('%@','%@')", number, isoCountryCode];
    BOOL        result   = [[webView stringByEvaluatingJavaScriptFromString:function] boolValue];

    return result;
}


//### Check if number is valid in ISO Code region (e.g. US vs. CA; both have +1).
- (BOOL)isValidNumber:(NSString*)number forIsoCountryCode:(NSString*)isoCountryCode;
{
    NSString*   function = [[NSString alloc] initWithFormat: @"isValidNumberForRegion('%@','%@')", number, isoCountryCode];
    BOOL        result   = [[webView stringByEvaluatingJavaScriptFromString:function] boolValue];

    return result;
}


- (BOOL)isPossibleNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"isPossibleNumber('%@','%@')", number, isoCountryCode];
    BOOL        result   = [[webView stringByEvaluatingJavaScriptFromString:function] boolValue];

    return result;
}


- (BOOL)isEmergencyNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"isEmergencyNumber('%@','%@')", number, isoCountryCode];
    BOOL        result   = [[webView stringByEvaluatingJavaScriptFromString:function] boolValue];

    return result;
}


- (PhoneNumberType)typeOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getNumberType('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    if ([self isEmergencyNumber:number isoCountryCode:isoCountryCode])
    {
        return PhoneNumberTypeEmergency;
    }
    else if ([result isEqualToString:@"fixed-line"])
    {
        return PhoneNumberTypeFixedLine;
    }
    else if ([result isEqualToString:@"mobile"])
    {
        return PhoneNumberTypeMobile;
    }
    else if ([result isEqualToString:@"fixed-line or mobile"])
    {
        return PhoneNumberTypeFixedLineOrMobile;
    }
    else if ([result isEqualToString:@"toll-free"])
    {
        return PhoneNumberTypeTollFree;
    }
    else if ([result isEqualToString:@"premium-rate"])
    {
        return PhoneNumberTypePremiumRate;
    }
    else if ([result isEqualToString:@"shared-cost"])
    {
        return PhoneNumberTypeSharedCost;
    }
    else if ([result isEqualToString:@"VoIP"])
    {
        return PhoneNumberTypeVoip;
    }
    else if ([result isEqualToString:@"personal number"])
    {
        return PhoneNumberTypePersonalNumber;
    }
    else if ([result isEqualToString:@"pager"])
    {
        return PhoneNumberTypePager;
    }
    else if ([result isEqualToString:@"UAN"])
    {
        return PhoneNumberTypeUan;
    }
    else if ([result isEqualToString:@"unknown"])
    {
        return PhoneNumberTypeUnknown;
    }
    else
    {
        NSLog(@"Unknown phone number type");
        return PhoneNumberTypeUnknown;
    }
}


- (NSString*)originalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getOriginalFormat('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}


- (NSString*)e164FormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getE164Format('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}


- (NSString*)internationalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getInternationalFormat('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}


- (NSString*)nationalFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getNationalFormat('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}


- (NSString*)outOfCountryFormatOfNumber:(NSString*)number
                         isoCountryCode:(NSString*)isoCountryCode       // ISO country code of number.
                    outOfIsoCountryCode:(NSString*)outOfIsoCountryCode  // ISO country code from which to call.
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getOutOfCountryCallingFormat('%@','%@','%@')",
                                                             number, isoCountryCode, outOfIsoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}


- (NSString*)asYouTypeFormatOfNumber:(NSString*)number isoCountryCode:(NSString*)isoCountryCode
{
    NSString*   function = [[NSString alloc] initWithFormat: @"getAsYouTypeFormat('%@','%@')", number, isoCountryCode];
    NSString*   result   = [webView stringByEvaluatingJavaScriptFromString:function];

    return ([result length] > 0) ? result : nil;
}

@end
