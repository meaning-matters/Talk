//
//  CallManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "PurchaseManager.h"
#import "PhoneNumber.h"
#import "CountriesViewController.h"
#import "CallViewController.h"
#import "CallbackViewController.h"
#import "Tones.h"
#import "Base64.h"
#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"


#define ALLOW_CALLS_WHEN_REACHABLE_DISCONNECTED 1


@interface CallManager ()
{
    CallViewController*     callViewController;
    CallbackViewController* callbackViewController;
}

@end


@implementation CallManager

static SipInterface*    sipInterface;


#pragma mark - Singleton Stuff

+ (CallManager*)sharedManager
{
    static CallManager*    sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[CallManager alloc] init];
#if HAS_VOIP
        sipInterface   = [[SipInterface alloc] initWithRealm:[Settings sharedSettings].sipRealm
                                                      server:[Settings sharedSettings].sipServer
                                                    username:[Settings sharedSettings].sipUsername
                                                    password:[Settings sharedSettings].sipPassword];
        sipInterface.delegate = sharedInstance;
#endif
    });
    
    return sharedInstance;
}


#pragma mark Utility Methods

#warning I makes no sense to have messages for errors that are never used in an alert.  The current
#warning code only shows a message when no CallViewController was shown yet: a very limited  number.
#warning Need to rethink this (hence a number of empty ... ones below): perhaps always have CallView
#warning and show a short line instead of full message?  On the other hand it's good to have a popup
#warning for the NoCredit one, with a Buy button.
- (NSString*)callFailedMessage:(SipInterfaceCallFailed)failed sipStatus:(int)sipStatus
{
    NSString* message;

    switch (failed)
    {
        case SipInterfaceCallFailedNone:
            message = @"";
            break;

        case SipInterfaceCallFailedNotAllowedCountry:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotAllowedCountryMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The dialed number is in a country that is not supported.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"it was to a country we don't allow calls to\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNotAllowedNumber:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotAllowedNumberMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The dialed number is to a destination that is not supported.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"it was to a destination we don't allow calls to\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNoCredit:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NoCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"There is not enough credit to make this call. "
                                                        @"Buy more, and be ready to call again in a snap.",
                                                        @"Alert message informing that a call could not be connected "
                                                        @"because there was not enough calling credit\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedCalleeNotOnline:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed CalleeNotOnlineMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The called person appears to be offline.",
                                                        @"Alert message informing that a call could not be connected "
                                                        @"because there was not enough calling credit\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTooManyCalls:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed TooManyCallsMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The number of simultaneous calls has been reached; "
                                                        @"no more calls can be added.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"there are already a number of calls active\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTechnical:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed InternalIssueMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"This call could not be made due to a technical issue (%d).",
                                                        @"Alert message informing that a call failed due to a "
                                                        @"technical problem\n"
                                                        @"[iOS alert message size].");
            message = [NSString stringWithFormat:message, sipStatus];
            break;

        case SipInterfaceCallFailedInvalidNumber:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed InvalidNumberMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The number appears to be invalid.",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"the number appeared to be invalid."
                                                        @"[iOS alert message size].");
            break;

            
        case SipInterfaceCallFailedBadRequest:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed BadRequestMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Bad request ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNotFound:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotFoundMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Not found ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedAuthenticationRequired:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed AuthenticationRequiredMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Authentication required ...", // Occurred when not registed or so.
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;


        case SipInterfaceCallFailedRequestTimeout:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed RequestTimeoutMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Request timeout ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTemporarilyUnavailable:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed TemporarilyUnavailableMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Temporarily unavailable ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedCallDoesNotExist:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed CallDoesNotExistMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Failed to setup call ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedAddressIncomplete:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed ddressIncompleteMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Address incomplete ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;
            
        case SipInterfaceCallFailedInternalServerError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed InternalServerErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Internal server error ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedServiceUnavailable:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed ServiceUnavailableMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"No internet connection, or telephony service unavailable ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedPstnTerminationFail:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed PstnTerminationFailMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"PSTN termination fail ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedCallRoutingError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed CallRoutingErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Call routing error ...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedServerError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed ServerErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Server error (%d)",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            message = [NSString stringWithFormat:message, sipStatus];
            break;

        case SipInterfaceCallFailedOtherSipError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed OtherSipErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"SIP error (%d)",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            message = [NSString stringWithFormat:message, sipStatus];
            break;
    }

    return message;
}


