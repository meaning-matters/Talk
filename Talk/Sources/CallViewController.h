//
//  CallViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CallOptionsView.h"
#import "CallKeypadView.h"
#import "Call.h"
#import "SipInterface.h"


@interface CallViewController : UIViewController <CallOptionsViewDelegate, CallKeypadViewDelegate>

@property (nonatomic, strong) NSMutableArray*               calls;

@property (nonatomic, strong) IBOutlet UIImageView*         backgroundImageView;
@property (nonatomic, strong) IBOutlet UIView*              topView;
@property (nonatomic, strong) IBOutlet UIView*              centerRootView;
@property (nonatomic, strong) IBOutlet UIView*              bottomView;

@property (nonatomic, strong) IBOutlet UIImageView*         topImageView;
@property (nonatomic, strong) IBOutlet UIImageView*         bottomImageView;

@property (nonatomic, strong) IBOutlet UILabel*             infoLabel;
@property (nonatomic, strong) IBOutlet UILabel*             calleeLabel;
@property (nonatomic, strong) IBOutlet UILabel*             dtmfLabel;
@property (nonatomic, strong) IBOutlet UILabel*             statusLabel;

@property (nonatomic, strong) IBOutlet UIButton*            endButton;
@property (nonatomic, strong) IBOutlet UIButton*            hideButton;


- (IBAction)endAction:(id)sender;

- (IBAction)hideAction:(id)sender;

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

- (void)updateCallNotAllowed:(Call*)call reason:(SipInterfaceCallNotAllowed)reason;

- (void)updateCallFailed:(Call*)call reason:(SipInterfaceCallFailed)reason;

- (void)setCall:(Call*)call onMute:(BOOL)onMute;

- (void)setCall:(Call*)call onHold:(BOOL)onHold;

- (void)setOnSpeaker:(BOOL)onSpeaker;

- (void)setSpeakerEnable:(BOOL)enable;

@end
