//
//  CallbackViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/10/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "CallbackViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "CallMessageView.h"
#import "NSTimer+Blocks.h"
#import "NSObject+Blocks.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "Strings.h"
#import "Settings.h"
#import "NetworkStatus.h"


@interface CallbackViewController ()
{
    CallMessageView* callMessageView;
    NSTimer*         durationTimer;
    int              duration;
    PhoneNumber*     callerPhoneNumber;
    NSMutableArray*  notificationObservers;
    BOOL             callbackPending;
}

@end


@implementation CallbackViewController

- (id)initWithCall:(Call*)call
{
    if (self = [super init])
    {
        self.call = call;

        notificationObservers = [NSMutableArray array];
        [self addNotificationObservers];

        [UIApplication sharedApplication].idleTimerDisabled = YES;
    }

    return self;
}


- (void)dealloc
{
    [self removeNotificationObservers];

    [UIApplication sharedApplication].idleTimerDisabled = NO;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.infoLabel.text   = [self.call.phoneNumber infoString];
    self.calleeLabel.text = [self.call.phoneNumber asYouTypeFormat];
    self.statusLabel.text = [self.call stateString];

    [self.calleeLabel setFont:[Common phoneFontOfSize:38]];

    CGRect  frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    callMessageView = [[CallMessageView alloc] initWithFrame:frame];

    [self.centerRootView addSubview:callMessageView];

    [self startCallback];
}


- (void)startCallback
{
    self.statusLabel.text      = NSLocalizedStringWithDefaultValue(@"Callback RequestingText", nil, [NSBundle mainBundle],
                                                                   @"requesting...",
                                                                   @"Text ...\n"
                                                                   @"[N lines]");
    callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback StartMessage", nil, [NSBundle mainBundle],
                                                                   @"A request to call you back is being sent to our "
                                                                   @"server via internet.\n\nPlease wait.",
                                                                   @"Alert message: ...\n"
                                                                   @"[N lines]");

    callerPhoneNumber = [[PhoneNumber alloc] initWithNumber:self.call.identityNumber];
    callbackPending   = YES;
    [[WebClient sharedClient] initiateCallbackForCallee:self.call.phoneNumber
                                                 caller:callerPhoneNumber
                                               identity:[[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].callbackCallerId]
                                                privacy:![Settings sharedSettings].showCallerId
                                                  reply:^(WebClientStatus status)
    {
        if (status == WebClientStatusOk)
        {
            self.call.state       = CallStateCalling;
            self.statusLabel.text = [self.call stateString];

            callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback ProgressMessage", nil, [NSBundle mainBundle],
                                                                           @"Your number is being called.\n\nAfter you answer, "
                                                                           @"the person you're trying to reach will be "
                                                                           @"called automatically.\n\n"
                                                                           @"Then, wait until you're connected.",
                                                                           @"Alert message: ...\n"
                                                                           @"[N lines]");

            [self checkCallbackState];
        }
        else
        {
            callbackPending = NO;

            self.call.state       = CallStateFailed;
            self.statusLabel.text = [self.call stateString];

            NSString* format = NSLocalizedStringWithDefaultValue(@"Callback RequestFailedMessage", nil, [NSBundle mainBundle],
                                                                 @"Sending the callback request failed: %@.\n\n"
                                                                 @"You can end this callback, or retry.",
                                                                 @"Alert message: ...\n"
                                                                 @"[N lines]");
            callMessageView.label.text = [NSString stringWithFormat:format, [WebClient localizedStringForStatus:status]];

            [self showRetry];
        }
    }];
}


- (void)checkCallbackState
{
    if (self.call.readyForCleanup == YES)
    {
        return;
    }

    [[WebClient sharedClient] retrieveCallbackStateForCaller:callerPhoneNumber
                                                       reply:^(WebClientStatus status, CallState state)
    {
        if (status == WebClientStatusOk)
        {
            self.call.state       = state;
            self.statusLabel.text = [self.call stateString];

            BOOL            checkState;
            switch (state)
            {
                case CallStateCalling:
                    callbackPending = YES;
                    checkState      = YES;
                    break;

                case CallStateRinging:
                    callbackPending = YES;
                    checkState      = YES;
                    break;

                case CallStateConnected:
                    callbackPending = YES;
                    checkState      = YES;
                    callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback ConnectedMessage", nil, [NSBundle mainBundle],
                                                                                   @"The party you were trying to reach "
                                                                                   @"picked up the phone.\n\nIf you declined our call, or "
                                                                                   @"answered another call, your callee got connected to "
                                                                                   @"your voicemail.",
                                                                                   @"Alert message: ...\n"
                                                                                   @"[N lines]");
                    break;

                case CallStateEnded:
                {
                    callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback EndedMessage", nil, [NSBundle mainBundle],
                                                                                   @"The call has ended.",
                                                                                   @"Alert message: ...\n"
                                                                                   @"[N lines]");
                    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                    dispatch_after(when, dispatch_get_main_queue(), ^
                    {
                        [self endAction:nil];
                    });

                    callbackPending = NO;
                    checkState      = NO;
                    break;
                }

                case CallStateNone:
                    checkState = YES;
                    NSLog(@"Got spurious CallStateNone!");
                    break;

                default:
                    checkState = YES;
                    break;
            }

            NSLog(@"CallState = %d", state);

            if (checkState == YES)
            {
                [Common dispatchAfterInterval:1.0 onMain:^
                {
                    [self checkCallbackState];
                }];
            }
        }
        else
        {
            // Keep trying.
            [Common dispatchAfterInterval:1.0 onMain:^
            {
                [self checkCallbackState];
            }];
        }
    }];
}


