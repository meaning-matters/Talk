//
//  CallManager.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
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
#import "CallbackViewController.h"
#import "Tones.h"
#import "Base64.h"
#import "SettingsViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "WebClient.h"
#import "CallerIdData.h"
#import "CallableData.h"
#import "CallerIdViewController.h"


@interface CallManager ()
{
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

    if ([phoneNumber isValid] == YES)
    {
        result = YES;
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"Callback InvalidTitle", nil, [NSBundle mainBundle],
                                                    @"Invalid Number",
                                                    @"Alert title: Invalid phone number\n"
                                                    @"[iOS alert title size]");

        message = NSLocalizedStringWithDefaultValue(@"Callback InvalidMessage", nil, [NSBundle mainBundle],
                                                    @"The number you're trying to call does not seem to be "
                                                    @"valid.\n\nTry adding the country code, or check the "
                                                    @"current Home Country in Settings.",
                                                    @"Alert message: ...\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];

        result = NO;
    }

    return result;
}


// The `selectedCallable` completion parameter is only filled in if a callable
// was selected as caller ID and if previously there was none selected.
- (void)checkIdentityForContactId:(NSString*)contactId completion:(void (^)(NSString* identity, BOOL showCallerId))completion
{
    if (contactId == nil)
    {
        [self checkDefaultIdentityWithCompletion:completion];
    }
    else
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"contactId == %@", contactId];
        NSArray*     callerIds = [[DataManager sharedManager] fetchEntitiesWithName:@"CallerId"
                                                                           sortKeys:nil
                                                                          predicate:predicate
                                                               managedObjectContext:nil];
        if (callerIds.count > 0)
        {
            CallerIdData* callerId = callerIds[0];
            
            completion(callerId.callable.e164, (callerId.callable != nil));
        }
        else // Use default.
        {
            [self checkDefaultIdentityWithCompletion:completion];
        }
    }
}


// Parameter `selectedCallable` is only there get the same completion prototype as checkIdentityForContactId:completion:.
- (void)checkDefaultIdentityWithCompletion:(void (^)(NSString* identity, BOOL showCallerId))completion
{
    if ([self checkCallbackAndIdentity:[Settings sharedSettings].callerIdE164
                          showCallerId:[Settings sharedSettings].showCallerId] == NO)
    {
        completion(nil, NO);
    }
    else
    {
        completion([Settings sharedSettings].callerIdE164, [Settings sharedSettings].showCallerId);
    }
}


- (BOOL)checkCallbackAndIdentity:(NSString*)identity showCallerId:(BOOL)showCallerId
{
    BOOL result;

    NSString* title;
    NSString* message;
    int       missing = (([Settings sharedSettings].callbackE164.length == 0) << 0) +
                        ((identity.length == 0 && showCallerId)               << 1);

    if (missing != 0)
    {
        switch (missing)
        {
            case 1:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Call MissingCallbackTitle", nil, [NSBundle mainBundle],
                                                            @"No Callback Phone",
                                                            @"...\n"
                                                            @"[iOS alert title size].");

                message = NSLocalizedStringWithDefaultValue(@"Call MissingCallbackMessage", nil, [NSBundle mainBundle],
                                                            @"Go to the Settings tab to select the Phone you want to be "
                                                            @"called back on.",
                                                            @"Alert message \n"
                                                            @"[iOS alert message size]");
                break;
            }
            case 2:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Call MissingIndentityTitle", nil, [NSBundle mainBundle],
                                                            @"No Default Caller ID",
                                                            @"...\n"
                                                            @"[iOS alert title size].");

#if HAS_BUYING_NUMBERS
                message = NSLocalizedStringWithDefaultValue(@"Call MissingIndentityMessage", nil, [NSBundle mainBundle],
                                                            @"Go to the Settings tab to select a Phone or Number as "
                                                            @"your default caller ID.",
                                                            @"Alert message \n"
                                                            @"[iOS alert message size]");
#else
                message = NSLocalizedStringWithDefaultValue(@"Call MissingIndentityMessage", nil, [NSBundle mainBundle],
                                                            @"Go to the Settings tab to select a Phone as your default "
                                                            @"caller ID.",
                                                            @"Alert message \n"
                                                            @"[iOS alert message size]");