- (BOOL)checkAccount
{
    BOOL result;

    if ([Settings sharedSettings].haveAccount)
    {
        result = YES;
    }
    else
    {
        result = NO;
        [Common showGetStartedViewController];
    }

    return result;
}


- (BOOL)checkIfValidPhoneNumber:(PhoneNumber*)phoneNumber
{
    BOOL result;

    if ([Settings sharedSettings].allowInvalidNumbers == YES || [phoneNumber isValid] == YES)
    {
        result = YES;
    }
    else
    {
        NSString* title;
        NSString* message;
        NSString* button;

        title   = NSLocalizedStringWithDefaultValue(@"Callback InvalidTitle", nil,
                                                    [NSBundle mainBundle], @"Invalid Number",
                                                    @"Alert title: Invalid phone number\n"
                                                    @"[iOS alert title size]");

#if HAS_INVALID_NUMBER_SETTING
        message = NSLocalizedStringWithDefaultValue(@"Callback InvalidOptionMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The number you're trying to call does not seem to be "
                                                    @"valid.\n\nTry adding the country code, check the "
                                                    @"current Home Country in Settings, or allow this from now on "
                                                    @"(switch off again in Settings).",
                                                    @"Alert message: ...\n"
                                                    @"[iOS alert message size]");

        button  = NSLocalizedStringWithDefaultValue(@"Callback InvalidButton", nil,
                                                    [NSBundle mainBundle],
                                                    @"Allow",
                                                    @" ...\n"
                                                    @"[iOS ...]");
#else
        message = NSLocalizedStringWithDefaultValue(@"Callback InvalidMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The number you're trying to call does not seem to be "
                                                    @"valid.\n\nTry adding the country code, or check the "
                                                    @"current Home Country in Settings.",
                                                    @"Alert message: ...\n"
                                                    @"[iOS alert message size]");

        button = nil;
#endif

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [Settings sharedSettings].allowInvalidNumbers = !cancelled;
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:button, nil];

        result = NO;
    }

    return result;
}


- (BOOL)checkNetwork
{
    BOOL                   result;
    NSString*              title;
    NSString*              message;
    NetworkStatusReachable reachable = [NetworkStatus sharedStatus].reachableStatus;

    if (reachable == NetworkStatusReachableDisconnected && ALLOW_CALLS_WHEN_REACHABLE_DISCONNECTED)
    {
        result = YES;
    }
    else if (reachable == NetworkStatusReachableDisconnected)
    {
        title   = NSLocalizedStringWithDefaultValue(@"Call:Voip NotConnectedTitle", nil,
                                                    [NSBundle mainBundle], @"No Internet Connection",
                                                    @"Alert title informing about not being able to make a "
                                                    @"call because not connected to internet\n"
                                                    @"[iOS alert title size - abbreviated: 'No Internet' or "
                                                    @"'Not Connected'].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Voip NotConnectedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"You can't make this call because there is no internet "
                                                    @"connection.",
                                                    @"Alert message informing about not being able to make a "
                                                    @"call because not connected to internet\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        result = NO;
    }
    else if (HAS_VOIP && reachable == NetworkStatusReachableCellular && [Settings sharedSettings].allowCellularDataCalls == NO)
    {
        title   = NSLocalizedStringWithDefaultValue(@"Call:Voip DisallowCellularTitle", nil,
                                                    [NSBundle mainBundle], @"No Cellular Data Calls",
                                                    @"Alert title informing about not being able to make a "
                                                    @"call over cellular data, because that's not allowed\n"
                                                    @"[iOS alert title size - abbreviated: 'No Data Calls'].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Voip DisallowCellularMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"You can't make this call because cellular data calls "
                                                    @"are disabled in app Settings.",
                                                    @"Alert message informing about not being able to make a "
                                                    @"call over cellular data, because that's not allowed\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                [[AppDelegate appDelegate].settingsViewController allowDataCalls];
            }
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:[Strings enableString], nil];

        result = NO;
    }
    else if (reachable == NetworkStatusReachableCaptivePortal)
    {
        title   = NSLocalizedStringWithDefaultValue(@"Call:Voip CaptivePortalTitle", nil,
                                                    [NSBundle mainBundle], @"Behind Captive Portal",
                                                    @"Alert title informing about not being able to make a "
                                                    @"call because behind a Wi-Fi captive portal\n"
                                                    @"[iOS alert title size - abbreviated: 'Captive Portal'].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Voip CaptivePortalMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"You can't make this call because Wi-Fi is connected "
                                                    @"to a captive portal (%@), which requires you to log in.",
                                                    @"Alert message informing about not being able to make a "
                                                    @"call because behind a Wi-Fi captive portal\n"
                                                    @"[iOS alert message size]");
        message = [NSString stringWithFormat:message, [[NetworkStatus sharedStatus] getSsid]];

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
        
        result = NO;
    }
    else
    {
        result = YES;
    }
    
    return result;
}


