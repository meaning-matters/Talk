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
    WebStatusFailDisallowedNumber      = 911011,  // Trying to verify a Voxbone DID (of any account).
    WebStatusFailCallbackAlreadyActive = 911012,
    WebStatusFailNoCallbackFound       = 911013,
    WebStatusFailNoCredit              = 911014,
    WebStatusFailUnknownCallerId       = 911015,  // Callback: When caller ID is unknown on server.
    WebStatusFailUnknownVerifiedNumber = 911016,  // Callback: When called back number is unknown.
    WebStatusFailUnknownBothE164       = 911017,  // Callback: When both called ID and called back number unknown.
    WebStatusFailAddressInUse          = 911018,
    WebStatusFailAddressUnknown        = 911019,
    WebStatusFailNoNumbersInStock      = 911020,
    WebStatusFailAudioInUse            = 911021,
    WebStatusFailNoAccount             = 911051,  // Indirect: not sent by server.
    WebStatusFailUnspecified           = 911052,  // Indirect: not sent by server.
    WebStatusFailInvalidResponse       = 911053,  // Indirect: not sent by server.
    WebStatusFailNoServer              = 911054,  // No API server could be retrieved with DNS-SRV.
    WebStatusFailUnknown               = 911099,  // Extreme unlikely situation where AFNetworking gives failure with error == nil.
} WebStatusCode;


@interface WebStatus : NSObject

+ (WebStatusCode)codeForString:(NSString*)string;

+ (NSString*)localizedStringForStatus:(WebStatusCode)code;

@end
