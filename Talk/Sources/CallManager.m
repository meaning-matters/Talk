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
            observer  =[[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
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

        callViewController = [[CallViewController alloc] init];
        [callViewController addCall:call];

        callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [Common.appDelegate.tabBarController presentViewController:callViewController
                                                          animated:YES
                                                        completion:nil];

        NSDictionary*   tones = [[Tones sharedTones] tonesForIsoCountryCode:[phoneNumber isoCountryCode]];
        sipInterface.louderVolume = [Settings sharedSettings].louderVolume;
        if ([sipInterface makeCall:call tones:tones] == NO)
        {
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


- (void)setOnSpeaker:(BOOL)onSpeaker
{
    [sipInterface setOnSpeaker:onSpeaker];
}


- (void)setCall:(Call*)call onMute:(BOOL)onMute
{
    [sipInterface setCall:call onMute:onMute];
}


- (void)setCall:(Call*)call onHold:(BOOL)onHold
{
    [sipInterface setCall:call onHold:onHold];
}


#pragma mark SipInterface Delegate

- (void)sipInterface:(SipInterface*)interface callCalling:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callRinging:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callConnecting:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callConnected:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callEnding:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callEnded:(Call*)call
{
    [callViewController changedStateOfCall:call];
}


- (void)sipInterface:(SipInterface*)interface callBusy:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callDeclined:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callNotAllowed:(Call*)call reason:(SipInterfaceCallNotAllowed)reason
{

}


- (void)sipInterface:(SipInterface*)interface callFailed:(Call*)call reason:(SipInterfaceCallFailed)reason
{

}


- (void)sipInterface:(SipInterface*)interface callIncoming:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callIncomingCanceled:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callOnHold:(Call*)call
{

}


- (void)sipInterface:(SipInterface*)interface callOnMute:(Call*)call
{

}


- (void)sipInterfaceOnSpeaker:(SipInterface*)interface
{
}


- (void)sipInterfaceError:(SipInterface*)interface reason:(SipInterfaceError)error
{

}

@end
