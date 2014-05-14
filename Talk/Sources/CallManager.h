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
#import "NBRecentContactEntry.h"


@protocol CallManagerDelegate <NSObject>

//### Place methods in here that are now part of CallViewController.  like addCall, changedStateOfCall, ...

@end


@interface CallManager : NSObject

@property (nonatomic, strong) NSMutableArray* activeCalls;


+ (CallManager*)sharedManager;

- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString*)contactId;

- (void)endCall:(Call*)call;

- (BOOL)retryCall:(Call*)call;

- (BOOL)callMobilePhoneNumber:(PhoneNumber*)phoneNumber;

- (void)setCall:(Call*)call onMute:(BOOL)onMute;

- (void)setCall:(Call*)call onHold:(BOOL)onHold;

- (void)setOnSpeaker:(BOOL)onSpeaker;

- (void)sendCall:(Call*)call dtmfCharacter:(char)character;

- (void)updateRecent:(NBRecentContactEntry*)recent withCall:(Call*)call;

- (void)updateRecent:(NBRecentContactEntry*)recent completion:(void (^)(BOOL success, BOOL ended))completion;

@end
