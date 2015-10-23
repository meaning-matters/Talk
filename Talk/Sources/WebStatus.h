//
//  WebStatus.h
//  Talk
//
//  Created by Cornelis van der Bent on 12/10/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
    WebStatusOk,
    WebStatusFailInvalidRequest        = 911001,
    WebStatusFailServerIternal         = 911002,
    WebStatusFailServiceUnavailable    = 911003,
    WebStatusFailInvalidReceipt        = 911004,
    WebStatusFailNoStatesForCountry    = 911005,
    WebStatusFailInvalidInfo           = 911006,
    WebStatusFailDataTooLarge          = 911007,
    WebStatusFailInsufficientCredit    = 911008,
    WebStatusFailIvrInUse              = 911009,
    WebStatusFailVerfiedNumberInUse    = 911010,
    WebStatusFailCallbackAlreadyActive = 911011,
    WebStatusFailNoCallbackFound       = 911012,
    WebStatusFailNoCredit              = 911013,
    WebStatusFailUnknownCallerId       = 911014,  // Callback: When caller ID is unknown on server.
    WebStatusFailUnknownVerifiedNumber = 911015,  // Callback: When called back number is unknown.
    WebStatusFailUnknownBothE164       = 911016,  // Callback: When both called ID and called back number unknown.
    WebStatusFailNoAccount             = 911051,  // Indirect: not sent by server.
    WebStatusFailUnspecified           = 911052,  // Indirect: not sent by server.
    WebStatusFailInvalidResponse       = 911053,  // Indirect: not sent by server.
    WebStatusFailUnknown               = 911054,  // Extreme unlikely situation where AFNetworking gives failure with error == nil.
} WebStatusCode;


@interface WebStatus : NSObject

+ (WebStatusCode)codeForString:(NSString*)string;

+ (NSString*)localizedStringForStatus:(WebStatusCode)code;

@end
