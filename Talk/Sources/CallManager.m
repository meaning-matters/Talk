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
#import "CallViewController.h"


@implementation CallManager

static CallManager* sharedManager;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([CallManager class] == self)
    {
        sharedManager = [self new];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedManager && [CallManager class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate Settings singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (CallManager*)sharedManager
{
    return sharedManager;
}


- (BOOL)callPhoneNumber:(PhoneNumber*)phoneNumber
{
    if ([self checkPhoneNumber:phoneNumber] == YES)
    {
        CallViewController* callViewController = [[CallViewController alloc] init];
        callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

        UITabBarController* tabBarController = [Common appDelegate].tabBarController;
        [tabBarController.selectedViewController presentViewController:callViewController
                                                              animated:YES
                                                            completion:nil];
        return YES;
    }
    else
    {
        return NO;
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
