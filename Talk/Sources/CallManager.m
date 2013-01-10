//
//  CallManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CallManager.h"
#import "Common.h"
#import "CommonStrings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "NetworkStatus.h"
#import "PhoneNumber.h"
#import "CountriesViewController.h"
#import "CallViewController.h"
#import "Tones.h"


@interface CallManager ()
{
    CallViewController* callViewController;
}

@end


@implementation CallManager

static CallManager*     sharedManager;
static SipInterface*    sipInterface;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([CallManager class] == self)
    {
        sharedManager = [self new];

        if ([self initializeSipInterface] == NO)
        {
            // Wait until SIP account is available.
            __block id  observer;
            observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                         object:nil
                                                                          queue:[NSOperationQueue mainQueue]
                                                                     usingBlock:^(NSNotification* note)
             {
                 if ([self initializeSipInterface] == YES)
                 {
                     [[NSNotificationCenter defaultCenter] removeObserver:observer];
                 }
             }];
        }
    }
}


+ (BOOL)initializeSipInterface
{
    if ([Settings sharedSettings].sipServer   != nil &&
        [Settings sharedSettings].sipRealm    != nil &&
        [Settings sharedSettings].sipUsername != nil &&
        [Settings sharedSettings].sipPassword != nil)
    {
        // Initialize SIP stuff.
        Settings*   settings = [Settings sharedSettings];

        sipInterface = [[SipInterface alloc] initWithRealm:settings.sipRealm
                                                    server:settings.sipServer
                                                  username:settings.sipUsername
                                                  password:settings.sipPassword];
        sipInterface.delegate = sharedManager;

        return YES;
    }
    else
    {
        return NO;
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedManager && [CallManager class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate CallManager singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (CallManager*)sharedManager
{
    return sharedManager;
}


#pragma mark Utility Methods

// Checks non-emergency number.
- (BOOL)checkPhoneNumber:(PhoneNumber*)phoneNumber
{
    BOOL    result;

    if ([[Settings sharedSettings].homeCountry length] == 0 && [phoneNumber isInternational] == NO)
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownTitle", nil,
                                                              [NSBundle mainBundle], @"Country Unknown",
                                                              @"Alert title informing about home country being unknown\n"
                                                              @"[iOS alert title size].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"The country for this (local) number can't be determined. "
                                                                @"Select the default country, or dial an international number.",
                                                                @"Alert message informing about home country being unknown\n"
                                                                @"[iOS alert message size]");

        NSString*   buttonTitle = NSLocalizedStringWithDefaultValue(@"General:AppStatus CountryUnknownButton", nil,
                                                                    [NSBundle mainBundle], @"Select",
                                                                    @"Alert button title for selecting home country\n"
                                                                    @"[iOS small alert button size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             if (buttonIndex == 1)
             {
                 UINavigationController*    modalViewController;
                 CountriesViewController*   countriesViewController;
                 UITabBarController*        tabBarController;

                 countriesViewController = [[CountriesViewController alloc] init];
                 countriesViewController.isModal = YES;

                 modalViewController = [[UINavigationController alloc] initWithRootViewController:countriesViewController];
                 modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                 tabBarController = [Common appDelegate].tabBarController;
                 [tabBarController presentViewController:modalViewController
                                                animated:YES
                                              completion:nil];
             }
         }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:buttonTitle, nil];

        result = NO;
    }
    else if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableDisconnected)
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Voip NotConnectedTitle", nil,
                                                              [NSBundle mainBundle], @"No Internet Connection",
                                                              @"Alert title informing about not being able to make a "
                                                              @"call because not connected to internet\n"
                                                              @"[iOS alert title size - abbreviated: 'No Internet' or "
                                                              @"'Not Connected'].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Voip NotConnectedMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"You can't make this call because there is no internet "
                                                                @"connection.",
                                                                @"Alert message informing about not being able to make a "
                                                                @"call because not connected to internet\n"
                                                                @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];
    }
    else if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCellular &&
             [Settings sharedSettings].allowCellularDataCalls == NO)
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Voip DisallowCellularTitle", nil,
                                                              [NSBundle mainBundle], @"No Cellular Data Calls",
                                                              @"Alert title informing about not being able to make a "
                                                              @"call over cellular data, because that's not allowed\n"
                                                              @"[iOS alert title size - abbreviated: 'No Data Calls'].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Voip DisallowCellularMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"You can't make this call because cellular data calls "
                                                                @"are disabled in app Settings.",
                                                                @"Alert message informing about not being able to make a "
                                                                @"call over cellular data, because that's not allowed\n"
                                                                @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];
    }
    else if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCaptivePortal)
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Voip CaptivePortalTitle", nil,
                                                              [NSBundle mainBundle], @"Behind Captive Portal",
                                                              @"Alert title informing about not being able to make a "
                                                              @"call because behind a Wi-Fi captive portal\n"
                                                              @"[iOS alert title size - abbreviated: 'Captive Portal'].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Voip CaptivePortalMessage", nil,
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
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        result = YES;
    }
    
    return result;
}


