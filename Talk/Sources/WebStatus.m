//
//  WebStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/15.
//  Copyright © 2015 Cornelis van der Bent. All rights reserved.
//

#import "WebStatus.h"


@implementation WebStatus

+ (WebStatusCode)codeForString:(NSString*)string
{
    static NSDictionary*   statuses;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        statuses = @{@"OK"                           : @(WebClientStatusOk),
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
                     @"FAIL_CALLBACK_ALREADY_ACTIVE" : @(WebStatusFailCallbackAlreadyActive),
                     @"FAIL_NO_CALLBACK_FOUND"       : @(WebStatusFailNoCallbackFound),
                     @"FAIL_NO_CREDIT"               : @(WebStatusFailNoCredit),
                     @"FAIL_UNKNOWN_CALLER_ID"       : @(WebStatusFailUnknownCallerId),
                     @"FAIL_UNKNOWN_VERIFIED_NUMBER" : @(WebStatusFailUnknownVerifiedNumber),
                     @"FAIL_UNKNOWN_BOTH_E164"       : @(WebStatusFailUnknownBothE164)};
    });
    
    NSNumber*     number = statuses[string];
    WebStatusCode code = (number != nil) ? [number intValue] : WebStatusFailUnspecified;

    return code;
}

@end
