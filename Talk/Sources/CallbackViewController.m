//
//  CallbackViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/10/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "CallbackViewController.h"
#import "Common.h"
#import "CallManager.h"
#import "GraphicCallStateView.h"
#import "NSTimer+Blocks.h"
#import "NSObject+Blocks.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "Strings.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "PurchaseManager.h"


@interface CallbackViewController ()
{
    GraphicCallStateView* graphicStateView;
    NSTimer*              durationTimer;
    int                   duration;
    NSMutableArray*       notificationObservers;
    BOOL                  callbackPending;
    NSString*             uuid;              // Needed to give endAction an independent copy from call's uuid.
}

@property (nonatomic, strong) Call*         call;
@property (nonatomic, strong) PhoneData*    phone;
@property (nonatomic, strong) CallableData* callerId;

@end


@implementation CallbackViewController

- (instancetype)initWithCall:(Call*)call phone:(PhoneData*)phone callerId:(CallableData*)callerId
{
    if (self = [super init])
    {
        self.call     = call;
        self.phone    = phone;
        self.callerId = callerId;

        notificationObservers = [NSMutableArray array];
        [self addNotificationObservers];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGRect frame = CGRectMake(0, 0, self.centerRootView.frame.size.width, self.centerRootView.frame.size.height);
    graphicStateView = [[GraphicCallStateView alloc] initWithFrame:frame];
    graphicStateView.callingContact = (self.call.contactId != nil);

    [self.centerRootView addSubview:graphicStateView];

    self.infoLabel.text   = [self.call.phoneNumber infoString];
    self.calleeLabel.text = self.call.contactId ? self.call.contactName : [self.call.phoneNumber asYouTypeFormat];

    self.statusLabel.text            = [self statusString];
    graphicStateView.phoneLabel.text = [NSString stringWithFormat:@"%@: %@", [Strings phoneString],
                                                                                self.phone.name];
    if (self.call.showCallerId)
    {
        graphicStateView.callerIdLabel.text = [NSString stringWithFormat:@"%@: %@", [Strings callerIdString],
                                                                                    self.callerId.name];
    }
    else
    {
        NSString* string = [NSString stringWithFormat:@"%@: %@", [Strings callerIdString], [Strings hiddenString]];
        graphicStateView.callerIdLabel.attributedText = [self attributedString:string
                                                                     withColor:[Skinning valueColor]
                                                                     substring:[Strings hiddenString]];
    }

    graphicStateView.stateLabel.text    = [self stateString];

    [Common getCostForCallbackE164:[Settings sharedSettings].callbackE164
                      callthruE164:self.call.phoneNumber.e164Format
                        completion:^(NSString* costString)
    {
        NSString* infoString = [self.call.phoneNumber infoString];
        
        switch (((costString != nil) << 1) | ((infoString != nil) << 0))
        {
            case 0:
            {
                self.infoLabel.text = nil;
                break;
            }
            case 1:
            {
                self.infoLabel.text = [NSString stringWithFormat:@"%@", infoString];
                break;
            }
            case 2:
            {
                self.infoLabel.text = [NSString stringWithFormat:@"%@", costString];
                break;
            }
            case 3:
            {
                self.infoLabel.text = [NSString stringWithFormat:@"%@ - %@", infoString, costString];
                break;
            }
        }
    }];

    [self.calleeLabel setFont:[Common phoneFontOfSize:38]];

    [self startCallback];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self removeNotificationObservers]; // Can't be done in dealloc, because the observers prevent dealloc from being called.
}


#pragma mark - Helper

- (NSAttributedString*)attributedString:(NSString*)string withColor:(UIColor*)color substring:(NSString*)substring
{
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSRange range                               = [string rangeOfString:substring];
    [attributedString addAttribute:NSForegroundColorAttributeName value:color range:range];

    return attributedString;
}


#pragma mark - Logic