#pragma mark - Button Actions

- (IBAction)endAction:(id)sender
{
    self.endButton.enabled    = NO;
    self.call.readyForCleanup = YES;

    [[WebClient sharedClient] cancelAllInitiateCallback];
    [[WebClient sharedClient] cancelAllRetrieveCallbackStateForCaller:callerPhoneNumber];
    [[WebClient sharedClient] stopCallbackForCaller:callerPhoneNumber reply:^(WebClientStatus status)
    {
        if (status != WebClientStatusOk && callbackPending == YES)
        {
            NSString* title   = NSLocalizedStringWithDefaultValue(@"Callback EndFailedTitle", nil, [NSBundle mainBundle],
                                                                  @"Ending Callback Failed",
                                                                  @"Alert title: ...\n"
                                                                  @"[1 line]");
            NSString* message = NSLocalizedStringWithDefaultValue(@"Callback EndFailedMessage", nil, [NSBundle mainBundle],
                                                                  @"There seems to be a callback pending, but ending "
                                                                  @"it failed: %@.\n\n"
                                                                  @"This may mean that your callee got connected to "
                                                                  @"your voicemail.",
                                                                  @"Alert message: ...\n"
                                                                  @"[N lines]");
            message = [NSString stringWithFormat:message, [WebClient localizedStringForStatus:status]];

            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];

    [[CallManager sharedManager] endCall:self.call];
}


- (IBAction)retryAction:(id)sender
{
    [self showLargeEndButton];

    [self animateView:self.retryButton fromHidden:YES toHidden:YES];
    [self animateView:self.infoLabel   fromHidden:NO  toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:NO  toHidden:NO];
    [self animateView:self.statusLabel fromHidden:NO  toHidden:NO];

    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(TransitionDuration * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^
    {
        [self startCallback];
    });
}


- (void)showRetry
{
    [self showSmallEndButton];

    [self animateView:self.retryButton fromHidden:YES toHidden:NO];
    [self animateView:self.infoLabel   fromHidden:YES toHidden:NO];
    [self animateView:self.calleeLabel fromHidden:YES toHidden:NO];
    [self animateView:self.statusLabel fromHidden:YES toHidden:NO];
}


#pragma mark - System Notification Handling

- (void)addNotificationObservers
{
    static NetworkStatusMobileCall previousStatus;
    static BOOL                    didBecomeActive;
    id                             observer;

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusMobileCallStateChangedNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* note)
    {
        NetworkStatusMobileCall status = [note.userInfo[@"status"] intValue];

        if (status == NetworkStatusMobileCallIncoming)
        {
            didBecomeActive = NO;
        }

        if (status          == NetworkStatusMobileCallDisconnected &&
            previousStatus  == NetworkStatusMobileCallIncoming &&
            didBecomeActive == YES)
        {
            // Decline detected.
            NSLog(@">>>>>>>>>>>>>>>>>>>>>>>>> DECLINE");

            self.statusLabel.text      = NSLocalizedStringWithDefaultValue(@"Callback DeclinedText", nil, [NSBundle mainBundle],
                                                                           @"declined",
                                                                           @"Text ...\n"
                                                                           @"[N lines]");
            callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback DeclinedMessage", nil, [NSBundle mainBundle],
                                                                           @"You declined an incoming call.\n\nPlease end "
                                                                           @"if you meant to decline our callback.  Or "
                                                                           @"otherwise, please retry.",
                                                                           @"Alert message: ...\n"
                                                                           @"[N lines]");

            [[WebClient sharedClient] cancelAllInitiateCallback];
            [[WebClient sharedClient] cancelAllRetrieveCallbackStateForCaller:callerPhoneNumber];
            [[WebClient sharedClient] stopCallbackForCaller:callerPhoneNumber reply:^(WebClientStatus status)
            {
                if (status == WebClientStatusOk)
                {
                    // Reset flag because user is now aware of issue.  (Would otherwise result in alert on tapping End button.)
                    callbackPending = NO;
                }
                else if (callbackPending == YES)
                {
                    NSString* format = NSLocalizedStringWithDefaultValue(@"Callback StopFailedMessage", nil, [NSBundle mainBundle],
                                                                         @"You declined an incoming call.  This resulted in an "
                                                                         @"automatic attempt to stop the callback.  But "
                                                                         @"this attempt failed: %@.\n\nThis may mean that "
                                                                         @"your callee got connected to your voicemail.",
                                                                         @"Alert message: ...\n"
                                                                         @"[N lines]");
                    callMessageView.label.text = [NSString stringWithFormat:format, [WebClient localizedStringForStatus:status]];
                }
            }];

            [self showRetry];
        }

        previousStatus = status;
    }];

    [notificationObservers addObject:observer];

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* note)
    {
        NSLog(@"--- UIApplicationWillResignActiveNotification");
        didBecomeActive = NO;
    }];

    [notificationObservers addObject:observer];

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* note)
    {
        NSLog(@"+++ UIApplicationDidBecomeActiveNotification");
        didBecomeActive = YES;
    }];

    [notificationObservers addObject:observer];
}


- (void)removeNotificationObservers
{
    for (id observer in notificationObservers)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

@end
