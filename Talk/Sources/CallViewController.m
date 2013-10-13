//
//  CallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 26/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>   //### For SoloAmbient
#import "CallViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "CallMessageView.h"
#import "NSTimer+Blocks.h"
#import "DtmfPlayer.h"
#import "NSObject+Blocks.h"


@interface CallViewController ()
{
    CallOptionsView* callOptionsView;
    CallKeypadView*  callKeypadView;
    CallMessageView* callMessageView;
    NSTimer*         durationTimer;
    int              duration;
}

@end


@implementation CallViewController

- (id)initWithCall:(Call*)call
{
    if (self = [super init])
    {
        _calls = [NSMutableArray array];
        [self addCall:call];

        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }

    return self;
}


- (void)dealloc
{
    [[UIDevice currentDevice] setProximityMonitoringEnabled:NO];
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    Call*   call = [self.calls lastObject];
    self.infoLabel.text   = [call.phoneNumber infoString];
    self.calleeLabel.text = [call.phoneNumber asYouTypeFormat];
    self.statusLabel.text = [call stateString];
    self.dtmfLabel.text   = @"";

    CGRect  frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    callOptionsView = [[CallOptionsView alloc] initWithFrame:frame];
    callKeypadView  = [[CallKeypadView  alloc] initWithFrame:frame];
    callMessageView = [[CallMessageView alloc] initWithFrame:frame];

    callOptionsView.delegate = self;
    callKeypadView.delegate  = self;

    callOptionsView.muteButton.enabled   = NO;
    callOptionsView.keypadButton.enabled = NO;
    callOptionsView.addButton.enabled    = NO;
    callOptionsView.holdButton.enabled   = NO;

    [self.centerRootView addSubview:callOptionsView];
}



#pragma mark - Options Delegate

- (void)callOptionsViewPressedMuteKey:(CallOptionsView*)optionsView
{
    [[CallManager sharedManager] setCall:[self.calls lastObject] onMute:!optionsView.onMute];   //### Should be active call.
}


- (void)callOptionsViewPressedKeypadKey:(CallOptionsView*)optionsView
{
    [UIView transitionFromView:callOptionsView
                        toView:callKeypadView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    completion:nil];
    
    [self showSmallEndButton];
    
    [self animateView:self.hideButton  fromHidden:YES toHidden:NO];
    [self animateView:self.retryButton fromHidden:YES toHidden:YES];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:YES];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:YES];
    [self animateView:self.statusLabel fromHidden:YES toHidden:YES];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:NO];
}


- (void)callOptionsViewPressedSpeakerKey:(CallOptionsView*)optionsView
{
    [[CallManager sharedManager] setOnSpeaker:!optionsView.onSpeaker];
}


- (void)callOptionsViewPressedAddKey:(CallOptionsView*)optionsView
{
    
}


- (void)callOptionsViewPressedHoldKey:(CallOptionsView*)optionsView
{    
    [[CallManager sharedManager] setCall:[self.calls lastObject] onHold:!optionsView.onHold];  //### Should be active call.
}


- (void)callOptionsViewPressedGroupsKey:(CallOptionsView*)optionsView
{

}


#pragma mark - Keypad Delegate

- (void)callKeypadView:(CallKeypadView*)keypadView pressedDigitKey:(KeypadKey)key
{
    self.dtmfLabel.text = [NSString stringWithFormat:@"%@%c", self.dtmfLabel.text, key];

    [[DtmfPlayer sharedPlayer] playCharacter:key atVolume:1.5f];

    [[CallManager sharedManager] sendCall:[self.calls lastObject] dtmfCharacter:key];
}


#pragma mark - Call Delegate

- (void)call:(Call*)call didUpdateState:(CallState)state
{
    self.statusLabel.text = [call stateString];
}


#pragma Message View

- (void)showMessageViewWithText:(NSString*)text
{
    [UIView transitionFromView:[self.centerRootView.subviews lastObject]
                        toView:callMessageView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    completion:nil];

    callMessageView.label.text = text;

    [self showSmallEndButton];

    [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
    [self animateView:self.retryButton fromHidden:YES toHidden:NO];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:NO];
    [self animateView:self.statusLabel fromHidden:YES toHidden:NO];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
}


#pragma mark - Button Actions

- (IBAction)endAction:(id)sender
{
    Call* call = [self.calls lastObject];   //### Should be active call.

    self.endButton.enabled   = NO;
    self.retryButton.enabled = NO;
    self.hideButton.enabled  = NO;

    call.readyForCleanup = YES;
    [[CallManager sharedManager] endCall:call];
}