#warning I makes no sense to have messages for errors that are never used in an alert.  The current
#warning code only shows a message when no CallViewController was shown yet: a very limited  number.
#warning Need to rethink this (hence a number of empty ... ones below): perhaps always have CallView
#warning and show a short line instead of full message?  On the other hand it's good to have a popup
#warning for the NoCredit one, with a Buy button.
- (NSString*)callFailedMessage:(SipInterfaceCallFailed)failed
{
    NSString*   message;

    switch (failed)
    {
        case SipInterfaceCallFailedNotAllowedCountry:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotAllowedCountry", nil,
                                                        [NSBundle mainBundle],
                                                        @"The dialed number is in a country that is not supported.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"it was to a country we don't allow calls to\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNotAllowedNumber:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotAllowedNumber", nil,
                                                        [NSBundle mainBundle],
                                                        @"The dialed number is to a destination that is not supported.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"it was to a destination we don't allow calls to\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNoCredit:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NoCredit", nil,
                                                        [NSBundle mainBundle],
                                                        @"There is not enough credit to make this call. "
                                                        @"Buy more, and be ready to call in a snap.",
                                                        @"Alert message informing that a call could not be connected "
                                                        @"because there was not enough calling credit\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedCalleeNotOnline:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed CalleeNotOnline", nil,
                                                        [NSBundle mainBundle],
                                                        @"The called person appears to be offline.",
                                                        @"Alert message informing that a call could not be connected "
                                                        @"because there was not enough calling credit\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTooManyCalls:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed TooManyCalls", nil,
                                                        [NSBundle mainBundle],
                                                        @"The number of simultaneous calls has been reached; "
                                                        @"no more calls can be added.",
                                                        @"Alert message informing that a call was not possible because "
                                                        @"there are already a number of calls active\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTechnical:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed Internal", nil,
                                                        [NSBundle mainBundle],
                                                        @"This call could not be made due to a technical issue.",
                                                        @"Alert message informing that a call failed due to a "
                                                        @"technical problem\n"
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedInvalidNumber:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed InvalidNumber", nil,
                                                        [NSBundle mainBundle],
                                                        @"The number appears to be invalid.",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"the number appeared to be invalid."
                                                        @"[iOS alert message size].");
            break;

            
        case SipInterfaceCallFailedBadRequest:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed BadRequest", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedNotFound:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed NotFound", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedTemporarilyUnavailable:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed TemporarilyUnavailable", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedPstnTerminationFail:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed PstnTerminationFail", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedCallRoutingError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed CallRoutingError", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;

        case SipInterfaceCallFailedOtherSipError:
            message = NSLocalizedStringWithDefaultValue(@"Call:Failed OtherSipError", nil,
                                                        [NSBundle mainBundle],
                                                        @"...",
                                                        @"Alert message informing that a call could not be made because "
                                                        @"...."
                                                        @"[iOS alert message size].");
            break;
    }

    return message;
}


#pragma mark - Public API

- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber fromIdentity:(NSString*)identity
{
    Call*   call = nil;

    //### Check that number and identity are non empty!

    if (phoneNumber.isEmergency)
    {
        if ([self callMobilePhoneNumber:phoneNumber] == YES)
        {
            call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOut];
            call.network = CallNetworkMobile;
        }
    }
    else if ([self checkPhoneNumber:phoneNumber] == YES)
    {
        call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOut];
        call.identityNumber = identity;

        NSDictionary*   tones = [[Tones sharedTones] tonesForIsoCountryCode:[phoneNumber isoCountryCode]];
        sipInterface.louderVolume = [Settings sharedSettings].louderVolume;
        if ([sipInterface makeCall:call tones:tones] == YES)
        {
            callViewController = [[CallViewController alloc] initWithCall:call];
            callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
            [Common.appDelegate.tabBarController presentViewController:callViewController
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
    [sipInterface hangupCall:call reason:nil];
}


- (BOOL)callMobilePhoneNumber:(PhoneNumber*)phoneNumber
{
    if ([NetworkStatus sharedStatus].allowsMobileCalls)
    {
        NSURL*  url = [NSURL URLWithString:[NSString stringWithFormat:@"tel:%@", phoneNumber.number]];
        if ([[UIApplication sharedApplication] openURL:url] == NO)
        {
            NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedTitle", nil,
                                                                  [NSBundle mainBundle], @"Mobile Call Failed",
                                                                  @"Alert title informing about mobile call that failed\n"
                                                                  @"[iOS alert title size - abbreviated: 'Call Failed'].");

            NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedMessage", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"An attempt was made to make a mobile call, but it failed.",
                                                                    @"Alert message informing about mobile call that failed\n"
                                                                    @"[iOS alert message size]");

            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[CommonStrings closeString]
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
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil,
                                                              [NSBundle mainBundle], @"No Emergency Calls",
                                                              @"Alert title informing that emergency calls are not supported\n"
                                                              @"[iOS alert title size].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil,
                                                                [NSBundle mainBundle],
                                                                @"Your device does not allow making emergency calls.",
                                                                @"Alert message informing that emergency calls are not supported\n"
                                                                @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleTitle", nil,
                                                              [NSBundle mainBundle], @"No Mobile Calls",
                                                              @"Alert title informing that mobile calls are not supported\n"
                                                              @"[iOS alert title size].");

        NSString*   message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Your device does not allow making mobile calls.",
                                                                @"Alert message informing that mobile calls are not supported\n"
                                                                @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[CommonStrings closeString]
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
    [callViewController dismissViewControllerAnimated:YES completion:nil];
    callViewController = nil;
}


- (void)sipInterface:(SipInterface*)interface callBusy:(Call*)call
{
    [callViewController updateCallBusy:call];
}


- (void)sipInterface:(SipInterface*)interface callDeclined:(Call*)call
{
    [callViewController updateCallDeclined:call];
}


- (void)sipInterface:(SipInterface*)interface callFailed:(Call*)call reason:(SipInterfaceCallFailed)reason
{
    if (callViewController != nil)
    {
        [callViewController updateCallFailed:call reason:reason];
    }
    else
    {
        NSString*   title = NSLocalizedStringWithDefaultValue(@"Call:Failed AlertTitle", nil,
                                                              [NSBundle mainBundle], @"No Call Made",
                                                              @"Alert title informing (in non-negative way: not using "
                                                              @"words like failed/error/...) that call could not be "
                                                              @"made\n"
                                                              @"[iOS alert title size].");

        if (reason == SipInterfaceCallFailedNoCredit)
        {
            [BlockAlertView showAlertViewWithTitle:title
                                           message:[self callFailedMessage:reason]
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 if (buttonIndex == 1)
                 {
                     //### Open Purchases view controller.  See checkPhoneNumber: for example code.
                 }
             }
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:[CommonStrings buyString], nil];
        }
        else
        {
            [BlockAlertView showAlertViewWithTitle:title
                                           message:[self callFailedMessage:reason]
                                        completion:nil
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:nil];
        }
    }
}


- (void)sipInterface:(SipInterface*)interface callIncoming:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callIncomingCanceled:(Call*)call
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
