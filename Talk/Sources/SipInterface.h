//
//  SipInterface.h
//  Talk
//
//  Created by Cornelis van der Bent on 29/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pjsua-lib/pjsua.h>


typedef enum
{
    SipInterfaceRegisteredNo,
    SipInterfaceRegisteredYes,
    SipInterfaceRegisteredFailed
} SipInterfaceRegistered;


typedef enum
{
    SipInterfaceCallNotAllowedCountry,  // Unsupported country.
    SipInterfaceCallNotAllowedNumber,   // For premium number for example.
    SipInterfaceCallNotAllowedNoCredit, // No credit on server.
} SipInterfaceCallNotAllowed;


typedef enum
{
    SipInterfaceCallFailedNoServer,
    SipInterfaceCallFailedTooManyCalls,
    SipInterfaceCallFailedInternal,
} SipInterfaceCallFailed;

typedef enum
{
    SipInterfaceErrorInternal,      //### Think of more usefull ones.
} SipInterfaceError;


@class SipInterface;

@protocol SipInterfaceDelegate <NSObject>   // All these methods will be invoked on main thread.

- (void)sipInterfaceCallCalling:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallRinging:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallConnecting:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallConnected:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallEnding:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallEnded:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallBusy:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallDeclined:(SipInterface*)interface userData:(void*)userData;

- (void)sipInterfaceCallNotAllowed:(SipInterface*)interface userData:(void*)userData reason:(SipInterfaceCallNotAllowed)reason;

- (void)sipInterfaceCallFailed:(SipInterface*)interface userData:(void*)userData reason:(SipInterfaceCallFailed)reason;

- (void)sipInterfaceCallIncoming:(SipInterface*)interface number:(NSString*)number callId:(int)callId;  // callId must be passed back.

- (void)sipInterfaceCallIncomingCanceled:(SipInterface*)interface number:(NSString*)number;

- (void)sipInterfaceCallOnHold:(SipInterface*)interface userData:(void*)userData;   // Response method of requesting on-hold.

- (void)sipInterfaceCallOnMute:(SipInterface*)interface userData:(void*)userData;   // Response method ... .

- (void)sipInterfaceOnSpeaker:(SipInterface*)interface;                             // Response method ... .

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

// A pointer to Call object should passed as userData;
- (pjsua_call_id)callNumber:(NSString*)calledNumber
             identityNumber:(NSString*)identityNumber
                   userData:(void*)userData
                      tones:(NSDictionary*)tones;

- (void)hangupCall:(void*)userData reason:(NSString*)reason;

@end