- (IBAction)hideAction:(id)sender
{
    [UIView transitionFromView:callKeypadView
                        toView:callOptionsView
                      duration:TransitionDuration
                       options:UIViewAnimationOptionTransitionFlipFromLeft
                    completion:nil];

    [self showLargeEndButton];

    [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
    [self animateView:self.retryButton fromHidden:YES toHidden:YES];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:NO];
    [self animateView:self.statusLabel fromHidden:YES toHidden:NO];
    [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
}


- (IBAction)retryAction:(id)sender
{
    if ([[CallManager sharedManager] retryCall:[self.calls lastObject]] == YES)
    {
        [UIView transitionFromView:callMessageView
                            toView:callOptionsView
                          duration:TransitionDuration
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];

        [self showLargeEndButton];

        [self animateView:self.hideButton  fromHidden:YES toHidden:YES];
        [self animateView:self.retryButton fromHidden:YES toHidden:YES];
        [self animateView:self.infoLabel   fromHidden:NO  toHidden:NO];
        [self animateView:self.calleeLabel fromHidden:NO  toHidden:NO];
        [self animateView:self.statusLabel fromHidden:NO  toHidden:NO];
        [self animateView:self.dtmfLabel   fromHidden:YES toHidden:YES];
    }
}


#pragma mark - Public API

- (void)addCall:(Call*)call
{
    [self.calls addObject:call];
}


- (void)endCall:(Call*)call
{
#warning Move this to SipInterface, and do when last call in array has been ended.
    [Common dispatchAfterInterval:0.5 onMain:^
    {
        // Delay this (which route backs to speaker) to prevent 'noisy click' during brief moment
        // that PISIP has not shutdown audio yet.  Also prevents Speaker option button to light up
        // on CallView just before it disappears.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategorySoloAmbient error:nil];
    }];
}


- (void)updateCallCalling:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallRinging:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallConnecting:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallConnected:(Call*)call
{
    self.statusLabel.text = [call stateString];

    call.readyForCleanup = YES;

    callOptionsView.muteButton.enabled   = YES;
    callOptionsView.keypadButton.enabled = YES;
    callOptionsView.addButton.enabled    = NO;
    callOptionsView.holdButton.enabled   = YES;

    duration = 1;
    durationTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 repeats:YES block:^
    {
        if (duration < 3600)
        {
            self.statusLabel.text = [NSString stringWithFormat:@"%02d:%02d",
                                     (duration % 3600) / 60,
                                     duration % 60];
        }
        else
        {
            self.statusLabel.text = [NSString stringWithFormat:@"%d:%02d:%02d",
                                     duration / 3600,
                                     (duration % 3600) / 60,
                                     duration % 60];
        }

        duration++;
    }];
}


- (void)updateCallEnding:(Call*)call
{
    [durationTimer invalidate];
    durationTimer = nil;

    self.statusLabel.text = [call stateString];

    callOptionsView.muteButton.enabled    = NO;
    callOptionsView.keypadButton.enabled  = NO;
    callOptionsView.speakerButton.enabled = NO;
    callOptionsView.addButton.enabled     = NO;
    callOptionsView.holdButton.enabled    = NO;
    callOptionsView.groupsButton.enabled  = NO;
}


- (void)updateCallEnded:(Call*)call
{
    [durationTimer invalidate];
    durationTimer = nil;

    [self endCall:call];
}


- (void)updateCallBusy:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallDeclined:(Call*)call
{
    self.statusLabel.text = [call stateString];
}


- (void)updateCallFailed:(Call*)call message:(NSString*)message;
{
    if (call == nil)
    {
        NSLog(@"//### Call is nil (failed)");
        Call* call = [[Call alloc] init];
        call.state = CallStateFailed;
    }

    [durationTimer invalidate];
    durationTimer = nil;

    self.statusLabel.text = [call stateString];
    [self showMessageViewWithText:message];
}


- (void)setCall:(Call*)call onMute:(BOOL)onMute
{
#warning Only update when current call.
    callOptionsView.onMute = onMute;
}


- (void)setCall:(Call*)call onHold:(BOOL)onHold
{
#warning Only update when current call.
#warning Set Call onHold variable -  also for others.
    callOptionsView.onHold = onHold;
}


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    callOptionsView.onSpeaker = onSpeaker;
    [[UIDevice currentDevice] setProximityMonitoringEnabled:!onSpeaker];
}


- (void)setSpeakerEnable:(BOOL)enable
{
    callOptionsView.speakerButton.enabled = enable;
}

@end
