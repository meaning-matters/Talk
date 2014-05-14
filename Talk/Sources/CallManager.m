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
#import "WebClient.h"


#define ALLOW_CALLS_WHEN_REACHABLE_DISCONNECTED 1


@interface CallManager ()
{
    CallViewController*     callViewController;
    CallbackViewController* callbackViewController;
}

@end


@implementation CallManager

#pragma mark - Singleton Stuff

+ (CallManager*)sharedManager
{
    static CallManager*    sharedInstance;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[CallManager alloc] init];
    });
    
    return sharedInstance;
}


#pragma mark Utility Methods

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

    //### It's hacky that we have two updates; needs cleanup.
    [self updateRecent:recent withCall:call];
    [self updateRecent:recent completion:^(BOOL success, BOOL ended)
    {
        NBLog(@"%@", success ? @"###Success updating recent" : @"Failed updating recent.");
    }];
}


- (void)updateRecent:(NBRecentContactEntry*)recent completion:(void (^)(BOOL success, BOOL ended))completion
{
    if (recent == nil || recent.uuid.length == 0)
    {
        return;
    }

    [[WebClient sharedClient] retrieveCallbackStateForUuid:recent.uuid
                                              currencyCode:[Settings sharedSettings].currencyCode
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
             PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:recent.number];
             Call*        call        = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOutgoing];

             call.state            = state;
             call.leg              = leg;
             call.callbackDuration = callbackDuration;
             call.outgoingDuration = outgoingDuration;
             call.callbackCost     = callbackCost;
             call.outgoingCost     = outgoingCost;

             recent.uuid = (state == CallStateEnded) ? nil : recent.uuid;
             [[CallManager sharedManager] updateRecent:recent withCall:call];

             completion(YES, state == CallStateEnded);
         }
         else
         {
             completion(NO, NO);
         }
     }];
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

- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString*)contactId
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
            call = [self callCallbackPhoneNumber:phoneNumber fromIdentity:identity contactId:contactId];
    }

    return call;
}


- (Call*)callCallbackPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity contactId:(NSString*)contactId
{
    Call*     call = nil;
    NSString* title;
    NSString* message;
    int       missing = (([Settings sharedSettings].callbackE164.length == 0) << 0) +
                        (([Settings sharedSettings].callerIdE164.length == 0) << 1);

    if (missing != 0)
    {
        title   = NSLocalizedStringWithDefaultValue(@"Call:CallBack MissingPhonesTitle", nil, [NSBundle mainBundle],
                                                    @"No Phone%@ Selected",
                                                    @"Alert title informing that mobile calls are not supported\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Call:CallBack MissingPhonesMessage", nil, [NSBundle mainBundle],
                                                    @"You can't call because no Phone was selected as %@.\n\n"
                                                    @"Go to the Settings tab to make changes.",
                                                    @"Alert message \n"
                                                    @"[iOS alert message size]");

        switch (missing)
        {
            case 1:
                title   = [NSString stringWithFormat:title,   @""];
                message = [NSString stringWithFormat:message, @"callback number"];
                break;

            case 2:
                title   = [NSString stringWithFormat:title,   @""];
                message = [NSString stringWithFormat:message, @"caller ID"];
                break;

            case 3:
                title   = [NSString stringWithFormat:title,   @"s"];
                message = [NSString stringWithFormat:message, @"callback number and caller ID"];
                break;
        }

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];

        return nil;
    }

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


- (void)endCall:(Call*)call
{
    [callbackViewController dismissViewControllerAnimated:YES completion:^
    {
        [self addCallToRecents:call];
        callbackViewController = nil;
    }];
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

@end
