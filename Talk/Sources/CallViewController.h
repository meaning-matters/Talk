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


@class CallViewController;

//### Probably better when CallView calls CallManager, so this delegate can be removed.
//### Otherwise the CallManager becomes dependent on UI stuff; otherway arround is better.
@protocol CallViewControllerDelegate <NSObject>

- (void)callViewController:(CallViewController*)callViewController setOnMute:(BOOL)onMute;

- (void)callViewController:(CallViewController*)callViewController setOnSpeaker:(BOOL)onSpeaker;

- (void)callViewController:(CallViewController*)callViewController setOnHold:(BOOL)onHold;

- (void)callViewController:(CallViewController*)callViewController sendDtmfKey:(KeypadKey)key;

- (void)callViewControllerEndCall:(CallViewController*)callViewController;

@end


@interface CallViewController : UIViewController <CallOptionsViewDelegate, CallKeypadViewDelegate, CallExternalDelegate>

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

- (void)changedStateOfCall:(Call*)call;

- (void)endCall:(Call*)call;

@end
