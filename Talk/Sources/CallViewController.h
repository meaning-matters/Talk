//
//  CallViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallBaseViewController.h"
#import "CallOptionsView.h"
#import "CallKeypadView.h"
#import "Call.h"


@interface CallViewController : CallBaseViewController <CallOptionsViewDelegate, CallKeypadViewDelegate>

@property (nonatomic, strong) NSMutableArray* calls;

- (id)initWithCall:(Call*)call;

- (void)addCall:(Call*)call;

- (void)endCall:(Call*)call;

- (void)updateCallCalling:(Call*)call;

- (void)updateCallRinging:(Call*)call;

- (void)updateCallConnecting:(Call*)call;

- (void)updateCallConnected:(Call*)call;

- (void)updateCallEnding:(Call*)call;

- (void)updateCallEnded:(Call*)call;

- (void)updateCallBusy:(Call*)call;

- (void)updateCallDeclined:(Call*)call;

- (void)updateCallFailed:(Call*)call message:(NSString*)message;

- (void)setCall:(Call*)call onMute:(BOOL)onMute;

- (void)setCall:(Call*)call onHold:(BOOL)onHold;

- (void)setOnSpeaker:(BOOL)onSpeaker;

- (void)setSpeakerEnable:(BOOL)enable;

@end
