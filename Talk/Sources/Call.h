//
//  Call.h
//  Talk
//
//  Created by Cornelis van der Bent on 04/12/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import "PhoneNumber.h"


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
    CallLegCallthru,
} CallLeg;


@interface Call : NSObject

@property (nonatomic, strong, readonly) PhoneNumber*    phoneNumber;
@property (nonatomic, strong) NSString*                 calledNumber;       // Actual outgoing number (not number chosen/entered).
@property (nonatomic, strong) NSString*                 identityNumber;     // Number form/on which call is made/received.
@property (nonatomic, assign) BOOL                      showCallerId;
@property (nonatomic, strong) NSString*                 contactName;
@property (nonatomic, strong) NSString*                 contactId;          // The ABRecordID (which is int32_t) as string.
@property (nonatomic, strong, readonly) NSDate*         beginDate;
@property (nonatomic, assign) int                       callbackDuration;
@property (nonatomic, assign) int                       callthruDuration;
@property (nonatomic, assign) float                     callbackCost;
@property (nonatomic, assign) float                     callthruCost;
@property (nonatomic, assign) CallState                 state;              // With callback, this is the state for the current leg only.
@property (nonatomic, assign) CallLeg                   leg;                // This is the current leg and amends the state.
@property (nonatomic, assign) CallDirection             direction;
@property (nonatomic, assign) CallNetwork               network;
@property (nonatomic, assign) BOOL                      readyForCleanup;
@property (nonatomic, assign) BOOL                      userInformedAboutFailure;
@property (nonatomic, strong) NSString*                 uuid;               // When not nil, the final durations & costs are not known.


- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction;

- (NSString*)stateString;

@end
