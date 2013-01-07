//
//  CallManager.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneNumber.h"
#import "Call.h"
#import "SipInterface.h"


@protocol CallManagerDelegate <NSObject>

//### Place methods in here that are now part of CallViewController.  like addCall, changedStateOfCall, ...

@end


@interface CallManager : NSObject <SipInterfaceDelegate>

@property (nonatomic, strong) NSMutableArray*   activeCalls;

+ (CallManager*)sharedManager;

- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity;

- (void)endCall:(Call*)call;

- (BOOL)callMobilePhoneNumber:(PhoneNumber*)phoneNumber;

- (void)setOnSpeaker:(BOOL)onSpeaker;

- (void)setCall:(Call*)call onHold:(BOOL)onHold;

@end