- (void)addCallToRecents:(Call*)call
{
    NSManagedObjectContext* context = [DataManager sharedManager].managedObjectContext;
    NBRecentContactEntry*   recent  = [NSEntityDescription insertNewObjectForEntityForName:@"NBRecentContactEntry"
                                                                    inManagedObjectContext:context];
    recent.number    = call.phoneNumber.number;
    recent.date      = call.beginDate;
    recent.timeZone  = [[NSTimeZone defaultTimeZone] abbreviation];
    recent.contactID = call.contactId;
    recent.direction = [NSNumber numberWithInt:CallDirectionOutgoing];
    recent.uuid      = call.uuid;

    [self updateRecent:recent withCall:call];
}


- (void)updateRecent:(NBRecentContactEntry*)recent withCall:(Call*)call
{
    switch (call.state)
    {
        case CallStateNone:
            call.state    = CallStateCancelled;
            recent.status = @(CallStatusCancelled);
            break;

        case CallStateCalling:
        case CallStateRinging:
        case CallStateConnecting:
            call.state    = (call.leg == CallLegOutgoing) ? CallStateEnded        : CallStateCancelled;
            recent.status = (call.leg == CallLegOutgoing) ? @(CallStatusCallback) : @(CallStatusCancelled);
            break;

        case CallStateConnected:
        case CallStateEnding:
            call.state    = CallStateEnded;
            recent.status = (call.leg == CallLegOutgoing) ? @(CallStatusSuccess) : @(CallStatusCallback);
            break;

        case CallStateEnded:
            recent.status = (call.callbackCost == 0) ? @(CallStatusCancelled)
                                                     : ((call.outgoingCost == 0) ? @(CallStatusCallback)
                                                                                 : @(CallStatusSuccess));
            break;

        case CallStateCancelled:
            recent.status = @(CallStatusCancelled);
            break;

        case CallStateBusy:
            recent.status = @(CallStatusBusy);
            break;

        case CallStateDeclined:
            recent.status = @(CallStatusDeclined);
            break;

        case CallStateFailed:
            recent.status = @(CallStatusFailed);
            break;
    }

    recent.callbackDuration = @(call.callbackDuration);
    recent.outgoingDuration = @(call.outgoingDuration);
    recent.callbackCost     = @(call.callbackCost);
    recent.outgoingCost     = @(call.outgoingCost);
    recent.e164             = [call.phoneNumber e164Format];

    [[DataManager sharedManager].managedObjectContext save:nil];
}


#pragma mark - Public API

- (void)resetSipAccount
{
    sipInterface.realm    = [Settings sharedSettings].sipRealm;
    sipInterface.server   = [Settings sharedSettings].sipServer;
    sipInterface.username = [Settings sharedSettings].sipUsername;
    sipInterface.password = [Settings sharedSettings].sipPassword;

    [sipInterface restart];
}


- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString *)contactId
{
    Call* call = nil;

#warning //### Check that number and identity are non empty && valid!

    if (phoneNumber.isEmergency)
    {
        if ([self callMobilePhoneNumber:phoneNumber] == YES)
        {
            call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOutgoing];
            call.network = CallNetworkMobile;
        }
    }
    else if ([self checkAccount] &&
             [Common checkCountryOfPhoneNumber:phoneNumber completion:nil] &&
             [self checkIfValidPhoneNumber:phoneNumber])
    {
        if ([Settings sharedSettings].callbackMode == YES)
        {
            call = [self callCallbackPhoneNumber:phoneNumber fromIdentity:identity contactId:contactId];
        }
        else
        {
            call = [self callVoipPhoneNumber:phoneNumber fromIdentity:identity contactId:contactId];
        }
    }

    return call;
}


