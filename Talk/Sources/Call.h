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


typedef enum
{
    CallStateNone,
    CallStateCalling,
    CallStateRinging,
    CallStateConnecting,
    CallStateConnected,
    CallStateEnding,
    CallStateEnded,
    CallStateCanceled,
    CallStateBusy,
    CallStateDeclined,
    CallStateNotAllowed,
    CallStateFailed,
} CallState;


typedef enum
{
    CallDirectionOut,
    CallDirectionIn,
} CallDirection;


typedef enum
{
    CallNetworkInternet,
    CallNetworkMobile,
} CallNetwork;


@class Call;

@protocol CallExternalDelegate <NSObject>

- (void)call:(Call*)call didUpdateState:(CallState)state;

@end


@protocol CallInternalDelegate <NSObject>

@end


@interface Call : NSObject

@property (nonatomic, assign) id<CallExternalDelegate>  externalDelegate;   // UI related.
@property (nonatomic, assign) id<CallInternalDelegate>  internalDelegate;   // SIP related.
@property (nonatomic, readonly) PhoneNumber*            phoneNumber;
@property (nonatomic, readonly) NSString*               calledNumber;
@property (nonatomic, strong) NSString*                 identityNumber;     // Number form/on which call is made/received.
@property (nonatomic, assign) ABRecordID                abRecordId;
@property (nonatomic, readonly) NSDate*                 beginDate;
@property (nonatomic, readonly) NSDate*                 connectDate;
@property (nonatomic, readonly) NSDate*                 endDate;
@property (nonatomic, assign) CallState                 state;
@property (nonatomic, assign) CallDirection             direction;
@property (nonatomic, assign) CallNetwork               network;

// SipInterface specifics.
@property (nonatomic, assign) int                       callId;
@property (nonatomic, assign) BOOL                      ringbackToneOn;
@property (nonatomic, assign) BOOL                      busyToneOn;
@property (nonatomic, assign) BOOL                      congestionToneOn;
@property (nonatomic, assign) BOOL                      ringToneOn;


- (id)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction;

- (void)end;

- (NSString*)stateString;

- (NSString*)failedString;

@end
