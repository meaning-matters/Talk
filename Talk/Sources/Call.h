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
    CallStateBeginning,
    CallStateCalling,
    CallStateDeclined,
    CallStateBusy,
    CallStateRinging,
    CallStateConnected,
    CallStateEnding,
    CallStateCanceled,
    CallStateHungup,
    CallStateFailed,
} CallState;


typedef enum
{
    CallDirectionOut,
    CallDirectionIn,
} CallDirection;


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
@property (nonatomic, assign) ABRecordID                abRecordId;
@property (nonatomic, readonly) NSDate*                 beginDate;
@property (nonatomic, readonly) NSDate*                 connectDate;
@property (nonatomic, readonly) NSDate*                 endDate;
@property (nonatomic, readonly) CallState               state;
@property (nonatomic, assign) CallDirection             direction;


- (id)initWithPhoneNumber:(PhoneNumber*)phoneNumber direction:(CallDirection)direction;

- (void)end;

- (NSString*)stateString;

- (NSString*)failedString;

@end