- (Call*)callCallbackPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString*)contactId
{
    Call* call = nil;

    if ([phoneNumber.originalFormat isEqualToString:[Settings sharedSettings].testNumber] == NO)
    {
        call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOutgoing];
        call.identityNumber = identity;
        call.showCallerId   = [Settings sharedSettings].showCallerId;
        call.leg            = CallLegCallback;
        call.contactId      = contactId;
        call.contactName    = [[AppDelegate appDelegate] contactNameForId:contactId];

        callbackViewController = [[CallbackViewController alloc] initWithCall:call];
        callbackViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [AppDelegate.appDelegate.tabBarController presentViewController:callbackViewController
                                                               animated:YES
                                                             completion:nil];
    }

    return call;
}


- (Call*)callVoipPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString *)contactId
{
    Call* call = nil;

    if ([self checkNetwork])
    {
        call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOutgoing];
        call.identityNumber = identity;
        call.showCallerId   = [Settings sharedSettings].showCallerId;
        call.contactId      = contactId;
        call.contactName    = [[AppDelegate appDelegate] contactNameForId:contactId];

        NSDictionary* tones = [[Tones sharedTones] tonesForIsoCountryCode:[phoneNumber isoCountryCode]];
        if ([sipInterface makeCall:call tones:tones] == YES)
        {
            callViewController = [[CallViewController alloc] initWithCall:call];
            callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [AppDelegate.appDelegate.tabBarController presentViewController:callViewController
                                                                   animated:YES
                                                                 completion:^
            {
                if ([Common deviceHasReceiver] == NO)
                {
                    [callViewController setSpeakerEnable:NO];
                }
            }];
        }
        else
        {
            callViewController = nil;
            NSLog(@"//### Call failed.");
        }
    }

    return call;
}


- (void)endCall:(Call*)call
{
    if ([Settings sharedSettings].callbackMode == NO ||
        [call.calledNumber isEqualToString:[Settings sharedSettings].testNumber] == YES)
    {
        if (call != nil && call.state != CallStateEnded && call.state != CallStateFailed)
        {
            [sipInterface hangupCall:call reason:nil];
        }
        else
        {
            // Call must have been ended earlier.
            [callViewController dismissViewControllerAnimated:YES completion:^
            {
                [self addCallToRecents:call];
                callViewController = nil;
            }];
        }
    }
    else
    {
        [callbackViewController dismissViewControllerAnimated:YES completion:^
        {
            [self addCallToRecents:call];
            callbackViewController = nil;
        }];
    }
}


// Only used for SIP.
- (BOOL)retryCall:(Call*)call
{
    if (call != nil)
    {
        call.userInformedAboutFailure = NO;

        NSDictionary* tones = [[Tones sharedTones] tonesForIsoCountryCode:[call.phoneNumber isoCountryCode]];
        if ([sipInterface makeCall:call tones:tones] == YES)
        {
            return YES;
        }
        else
        {
            [callViewController dismissViewControllerAnimated:YES completion:^
            {
                [self addCallToRecents:call];
                callViewController = nil;
            }];

            return NO;
        }
    }
    else
    {
        // Call must have been ended earlier.
        [callViewController dismissViewControllerAnimated:YES completion:^
        {
            callViewController = nil;
        }];

        return NO;
    }
}


- (BOOL)callMobilePhoneNumber:(PhoneNumber*)phoneNumber
{
    NSString*   title;
    NSString*   message;

    if ([NetworkStatus sharedStatus].allowsMobileCalls)
    {
        NSURL*  url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber.number]];
        if ([[UIApplication sharedApplication] openURL:url] == NO)
        {
            title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedTitle", nil,
                                                      [NSBundle mainBundle], @"Mobile Call Failed",
                                                      @"Alert title informing about mobile call that failed\n"
                                                      @"[iOS alert title size - abbreviated: 'Call Failed'].");

            message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"An attempt was made to make a mobile call, but it failed.",
                                                        @"Alert message informing about mobile call that failed\n"
                                                        @"[iOS alert message size]");

            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];

            return NO;
        }
        else
        {
            return YES;
        }
    }
    else if (phoneNumber.isEmergency)
    {
        title = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil,
                                                  [NSBundle mainBundle], @"No Emergency Calls",
                                                  @"Alert title informing that emergency calls are not supported\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil,
                                                    [NSBundle mainBundle],
                                                    @"Your device does not allow making emergency calls.",
                                                    @"Alert message informing that emergency calls are not supported\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleTitle", nil,
                                                  [NSBundle mainBundle], @"No Mobile Calls",
                                                  @"Alert title informing that mobile calls are not supported\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Your device does not allow making mobile calls.",
                                                    @"Alert message informing that mobile calls are not supported\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
}


