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
    NSMutableArray*  notificationObservers;
    BOOL             callbackPending;
    NSString*        uuid;              // Needed to give endAction an independent copy from call's uuid.
}

@end


@implementation CallbackViewController

- (instancetype)initWithCall:(Call*)call
{
    if (self = [super init])
    {
        self.call = call;

        notificationObservers = [NSMutableArray array];
        [self addNotificationObservers];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.infoLabel.text   = [self.call.phoneNumber infoString];
    self.calleeLabel.text = self.call.contactId ? self.call.contactName : [self.call.phoneNumber asYouTypeFormat];
    self.statusLabel.text = [self.call stateString];

    [self.calleeLabel setFont:[Common phoneFontOfSize:38]];

    CGRect  frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    callMessageView = [[CallMessageView alloc] initWithFrame:frame];

    [self.centerRootView addSubview:callMessageView];

    [self startCallback];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self removeNotificationObservers]; // Can't be done in dealloc, because the observers prevent dealloc from being called.
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

    PhoneNumber* callbackPhoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].callbackE164];
    PhoneNumber* callerIdPhoneNumber = [[PhoneNumber alloc] initWithNumber:self.call.identityNumber];
    callbackPending = YES;
    [[WebClient sharedClient] initiateCallbackForCallee:self.call.phoneNumber
                                                 caller:callbackPhoneNumber
                                               identity:callerIdPhoneNumber
                                                privacy:![Settings sharedSettings].showCallerId
                                                  reply:^(NSError* error, NSString* theUuid)
    {
        if (error == nil)
        {
            self.call.state       = CallStateCalling;
            self.call.uuid        = theUuid;
            uuid                  = theUuid;
            self.statusLabel.text = [self.call stateString];

            callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback ProgressMessage", nil,
                                                                           [NSBundle mainBundle],
                                                                           @"Your number is being called.\n\nAfter you "
                                                                           @"answer, the person you're trying to reach "
                                                                           @"will be called automatically.\n\n"
                                                                           @"Then, wait until you're connected.",
                                                                           @"Alert message: ...\n"
                                                                           @"[N lines]");

            [self checkCallbackState];
        }
        else
        {
            callbackPending = NO;

            self.call.state = CallStateFailed;

            if (error.code == WebClientStatusFailNoCredit)
            {
                self.statusLabel.text      = NSLocalizedStringWithDefaultValue(@"Callback NoCreditStatusText", nil,
                                                                               [NSBundle mainBundle],
                                                                               @"no credit",
                                                                               @"Call status text\n"
                                                                               @"[1 line]");
                callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback NoCreditMessage", nil,
                                                                               [NSBundle mainBundle],
                                                                               @"The callback failed because you've run "
                                                                               @"out of credit.\n\nBuy more on the "
                                                                               @"Credit tab.",
                                                                               @"Alert message\n"
                                                                               @"[N lines]");
            }
            else if (error.code == WebClientStatusFailUnknownCallerId ||
                     error.code == WebClientStatusFailUnknownVerifiedNumber ||
                     error.code == WebClientStatusFailUnknownBothE164)
            {
                self.statusLabel.text = [self.call stateString];

                NSString* format = NSLocalizedStringWithDefaultValue(@"Callback UnknownNumberMessage", nil,
                                                                     [NSBundle mainBundle],
                                                                     @"Starting callback failed: %@\n\n"
                                                                     @"Please synchronize your account data (via Settings).",
                                                                     @"Alert message: ...\n"
                                                                     @"[N lines]");
                callMessageView.label.text = [NSString stringWithFormat:format, error.localizedDescription];
            }
            else
            {
                self.statusLabel.text = [self.call stateString];

                NSString* format = NSLocalizedStringWithDefaultValue(@"Callback RequestFailedMessage", nil,
                                                                     [NSBundle mainBundle],
                                                                     @"Sending the callback request failed: %@\n\n"
                                                                     @"You can end this callback, or retry.",
                                                                     @"Alert message: ...\n"
                                                                     @"[N lines]");
                callMessageView.label.text = [NSString stringWithFormat:format, error.localizedDescription];
                
                [self showRetry];
            }
        }
    }];
}


