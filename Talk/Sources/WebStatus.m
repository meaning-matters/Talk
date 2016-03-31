//
//  WebStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "WebStatus.h"


@implementation WebStatus

+ (WebStatusCode)codeForString:(NSString*)string
{
    static NSDictionary*   statuses;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        statuses = @{@"OK"                           : @(WebStatusOk),
                     @"FAIL_INVALID_REQUEST"         : @(WebStatusFailInvalidRequest),
                     @"FAIL_SERVER_INTERNAL"         : @(WebStatusFailServerIternal),
                     @"FAIL_SERVICE_UNAVAILABLE"     : @(WebStatusFailServiceUnavailable),
                     @"FAIL_INVALID_RECEIPT"         : @(WebStatusFailInvalidReceipt),
                     @"FAIL_NO_STATES_FOR_COUNTRY"   : @(WebStatusFailNoStatesForCountry),
                     @"FAIL_INVALID_INFO"            : @(WebStatusFailInvalidInfo),
                     @"FAIL_DATA_TOO_LARGE"          : @(WebStatusFailDataTooLarge),
                     @"FAIL_INSUFFICIENT_CREDIT"     : @(WebStatusFailInsufficientCredit),
                     @"FAIL_IVR_IN_USE"              : @(WebStatusFailIvrInUse),
                     @"FAIL_VERIFIED_NUMBER_IN_USE"  : @(WebStatusFailVerfiedNumberInUse),
                     @"FAIL_DISALLOWED_NUMBER"       : @(WebStatusFailDisallowedNumber),
                     @"FAIL_CALLBACK_ALREADY_ACTIVE" : @(WebStatusFailCallbackAlreadyActive),
                     @"FAIL_NO_CALLBACK_FOUND"       : @(WebStatusFailNoCallbackFound),
                     @"FAIL_NO_CREDIT"               : @(WebStatusFailNoCredit),
                     @"FAIL_UNKNOWN_CALLER_ID"       : @(WebStatusFailUnknownCallerId),
                     @"FAIL_UNKNOWN_VERIFIED_NUMBER" : @(WebStatusFailUnknownVerifiedNumber),
                     @"FAIL_UNKNOWN_BOTH_E164"       : @(WebStatusFailUnknownBothE164),
                     @"FAIL_ADDRESS_IN_USE"          : @(WebStatusFailAddressInUse),
                     @"FAIL_ADDRESS_UNKNOWN"         : @(WebStatusFailAddressUnknown),
                     @"FAIL_NO_NUMBERS_IN_STOCK"     : @(WebStatusFailNoNumbersInStock),
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
        case WebStatusFailInvalidRequest:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInvalidRequest", nil, [NSBundle mainBundle],
                                                       @"Couldn't communicate with the server.",
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
        case WebStatusFailInvalidReceipt:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInvalidReceipt", nil, [NSBundle mainBundle],
                                                       @"Electronic receipt is not valid.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoStatesForCountry:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailNoStatesForCountry", nil, [NSBundle mainBundle],
                                                       @"This country does not have states.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailInvalidInfo:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInvalidInfo", nil, [NSBundle mainBundle],
                                                       @"Your name and address were not accepted.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailDataTooLarge:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailDataTooLarge", nil, [NSBundle mainBundle],
                                                       @"Too much data to load in one go.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailInsufficientCredit:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailInsufficientCredit", nil, [NSBundle mainBundle],
                                                       @"You have not enough credit.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailIvrInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailIvrInUse", nil, [NSBundle mainBundle],
                                                       @"This Destination is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailVerfiedNumberInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailVerifiedNumberInUse", nil, [NSBundle mainBundle],
                                                       @"This Phone is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailDisallowedNumber:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailDisallowedNumbe", nil, [NSBundle mainBundle],
                                                       @"This number can't be added as a Phone.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailCallbackAlreadyActive:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient CallbackAlreadyActive", nil, [NSBundle mainBundle],
                                                       @"There's already a callback request active.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoCallbackFound:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient CallbackNotFound", nil, [NSBundle mainBundle],
                                                       @"No callback request found.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoCredit:   // Not used at the moment, because we have different failure texts.
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient NoCredit", nil, [NSBundle mainBundle],
                                                       @"You've run out of credit; buy more on the Credit tab.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailUnknownCallerId:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient UnknownCallerID", nil, [NSBundle mainBundle],
                                                       @"The caller ID you selected is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailUnknownVerifiedNumber:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient UnknownVerifiedNumber", nil, [NSBundle mainBundle],
                                                       @"The phone you selected to be called back is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailUnknownBothE164:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient UnknownBothE164", nil, [NSBundle mainBundle],
                                                       @"Both the caller ID and the phone to be called back are unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAddressInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient AddressInUse", nil, [NSBundle mainBundle],
                                                       @"This Address is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAddressUnknown:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient AddressUnknown", nil, [NSBundle mainBundle],
                                                       @"This Address is unknown.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailNoNumbersInStock:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient NoNumbersInStock", nil, [NSBundle mainBundle],
                                                       @"Numbers in this area are out of stock. Please try again later.",
                                                       @"Status text.\n"
                                                       @"[].");
            break;
        }
        case WebStatusFailAudioInUse:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient AudioInUse", nil, [NSBundle mainBundle],
                                                       @"This Recording is still being used.",
                                                       @"Status text.\n"
                                                       @"[].");
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
        case WebStatusFailUnspecified:
        {
            string = NSLocalizedStringWithDefaultValue(@"WebClient FailUnspecified", nil, [NSBundle mainBundle],
                                                       @"An unspecified issue.",
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