- (void)setCall:(Call*)call onMute:(BOOL)onMute
{
    [sipInterface setCall:call onMute:onMute];
}


- (void)setCall:(Call*)call onHold:(BOOL)onHold
{
    [sipInterface setCall:call onHold:onHold];
}


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    [sipInterface setOnSpeaker:onSpeaker];
}


- (void)sendCall:(Call*)call dtmfCharacter:(char)character
{
    [sipInterface sendCall:call dtmfCharacter:character];
}


#pragma mark SipInterface Delegate

- (void)sipInterface:(SipInterface*)interface callCalling:(Call*)call
{
    [callViewController updateCallCalling:call];
}


- (void)sipInterface:(SipInterface*)interface callRinging:(Call*)call
{
    [callViewController updateCallRinging:call];
}


- (void)sipInterface:(SipInterface*)interface callConnecting:(Call*)call
{
    [callViewController updateCallConnecting:call];
}


- (void)sipInterface:(SipInterface*)interface callConnected:(Call*)call
{
    [callViewController updateCallConnected:call];
}


- (void)sipInterface:(SipInterface*)interface callEnding:(Call*)call
{
    [callViewController updateCallEnding:call];
}


- (void)sipInterface:(SipInterface*)interface callEnded:(Call*)call
{
    [callViewController updateCallEnded:call];

#warning Do only when last call was ended.
    if (call.readyForCleanup)
    {
        [callViewController dismissViewControllerAnimated:YES completion:^
        {
            [self addCallToRecents:call];
            callViewController = nil;
        }];
    }
}


- (void)sipInterface:(SipInterface*)interface callBusy:(Call*)call
{
    [callViewController updateCallBusy:call];
}


- (void)sipInterface:(SipInterface*)interface callDeclined:(Call*)call
{
    [callViewController updateCallDeclined:call];
}


- (void)sipInterface:(SipInterface*)interface callFailed:(Call*)call
              reason:(SipInterfaceCallFailed)reason
           sipStatus:(int)sipStatus
{
    if (call.userInformedAboutFailure == NO && call.readyForCleanup == NO)
    {
        call.userInformedAboutFailure = YES;

        call.sipInterfaceFailure = reason;
        call.sipFailedStatus     = sipStatus;

        if (reason == SipInterfaceCallFailedNoCredit)
        {
            // Get rid of call screen.
            [callViewController dismissViewControllerAnimated:YES completion:^
            {
                [self addCallToRecents:call];
                callViewController = nil;
            }];

            NSString*   title;
            title = NSLocalizedStringWithDefaultValue(@"Call:Failed AlertTitle", nil,
                                                      [NSBundle mainBundle], @"No Call Made",
                                                      @"Alert title informing (in non-negative way: not using "
                                                      @"words like failed/error/...) that call could not be made\n"
                                                      @"[iOS alert title size].");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:[self callFailedMessage:reason sipStatus:0]
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 if (buttonIndex == 1)
                 {
                     //### Open Purchases view controller.  See checkPhoneNumber: for example code.
                 }
             }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:[Strings buyString], nil];
        }
        else if (callViewController != nil)
        {
            [callViewController updateCallFailed:call message:[self callFailedMessage:reason sipStatus:sipStatus]];
        }
        else
        {
#warning Want to do something with errors after call screen is gone?
        }
    }
}


- (void)sipInterface:(SipInterface*)interface callIncoming:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callIncomingCancelled:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface call:(Call*)call onMute:(BOOL)onMute
{
    [callViewController setCall:call onMute:onMute];
}


- (void)sipInterface:(SipInterface*)interface call:(Call*)call onHold:(BOOL)onHold
{
    [callViewController setCall:call onHold:onHold];
}


- (void)sipInterface:(SipInterface*)interface onSpeaker:(BOOL)onSpeaker
{
    [callViewController setOnSpeaker:onSpeaker];
}


- (void)sipInterface:(SipInterface*)interface speakerEnable:(BOOL)enable
{
    if ([Common deviceHasReceiver] == YES)
    {
        [callViewController setSpeakerEnable:enable];
    }
}


- (void)sipInterfaceError:(SipInterface*)interface reason:(SipInterfaceError)error
{

}

@end
