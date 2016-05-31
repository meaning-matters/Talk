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
    WebStatusFailServerIternal         = 911001,
    WebStatusFailServiceUnavailable    = 911002,
    WebStatusFailReceiptInvalid        = 911003,
    WebStatusFailStatesNonexistent     = 911004,
    WebStatusFailCreditInsufficient    = 911005,
    WebStatusFailDestinationInUse      = 911006,
    WebStatusFailPhoneInUse            = 911007,
    WebStatusFailPhoneUnknown          = 911008,
    WebStatusFailE164Disallowed        = 911009,  // Trying to verify a Voxbone DID (of any account).
    WebStatusFailCallbackAlreadyActive = 911010,
    WebStatusFailCallbackUnknown       = 911011,
    WebStatusFailE164IndentityUnknown  = 911012,  // Callback: When caller ID is unknown on server.
    WebStatusFailE164CallbackUnknown   = 911013,  // Callback: When called back number is unknown.
    WebStatusFailE164BothUnknown       = 911014,  // Callback: When both called ID and called back number unknown.
    WebStatusFailAddressInUse          = 911015,
    WebStatusFailAddressUnknown        = 911016,
    WebStatusFailStockExhausted        = 911017,
    WebStatusFailAudioInUse            = 911018,
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
