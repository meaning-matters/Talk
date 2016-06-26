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
    WebStatusOk                        =      0,
    WebStatusFailRequestInvalid        = 911001,
    WebStatusFailServerIternal         = 911002,
    WebStatusFailServiceUnavailable    = 911003,
    WebStatusFailReceiptInvalid        = 911004,
    WebStatusFailStatesNonexistent     = 911005,
    WebStatusFailCreditInsufficient    = 911006,
    WebStatusFailDestinationInUse      = 911007,
    WebStatusFailPhoneInUse            = 911008,
    WebStatusFailPhoneUnknown          = 911009,
    WebStatusFailE164Disallowed        = 911010,  // Trying to verify a Voxbone DID (of any account).
    WebStatusFailCallbackAlreadyActive = 911011,
    WebStatusFailCallbackUnknown       = 911012,
    WebStatusFailE164IndentityUnknown  = 911013,  // Callback: When caller ID is unknown on server.
    WebStatusFailE164CallbackUnknown   = 911014,  // Callback: When called back number is unknown.
    WebStatusFailE164BothUnknown       = 911015,  // Callback: When both called ID and called back number unknown.
    WebStatusFailAddressInUse          = 911016,
    WebStatusFailAddressUnknown        = 911017,
    WebStatusFailStockExhausted        = 911018,
    WebStatusFailAudioInUse            = 911019,
    WebStatusFailNoInternet            = 911051,  // Indirect: not sent by server, from NSURLErrorNotConnectedToInternet.
    WebStatusFailSecureInternet        = 911052,  // Indirect: not sent by server, from other NSURLError... SSL related.
    WebStatusFailProblemInternet       = 911053,  // Indirect: not sent by server, from NSURLErrorCannotFindHost.
    WebStatusFailInternetLogin         = 911054,  // Indirect: not sent by server, may require to login.
    WebStatusFailNoAccount             = 911055,  // Indirect: not sent by server.
    WebStatusFailOther                 = 911056,  // Indirect: not sent by server, for example a 404.
    WebStatusFailUnspecified           = 911057,  // Indirect: not sent by server, when FAIL_... is missing or is unknown.
    WebStatusFailInvalidResponse       = 911058,  // Indirect: not sent by server, when server response is malformed.
    WebStatusFailNoServer              = 911059,  // No API server could be retrieved with DNS-SRV.
    WebStatusFailUnknown               = 911099,  // Extreme unlikely situation where AFNetworking gives failure with error == nil.
} WebStatusCode;


@interface WebStatus : NSObject

+ (WebStatusCode)codeForString:(NSString*)string;

+ (NSString*)localizedStringForStatus:(WebStatusCode)code;

@end
