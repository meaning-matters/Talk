//
//  Call.m
//  Talk
//
//  Created by Cornelis van der Bent on 04/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Call.h"

@implementation Call

- (id)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction
{
    if (self = [super init])
    {
        _phoneNumber  = phoneNumber;        
        _beginDate    = [NSDate date];
        _state        = CallStateNone;
        _direction    = direction;
        _network      = CallNetworkInternet; // Default.
    }

    return self;
}


- (void)end
{
    if (self.state == CallStateConnected)
    {
        //### send hangup to SIP
        _state = CallStateEnded;
    }
    else
    {
        //###
    }

    _endDate = [NSDate date];
}


- (NSString*)stateString
{
    NSString*   string;

    switch (self.state)
    {
        case CallStateNone:
            string = @"";
            break;

        case CallStateCalling:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Calling", nil,
                                                       [NSBundle mainBundle], @"calling...",
                                                       @"In-call status that calling a number ha started; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateRinging:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Ringing", nil,
                                                       [NSBundle mainBundle], @"ringing...",
                                                       @"In-call status that called party hears ring tone; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateConnecting:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Connected", nil,
                                                       [NSBundle mainBundle], @"connecting...",
                                                       @"In-call status that call is almost connected; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateConnected:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Connected", nil,
                                                       [NSBundle mainBundle], @"connected",
                                                       @"In-call status that call is connected; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateEnding:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Ending", nil,
                                                       [NSBundle mainBundle], @"ending...",
                                                       @"In-call status that call is being ended; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateEnded:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Ended", nil,
                                                       [NSBundle mainBundle], @"ended",
                                                       @"In-call status that call was ended; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateCanceled:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Canceled", nil,
                                                       [NSBundle mainBundle], @"canceled",
                                                       @"In-call status that user has canceled not yet connected call; Apple standard\n"
                                                       @"[1 line small font].");
            break;
        case CallStateBusy:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Busy", nil,
                                                       [NSBundle mainBundle], @"busy",
                                                       @"In-call status that called party is already on the phone; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateDeclined:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Declined", nil,
                                                       [NSBundle mainBundle], @"declined",
                                                       @"In-call status that called party has declined; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateNotAllowed:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status NotAllowed", nil,
                                                       [NSBundle mainBundle], @"not allowed",
                                                       @"In-call status that calls to a number are nog allowed; Apple standard\n"
                                                       @"[1 line small font].");
            break;

        case CallStateFailed:
            string = NSLocalizedStringWithDefaultValue(@"Call:Status Failed", nil,
                                                       [NSBundle mainBundle], @"failed",
                                                       @"In-call status that calling a number failed; Apple standard\n"
                                                       @"[1 line small font].");
            break;
    }

    return string;
}


- (NSString*)failedString
{
    NSString*   string;

    string = @"failed";//###

    return string;
}

@end
