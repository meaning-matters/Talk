//
//  WebStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "WebStatus.h"
#import "NetworkStatus.h"
#import "Strings.h"


@implementation WebStatus

+ (WebStatusCode)codeForString:(NSString*)string
{
    static NSDictionary*   statuses;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        statuses = @{@"OK"                           : @(WebStatusOk),
                     @"FAIL_SERVER_INTERNAL"         : @(WebStatusFailServerIternal),
                     @"FAIL_SERVICE_UNAVAILABLE"     : @(WebStatusFailServiceUnavailable),
                     @"FAIL_RECEIPT_INVALID"         : @(WebStatusFailReceiptInvalid),
                     @"FAIL_STATES_NONEXISTENT"      : @(WebStatusFailStatesNonexistent),
                     @"FAIL_CREDIT_INSUFFICIENT"     : @(WebStatusFailCreditInsufficient),
                     @"FAIL_DESTINATION_IN_USE"      : @(WebStatusFailDestinationInUse),
                     @"FAIL_PHONE_IN_USE"            : @(WebStatusFailPhoneInUse),
                     @"FAIL_PHONE_UNKNOWN"           : @(WebStatusFailPhoneUnknown),
                     @"FAIL_E164_DISALLOWED"         : @(WebStatusFailE164Disallowed),
                     @"FAIL_CALLBACK_ALREADY_ACTIVE" : @(WebStatusFailCallbackAlreadyActive),
                     @"FAIL_CALLBACK_UNKNOWN"        : @(WebStatusFailCallbackUnknown),
                     @"FAIL_E164_IDENTITY_UNKNOWN"   : @(WebStatusFailE164IndentityUnknown),
                     @"FAIL_E164_CALLBACK_UNKNOWN"   : @(WebStatusFailE164CallbackUnknown),
                     @"FAIL_E164_BOTH_UNKNOWN"       : @(WebStatusFailE164BothUnknown),
                     @"FAIL_ADDRESS_IN_USE"          : @(WebStatusFailAddressInUse),
                     @"FAIL_ADDRESS_UNKNOWN"         : @(WebStatusFailAddressUnknown),
                     @"FAIL_STOCK_EXHAUSTED"         : @(WebStatusFailStockExhausted),
                     @"FAIL_AUDIO_IN_USE"            : @(WebStatusFailAudioInUse)};
    });
    
    NSNumber*     number = statuses[string];
    WebStatusCode code = (number != nil) ? [number intValue] : WebStatusFailUnspecified;

    return code;
}


+ (NSString*)localizedStringForStatus:(WebStatusCode)code
{
    NSString* string;

    switch (code)
    {
        case WebStatusOk:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient StatusOk", nil, [NSBundle mainBundle],
                                                       @"Successful.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailRequestInvalid:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailRequestInvalid", nil, [NSBundle mainBundle],
                                                       @"Server could not process request.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailServerIternal:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailServerIternal", nil, [NSBundle mainBundle],
                                                       @"Internal server issue.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailServiceUnavailable:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailServiceUnavailable", nil, [NSBundle mainBundle],
                                                       @"Service is temporatily unavailable.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailReceiptInvalid:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailReceiptInvalid", nil, [NSBundle mainBundle],
                                                       @"Electronic receipt is not valid.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailStatesNonexistent:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailNoStatesForCountry", nil, [NSBundle mainBundle],
                                                       @"This country does not have states.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailCreditInsufficient:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailCreditInsufficient", nil, [NSBundle mainBundle],
                                                       @"You have not enough credit; buy more on the Credit tab.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailDestinationInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailDestinationInUse", nil, [NSBundle mainBundle],
                                                       @"This Destination is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailPhoneInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailVerifiedNumberInUse", nil, [NSBundle mainBundle],
                                                       @"This Phone is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailPhoneUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailVerifiedNumberInUse", nil, [NSBundle mainBundle],
                                                       @"The Phone is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailE164Disallowed:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailE164Disallowed", nil, [NSBundle mainBundle],
                                                       @"This number can't be added as a Phone.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailCallbackAlreadyActive:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailCallbackAlreadyActive", nil, [NSBundle mainBundle],
                                                       @"There's already a Callback request active.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailCallbackUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailCallbackUnknown", nil, [NSBundle mainBundle],
                                                       @"No Callback request found.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailE164IndentityUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailE164IndentityUnknown", nil, [NSBundle mainBundle],
                                                       @"The Caller ID you selected is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailE164CallbackUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailE164CallbackUnknown", nil, [NSBundle mainBundle],
                                                       @"The Phone you selected to be called back is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailE164BothUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailE164BothUnknown", nil, [NSBundle mainBundle],
                                                       @"Both the Caller ID and the Phone to be called back are unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAddressInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailAddressInUse", nil, [NSBundle mainBundle],
                                                       @"This Address is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAddressUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailAddressUnknown", nil, [NSBundle mainBundle],
                                                       @"This Address is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailStockExhausted:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailStockExhausted", nil, [NSBundle mainBundle],
                                                       @"Numbers in this area are out of stock. Please try again later.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAudioInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailAudioInUse", nil, [NSBundle mainBundle],
                                                       @"This Recording is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoInternet:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailNoInternet", nil, [NSBundle mainBundle],
                                                       @"The Internet connection appears to be offline.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailSecureInternet:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailSecureInternet", nil, [NSBundle mainBundle],
                                                       @"A secure Internet connection apears to be unavailable.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailProblemInternet:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailSecureInternet", nil, [NSBundle mainBundle],
                                                       @"There appears to be a problem with the Internet connection.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailInternetLogin:
        {
            NSString* networkText;

            if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableWifi)
            {
                networkText = [Strings wifiString];
            }
            else
            {
                networkText = [Strings internetString];
            }
            
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInternetLogin", nil, [NSBundle mainBundle],
                                                       @"The %@ connection seems to require you to login.",
                                                       @"Status text.\n"
                                                       @"[].");
            string = [NSString stringWithFormat:string, networkText];
            break;
        }
        case WebStatusFailNoAccount:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailNoAccount", nil, [NSBundle mainBundle],
                                                       @"There's no active account.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailOther:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailOther", nil, [NSBundle mainBundle],
                                                       @"Something went wrong.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailUnspecified:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailUnspecified", nil, [NSBundle mainBundle],
                                                       @"Error received from server.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailInvalidResponse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInvalidResponse", nil, [NSBundle mainBundle],
                                                       @"Invalid data received from server.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoServer:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailNoServer", nil, [NSBundle mainBundle],
                                                       @"No server could be reached.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInvalidResponse", nil, [NSBundle mainBundle],
                                                       @"Unknown error received from server.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
    }
    
    return string;
}

@end
