//
//  SipInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsua-lib/pjsua.h>
#import "Call.h"


typedef enum
{
    SipInterfaceRegisteredNo,
    SipInterfaceRegisteredYes,
    SipInterfaceRegisteredFailed
} SipInterfaceRegistered;

typedef enum
{
    SipInterfaceCallFailedNotAllowedCountry,    // Unsupported country (custom SIP state).
    SipInterfaceCallFailedNotAllowedNumber,     // For premium number for example (custom SIP state).
    SipInterfaceCallFailedNoCredit,             // No credit on server (custom SIP state).
    SipInterfaceCallFailedCalleeNotOnline,      // Callee not online (custom SIP state).
    SipInterfaceCallFailedTooManyCalls,         // PJSUA_MAX_CALLS reached.
    SipInterfaceCallFailedTechnical,            // Internal/Unknown error.
    SipInterfaceCallFailedInvalidNumber,        // Malformed URL, ...?
    SipInterfaceCallFailedBadRequest,
    SipInterfaceCallFailedNotFound,
    SipInterfaceCallFailedTemporarilyUnavailable,
    SipInterfaceCallFailedPstnTerminationFail,
    SipInterfaceCallFailedCallRoutingError,
    SipInterfaceCallFailedOtherSipError,
} SipInterfaceCallFailed;

typedef enum
{
    SipInterfaceErrorInternal,                  //### Think of more usefull ones.
} SipInterfaceError;


@class SipInterface;

@protocol SipInterfaceDelegate <NSObject>   // All these methods will be invoked on main thread.

- (void)sipInterface:(SipInterface*)interface callCalling:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callRinging:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callConnecting:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callConnected:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callEnding:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callEnded:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callBusy:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callDeclined:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callFailed:(Call*)call reason:(SipInterfaceCallFailed)reason;

- (void)sipInterface:(SipInterface*)interface callIncoming:(Call*)call;

- (void)sipInterface:(SipInterface*)interface callIncomingCanceled:(Call*)call;

- (void)sipInterface:(SipInterface*)interface call:(Call*)call onMute:(BOOL)onMute;     // Response method of requesting on-mute.

- (void)sipInterface:(SipInterface*)interface call:(Call*)call onHold:(BOOL)onHold;     // Response method ... .

- (void)sipInterface:(SipInterface*)interface onSpeaker:(BOOL)onSpeaker;                // Response method ... .

- (void)sipInterface:(SipInterface*)interface speakerEnable:(BOOL)enable;

- (void)sipInterfaceError:(SipInterface*)interface reason:(SipInterfaceError)error;

@end


@interface SipInterface : NSObject

@property (nonatomic, assign) id<SipInterfaceDelegate>  delegate;

@property (nonatomic, strong) NSString*                 realm;
@property (nonatomic, strong) NSString*                 server;
@property (nonatomic, strong) NSString*                 username;
@property (nonatomic, strong) NSString*                 password;

@property (nonatomic, assign) BOOL                      louderVolume;

@property (nonatomic, readonly) SipInterfaceRegistered  registered;


- (id)initWithRealm:(NSString*)realm server:(NSString*)server username:(NSString*)username password:(NSString*)password;

- (void)restart;

- (BOOL)makeCall:(Call*)call tones:(NSDictionary*)tones;

- (void)hangupCall:(Call*)call reason:(NSString*)reason;

- (void)setCall:(Call*)call onMute:(BOOL)onMute;

- (void)setCall:(Call*)call onHold:(BOOL)onHold;

- (void)setOnSpeaker:(BOOL)onSpeaker;

@end
