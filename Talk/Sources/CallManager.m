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
#import "PhoneNumber.h"
#import "CountriesViewController.h"
#import "SipInterface.h"


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
            // Wait until account is available.
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
    if ([Settings sharedSettings].sipRealm    != nil &&
        [Settings sharedSettings].sipUsername != nil &&
        [Settings sharedSettings].sipPassword != nil)
    {
        // Initialize SIP stuff.
        NSString*   sipConfigPath = [[NSBundle mainBundle] pathForResource:@"SipConfig" ofType:@"cfg"];
        sipInterface = [[SipInterface alloc] initWithConfigPath:sipConfigPath
                                                         server:[Settings sharedSettings].sipServer
                                                          realm:[Settings sharedSettings].sipRealm
                                                       username:[Settings sharedSettings].sipUsername
                                                       password:[Settings sharedSettings].sipPassword];

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


#pragma mark - Public API

- (void)makeCall:(Call*)call
{
    if ([self checkPhoneNumber:call.phoneNumber] == YES)
    {
    }
    else
    {
    }
}


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
                 [tabBarController.selectedViewController presentViewController:modalViewController
                                                                       animated:YES
                                                                     completion:nil];
             }
         }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:buttonTitle, nil];

        result = NO;
    }
    else
    {
        result = YES;
    }

    return result;
}

@end