#endif
                break;
            }
            case 3:
            {
                title   = NSLocalizedStringWithDefaultValue(@"Call MissingPhonesTitle", nil, [NSBundle mainBundle],
                                                            @"No Callback Nor Caller ID",
                                                            @"...\n"
                                                            @"[iOS alert title size].");

#if HAS_BUYING_NUMBERS
                message = NSLocalizedStringWithDefaultValue(@"Call MissingPhonesMessage", nil, [NSBundle mainBundle],
                                                            @"Go to the Settings tab to select the Phone you want to be "
                                                            @"called back on, and select a Phone or Number as your "
                                                            @"default caller ID.",
                                                            @"Alert message \n"
                                                            @"[iOS alert message size]");
#else
                message = NSLocalizedStringWithDefaultValue(@"Call MissingPhonesMessage", nil, [NSBundle mainBundle],
                                                            @"Go to the Settings tab to select the Phone you want to be "
                                                            @"called back on, and select a Phone as your default "
                                                            @"caller ID.",
                                                            @"Alert message \n"
                                                            @"[iOS alert message size]");
#endif
                break;
            }
        }

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings cancelString]
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
        {
            call.state    = CallStateCancelled;
            recent.status = @(CallStatusCancelled);
            break;
        }
        case CallStateCalling:
        case CallStateRinging:
        case CallStateConnecting:
        {
            call.state    = (call.leg == CallLegOutgoing) ? CallStateEnded        : CallStateCancelled;
            recent.status = (call.leg == CallLegOutgoing) ? @(CallStatusCallback) : @(CallStatusCancelled);
            break;
        }
        case CallStateConnected:
        case CallStateEnding:
        {
            call.state    = CallStateEnded;
            recent.status = (call.leg == CallLegOutgoing) ? @(CallStatusSuccess) : @(CallStatusCallback);
            break;
        }
        case CallStateEnded:
        {
            recent.status = (call.callbackCost == 0) ? @(CallStatusCancelled)
                                                     : ((call.outgoingCost == 0) ? @(CallStatusCallback)
                                                                                 : @(CallStatusSuccess));
            break;
        }
        case CallStateCancelled:
        {
            recent.status = @(CallStatusCancelled);
            break;
        }
        case CallStateBusy:
        {
            recent.status = @(CallStatusBusy);
            break;
        }
        case CallStateDeclined:
        {
            recent.status = @(CallStatusDeclined);
            break;
        }
        case CallStateFailed:
        {
            recent.status = @(CallStatusFailed);
            break;
        }
    }

    recent.callbackDuration = @(call.callbackDuration);
    recent.outgoingDuration = @(call.outgoingDuration);
    recent.callbackCost     = @(call.callbackCost);
    recent.outgoingCost     = @(call.outgoingCost);
    recent.e164             = [call.phoneNumber e164Format];

    [[DataManager sharedManager].managedObjectContext save:nil];
}


- (Call*)callPhoneNumber:(PhoneNumber*)phoneNumber
            fromIdentity:(NSString*)identity
            showCallerId:(BOOL)showCallerId
               contactId:(NSString*)contactId
{
    Call* call = nil;

    call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOutgoing];
    call.identityNumber = identity;
    call.showCallerId   = showCallerId;
    call.leg            = CallLegCallback;
    call.contactId      = contactId;
    call.contactName    = [[AppDelegate appDelegate] contactNameForId:contactId];

    callbackViewController = [[CallbackViewController alloc] initWithCall:call];
    callbackViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [AppDelegate.appDelegate.tabBarController presentViewController:callbackViewController
                                                           animated:YES
                                                         completion:nil];

    return call;
}


- (NSString*)defaultCallerIdName
{
    NSString*    e164      = [Settings sharedSettings].callerIdE164;
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
    NSArray*     callables = [[DataManager sharedManager] fetchEntitiesWithName:@"Callable"
                                                                       sortKeys:@[@"name"]
                                                                      predicate:predicate
                                                           managedObjectContext:nil];

    return ((CallableData*)[callables firstObject]).name;
}


#pragma mark - Public API

- (void)callPhoneNumber:(PhoneNumber*)phoneNumber
              contactId:(NSString*)contactId
             completion:(void (^)(Call* call))completion
{
    __block Call* call = nil;

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
        // Basic conditions have been met, now check the E164s.
        [self checkIdentityForContactId:contactId completion:^(NSString* identity, BOOL showCallerId)
        {
            if (showCallerId == NO && identity.length == 0)
            {
                identity = [Settings sharedSettings].callbackE164;
            }
                
            call = [self callPhoneNumber:phoneNumber fromIdentity:identity showCallerId:showCallerId contactId:contactId];
            
            completion ? completion(call) : (void)0;
        }];
    }
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
            title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedTitle", nil, [NSBundle mainBundle],
                                                      @"Mobile Call Failed",
                                                      @"Alert title informing about mobile call that failed\n"
                                                      @"[iOS alert title size - abbreviated: 'Call Failed'].");

            message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallFailedMessage", nil, [NSBundle mainBundle],
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
        title = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil, [NSBundle mainBundle],
                                                  @"No Emergency Calls",
                                                  @"Alert title informing that emergency calls are not supported\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Mobile NoEmergencyTitle", nil, [NSBundle mainBundle],
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
        title = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleTitle", nil, [NSBundle mainBundle],
                                                  @"No Mobile Calls",
                                                  @"Alert title informing that mobile calls are not supported\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Call:Mobile CallImpossibleMessage", nil, [NSBundle mainBundle],
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
