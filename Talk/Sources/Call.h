//
//  Call.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/12/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "PhoneNumber.h"
#import "SipInterface.h"


typedef enum
{
    CallStateNone,
    CallStateCalling,
    CallStateRinging,
    CallStateConnecting,
    CallStateConnected,
    CallStateEnding,
    CallStateEnded,
    CallStateCancelled,
    CallStateBusy,
    CallStateDeclined,
    CallStateNotAllowed,
    CallStateFailed,
} CallState;


typedef enum
{
    CallDirectionIncoming,
    CallDirectionOutgoing,
} CallDirection;


typedef enum
{
    CallNetworkInternet,
    CallNetworkMobile,
    CallNetworkCallback,
} CallNetwork;


typedef enum
{
    CallLegNone,
    CallLegCallback,
    CallLegOutgoing,
} CallLeg;


@interface Call : NSObject

@property (nonatomic, strong, readonly) PhoneNumber*    phoneNumber;
@property (nonatomic, strong) NSString*                 calledNumber;       // Actual outgoing number (not number chosen/entered).
@property (nonatomic, strong) NSString*                 identityNumber;     // Number form/on which call is made/received.
@property (nonatomic, assign) BOOL                      showCallerId;
@property (nonatomic, strong) NSString*                 contactName;
@property (nonatomic, strong) NSString*                 contactId;          // The ABRecordID (which is int32_t) as string.
@property (nonatomic, strong, readonly) NSDate*         beginDate;
@property (nonatomic, strong, readonly) NSDate*         connectDate;
@property (nonatomic, strong, readonly) NSDate*         endDate;
@property (nonatomic, assign) CallState                 state;              // With callback, this is the state for the current leg only.
@property (nonatomic, assign) CallLeg                   leg;                // This is the current leg and amends the state.
@property (nonatomic, assign) CallDirection             direction;
@property (nonatomic, assign) CallNetwork               network;
@property (nonatomic, assign) BOOL                      readyForCleanup;
@property (nonatomic, assign) BOOL                      userInformedAboutFailure;

// SipInterface specifics.
@property (nonatomic, assign) int                       callId;
@property (nonatomic, assign) BOOL                      ringbackToneOn;
@property (nonatomic, assign) BOOL                      busyToneOn;
@property (nonatomic, assign) BOOL                      congestionToneOn;
@property (nonatomic, assign) BOOL                      ringToneOn;
@property (nonatomic, assign) SipInterfaceCallFailed    sipInterfaceFailure;
@property (nonatomic, assign) int                       sipFailedStatus;


- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction;

- (NSString*)stateString;

- (NSString*)failedString;

@end