- (void)startCallback
{
    [graphicStateView startRequest];
    self.call.state = CallStateRequesting;

    self.statusLabel.text            = [self statusString];
    graphicStateView.stateLabel.text = [self stateString];

    PhoneNumber* callbackPhoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].callbackE164];
    PhoneNumber* callerIdPhoneNumber = [[PhoneNumber alloc] initWithNumber:self.call.identityNumber];
    callbackPending = YES;
    
    NSString* callthruE164 = [self.call.phoneNumber e164Format];
    if (![self.call.phoneNumber isValid] && ![callthruE164 hasPrefix:@"+"] && ![callthruE164 hasPrefix:@"00"])
    {
        // Not (common) international number; prefix it with Home Country calling code.
        NSString* callingCode = [Common callingCodeForCountry:[Settings sharedSettings].homeIsoCountryCode];
        callthruE164 = [@"+" stringByAppendingFormat:@"%@%@", callingCode, callthruE164];
    }
    
    [[WebClient sharedClient] initiateCallbackForCallbackE164:[callbackPhoneNumber e164Format]
                                                 callthruE164:callthruE164
                                                 identityE164:[callerIdPhoneNumber e164Format]
                                                      privacy:!self.call.showCallerId
                                                        reply:^(NSError* error, NSString* theUuid)
    {
        if (error == nil)
        {
            self.call.state = CallStateCalling;
            self.call.uuid  = theUuid;
            uuid            = theUuid;

            self.statusLabel.text            = [self statusString];
            graphicStateView.stateLabel.text = [self stateString];

            [graphicStateView startCallback];

            [self checkCallbackState];
        }
        else
        {
            callbackPending = NO;

            [graphicStateView stopRequest];

            self.call.state = CallStateFailed;

            if (error.code == WebStatusFailCreditInsufficient)
            {
                graphicStateView.stateLabel.text = NSLocalizedString(@"not enough credit", @"");
                self.statusLabel.text            = [self statusString];
            }
            else if (error.code == WebStatusFailE164IndentityUnknown ||
                     error.code == WebStatusFailE164CallbackUnknown  ||
                     error.code == WebStatusFailE164BothUnknown)
            {
                self.statusLabel.text            = [self statusString];
                graphicStateView.stateLabel.text = error.localizedDescription;
            }
            else
            {
                self.statusLabel.text            = [self statusString];
                graphicStateView.stateLabel.text = error.localizedDescription;

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

    // Don't poll the server when app is not active.
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive)
    {
        [Common dispatchAfterInterval:0.333 onMain:^
        {
            [self checkCallbackState];
        }];
        
        return;
    }
    
    [[WebClient sharedClient] retrieveCallbackStateForUuid:self.call.uuid
                                                     reply:^(NSError*  error,
                                                             CallState state,
                                                             CallLeg   leg,
                                                             int       callbackDuration,
                                                             int       callthruDuration,
                                                             float     callbackCost,
                                                             float     callthruCost)
    {
        if (error == nil)
        {
            self.call.state            = (state == CallStateNone) ? self.call.state : state;
            self.call.leg              = (leg   == CallLegNone)   ? self.call.leg   : leg;
            self.call.callbackDuration = callbackDuration;
            self.call.callthruDuration = callthruDuration;
            self.call.callbackCost     = callbackCost;
            self.call.callthruCost     = callthruCost;

            self.statusLabel.text            = [self statusString];
            graphicStateView.stateLabel.text = [self stateString];

            BOOL checkState;
            switch (state)
            {
                case CallStateCalling:
                case CallStateRinging:
                {
                    callbackPending = YES;
                    checkState      = YES;

                    if (leg == CallLegCallback)
                    {
                        [graphicStateView startCallback];
                    }

                    if (leg == CallLegCallthru)
                    {
                        [graphicStateView connectCallback];
                        [graphicStateView startCallthru];
                    }
                    break;
                }
                case CallStateConnected:
                {
                    callbackPending = YES;
                    checkState      = YES;
                    if (leg == CallLegCallback)
                    {
                        [graphicStateView connectCallback];
                    }

                    if (leg == CallLegCallthru)
                    {
                        [graphicStateView connectCallback];
                        [graphicStateView connectCallthru];
                    }
                    break;
                }
                case CallStateEnded:
                {
                    [graphicStateView stopCallback];
                    [graphicStateView stopCallthru];

                    if (callbackPending == YES)
                    {
                        dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
                        dispatch_after(when, dispatch_get_main_queue(), ^
                        {
                            [self endAction:nil];
                        });
                    }

                    callbackPending = NO;
                    checkState      = NO;
                    break;
                }
                default:
                {
                    checkState = YES;
                    break;
                }
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
            NBLog(@"Callback State: %@.", [error localizedDescription]);

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

    if (uuid != nil && callbackPending == YES)
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
            previousStatus  == NetworkStatusMobileCallIncoming     &&
            didBecomeActive == YES)
        {
            // Decline detected.
            self.statusLabel.text            = NSLocalizedString(@"declined", @"");
            graphicStateView.stateLabel.text = NSLocalizedString(@"You declined an incoming call. "
                                                                 @"If you declined the callback, please end. "
                                                                 @"If you declined another call, you can retry.",
                                                                 @"");

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
                        //##### TODO: This text is too long.
                        format = NSLocalizedStringWithDefaultValue(@"Callback StopFailedMessage", nil, [NSBundle mainBundle],
                                                                   @"You declined an incoming call. This resulted in an "
                                                                   @"automatic attempt to stop the callback. But "
                                                                   @"this attempt failed: %@\n\nThis may mean that "
                                                                   @"the person you're trying to reach got connected to "
                                                                   @"your voicemail.",
                                                                   @"Alert message: ...\n"
                                                                   @"[N lines]");
                        graphicStateView.stateLabel.text = [NSString stringWithFormat:format, error.localizedDescription];

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


#pragma mark - Status Strings

// Shown below the animation in center/call-state view; the state of call progress.
- (NSString*)stateString
{
    switch (self.call.state)
    {
        case CallStateNone:
        {
            return @"";
        }
        case CallStateRequesting:
        {
            return NSLocalizedString(@"requesting call...", @"");
        }
        case CallStateCalling:
        case CallStateRinging:
        case CallStateConnecting:
        {
            switch (self.call.leg)
            {
                case CallLegNone:     return NSLocalizedString(@"calling...", @"iOS string for phone call in progress");
                case CallLegCallback: return NSLocalizedString(@"calling your Phone...", @"");
                case CallLegCallthru: return NSLocalizedString(@"calling the other", @"");
            }
        }
        case CallStateConnected:
        {
            switch (self.call.leg)
            {
                case CallLegNone:     return NSLocalizedString(@"connected", @"");
                case CallLegCallback: return NSLocalizedString(@"your Phone answered\n(end if you're not connected, could be your voicemail)", @"");
                case CallLegCallthru: return NSLocalizedString(@"you're connected\nenjoy the call", @"");
            }
            break;
        }
        case CallStateEnding:
        case CallStateEnded:
        case CallStateCancelled:
        case CallStateBusy:
        case CallStateDeclined:
        {
            return @"";
        }
        case CallStateFailed:
        {
            return NSLocalizedString(@"failed #####ADD REASON", @"");
        }
    }
}


// Shown at top bar; the overal status of the call.
- (NSString*)statusString
{
    switch (self.call.state)
    {
        case CallStateNone:
        {
            return @"";
        }
        case CallStateRequesting:
        case CallStateCalling:
        case CallStateRinging:
        case CallStateConnecting:
        {
            return [self inProgressString];
        }
        case CallStateConnected:
        {
            switch (self.call.leg)
            {
                case CallLegNone:     return [self inProgressString];
                case CallLegCallback: return [self inProgressString];
                case CallLegCallthru: return [self durationStringWithSeconds:self.call.callthruDuration];
            }
        }
        case CallStateEnding:
        {
            return NSLocalizedString(@"ending...", @"");
        }
        case CallStateEnded:
        {
            return NSLocalizedString(@"ended", @"");
        }
        case CallStateCancelled:
        {
            return NSLocalizedString(@"cancelled", @"");
        }
        case CallStateBusy:
        {
            return NSLocalizedString(@"busy", @"");
        }
        case CallStateDeclined:
        {
            return NSLocalizedString(@"declined", @"");
        }
        case CallStateFailed:
        {
            return NSLocalizedString(@"failed", @"");
        }
    }
}


- (NSString*)durationStringWithSeconds:(int)seconds
{
    if (seconds < 3600)
    {
        return [NSString stringWithFormat:@"%02d:%02d", (seconds % 3600) / 60, seconds % 60];
    }
    else
    {
        return [NSString stringWithFormat:@"%d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60];
    }
}


- (NSString*)inProgressString
{
    return NSLocalizedString(@"call in progress...", @"");
}

@end
