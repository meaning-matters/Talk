//
//  GetStartedRestoreViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "GetStartedRestoreViewController.h"
#import "AnalyticsTransmitter.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@implementation GetStartedRestoreViewController

- (id)init
{
    if (self = [super init])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    AnalysticsTrace(@"viewDidLoad");

    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedStringWithDefaultValue(@"GetStartedRestore Welcome", nil, [NSBundle mainBundle],
                                                             @"Welcome back!",
                                                             @"...\n"
                                                             @"[1 line large font].");

    self.textView.text = NSLocalizedStringWithDefaultValue(@"GetStartedRestore Text", nil, [NSBundle mainBundle],
                                                           @"To access your data, iOS may ask you to sign "
                                                           @"in with your App Store account. (Use the same App Store "
                                                           @"account as when signing up with NumberBay.)\n\n"
                                                           @"If using multiple devices, you'll be sharing your "
                                                           @"Credit and verified Phones.\n\n"
                                                           @"Settings and Caller ID preferences are per device, "
                                                           @"and won't be restored nor shared.",
                                                           @"....\n"
                                                           @"[iOS alert title size].");

    [self.button setTitle:NSLocalizedStringWithDefaultValue(@"GetStartedRestore Button", nil, [NSBundle mainBundle],
                                                            @"Please Come In",
                                                            @"...\n"
                                                            @"[1 line larger font].")
                 forState:UIControlStateNormal];
}


- (void)getStarted
{
    AnalysticsTrace(@"getStarted");

    [self setBusy:YES];

    [[PurchaseManager sharedManager] restoreAccount:^(BOOL success, id object)
    {
        [self setBusy:NO];

        if (success == YES && object != nil)    // Transaction is passed, but we don't need/use that.
        {
            AnalysticsTrace(@"restoreAccount_A");

            [self restoreUserData];
        }
        else if (success == YES && object == nil)
        {
            AnalysticsTrace(@"restoreAccount_B");

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStartedRestore NothingToRestoreTitle", nil,
                                                        [NSBundle mainBundle], @"Nothing To Restore",
                                                        @"Alert title telling there is no account that could be restored.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStartedRestore NothingToRestoreMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"You haven't signed up yet with your App Store account.\n\n"
                                                        @"Tap the Sign Up button on the Get Started screen to get some "
                                                        @"calling credit and have your mobile number verified.",
                                                        @"Alert message telling there is no account that could be restored.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                AnalysticsTrace(@"restoreAccount_NothingToRestore");

                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            AnalysticsTrace(@"restoreAccount_C");

            [self.navigationController popViewControllerAnimated:YES];
        }
        else if (object != nil)
        {
            AnalysticsTrace(@"restoreAccount_D");

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStartedRestore FailedRestoreTitle", nil,
                                                        [NSBundle mainBundle], @"Restore Failed",
                                                        @"Alert title: An account could not be restored.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStartedRestore FailedRestoreMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while restoring your account: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that restoring an account failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [object localizedDescription]];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [[AppDelegate appDelegate] resetAll];
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}

@end