- (void)checkCallbackState
{
    if (self.call.readyForCleanup == YES || callbackPending == NO)
    {
        return;
    }

    [[WebClient sharedClient] retrieveCallbackStateForUuid:self.call.uuid
                                                     reply:^(NSError*  error,
                                                             CallState state,
                                                             CallLeg   leg,
                                                             int       callbackDuration,
                                                             int       outgoingDuration,
                                                             float     callbackCost,
                                                             float     outgoingCost)
    {
        if (error == nil)
        {
            self.call.state            = (state == CallStateNone) ? self.call.state : state;
            self.call.leg              = (leg   == CallLegNone)   ? self.call.leg   : leg;
            self.call.callbackDuration = callbackDuration;
            self.call.outgoingDuration = outgoingDuration;
            self.call.callbackCost     = callbackCost;
            self.call.outgoingCost     = outgoingCost;
            self.statusLabel.text      = [self.call stateString];

            NSString* text = nil;
            BOOL      checkState;
            switch (state)
            {
                case CallStateCalling:
                    callbackPending = YES;
                    checkState      = YES;
                    if (leg == CallLegOutgoing)
                    {
                        text = NSLocalizedStringWithDefaultValue(@"Callback CallingMessage", nil, [NSBundle mainBundle],
                                                                 @"Now, the person you're trying to reach is being "
                                                                 @"called.\n\nWhen answered, you'll be connected ",
                                                                 @"Alert message: ...\n"
                                                                 @"[N lines]");
                    }
                    break;

                case CallStateRinging:
                    callbackPending = YES;
                    checkState      = YES;
                    break;

                case CallStateConnected:
                    callbackPending = YES;
                    checkState      = YES;
                    if (leg == CallLegCallback)
                    {
                        text = NSLocalizedStringWithDefaultValue(@"Callback CallbackConnectedMessage", nil, [NSBundle mainBundle],
                                                                 @"Your phone answered the callback call.\n\n"
                                                                 @"If this is not you, the person you're trying to"
                                                                 @"reach is probably going to be connected to your "
                                                                 @"callback number's voicemail.",
                                                                 @"Alert message: ...\n"
                                                                 @"[N lines]");
                    }

                    if (leg == CallLegOutgoing)
                    {
                        text = NSLocalizedStringWithDefaultValue(@"Callback OutgoingConnectedMessage", nil, [NSBundle mainBundle],
                                                                 @"The person you were trying to reach answered.\n\n"
                                                                 @"If you're not in the call, the person you're trying to"
                                                                 @"reach is probably connected to your callback number's "
                                                                 @"voicemail.",
                                                                 @"Alert message: ...\n"
                                                                 @"[N lines]");
                    }
                    break;

                case CallStateEnded:
                {
                    if (callbackPending == YES)
                    {
                        text = NSLocalizedStringWithDefaultValue(@"Callback EndedMessage", nil, [NSBundle mainBundle],
                                                                 @"The call has ended.",
                                                                 @"Alert message: ...\n"
                                                                 @"[N lines]");
                        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                        dispatch_after(when, dispatch_get_main_queue(), ^
                        {
                            //self.call.uuid = nil;
                            [self endAction:nil];
                        });
                    }

                    callbackPending = NO;
                    checkState      = NO;
                    break;
                }

                default:
                    checkState = YES;
                    break;
            }

            if (text != nil)
            {
                callMessageView.label.text = text;
            }

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
            NSLog(@"Callback State: %@.", [error localizedDescription]);

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
    if (self.call.uuid != nil)
    {
        [[WebClient sharedClient] cancelAllRetrieveCallbackStateForUuid:self.call.uuid];
    }

    if (callbackPending == YES)
    {
        [[WebClient sharedClient] stopCallbackForUuid:uuid reply:^(NSError* error)
        {
            if (error != nil && callbackPending == YES)
            {
                NSString* title   = NSLocalizedStringWithDefaultValue(@"Callback EndFailedTitle", nil, [NSBundle mainBundle],
                                                                      @"Ending Callback Failed",
                                                                      @"Alert title: ...\n"
                                                                      @"[1 line]");
                NSString* message = NSLocalizedStringWithDefaultValue(@"Callback EndFailedMessage", nil, [NSBundle mainBundle],
                                                                      @"There seems to be a callback pending, but ending "
                                                                      @"it failed: %@\n\n"
                                                                      @"This may mean that your callee got connected to "
                                                                      @"your voicemail.",
                                                                      @"Alert message: ...\n"
                                                                      @"[N lines]");
                message = [NSString stringWithFormat:message, error.localizedDescription];

                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:nil
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    }

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
            self.statusLabel.text      = NSLocalizedStringWithDefaultValue(@"Callback DeclinedText", nil, [NSBundle mainBundle],
                                                                           @"declined",
                                                                           @"Text ...\n"
                                                                           @"[N lines]");
            callMessageView.label.text = NSLocalizedStringWithDefaultValue(@"Callback DeclinedMessage", nil, [NSBundle mainBundle],
                                                                           @"You declined an incoming call.\n\n"
                                                                           @"If you declined the callback, please end. "
                                                                           @"If you declined another call, you can retry.",
                                                                           @"Alert message: ...\n"
                                                                           @"[N lines]");

            [[WebClient sharedClient] cancelAllInitiateCallback];
            if (self.call.uuid != nil)
            {
                [[WebClient sharedClient] cancelAllRetrieveCallbackStateForUuid:self.call.uuid];
            }

            if (callbackPending == YES)
            {
                [[WebClient sharedClient] stopCallbackForUuid:self.call.uuid reply:^(NSError* error)
                {
                    if (error == nil)
                    {
                        // Reset flag because user is now aware of issue.  (Would otherwise result in alert on tapping End button.)
                        callbackPending = NO;

                        [self showRetry];
                    }
                    else if (callbackPending == YES)
                    {
                        NSString* format;
                        format = NSLocalizedStringWithDefaultValue(@"Callback StopFailedMessage", nil, [NSBundle mainBundle],
                                                                   @"You declined an incoming call. This resulted in an "
                                                                   @"automatic attempt to stop the callback. But "
                                                                   @"this attempt failed: %@\n\nThis may mean that "
                                                                   @"your callee got connected to your voicemail.",
                                                                   @"Alert message: ...\n"
                                                                   @"[N lines]");
                        callMessageView.label.text = [NSString stringWithFormat:format, error.localizedDescription];

                        // Don't show Retry here, because something failed; may otherwise cause multiple Callbacks.
                    }
                }];
            }
            else
            {
                [self showRetry];
            }
        }

        previousStatus = status;
    }];

    [notificationObservers addObject:observer];

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* note)
    {
        didBecomeActive = NO;
    }];

    [notificationObservers addObject:observer];

    observer = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* note)
    {
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

    [notificationObservers removeAllObjects];   // Without this, dealloc will not be called.
}

@end
