//
//  GetStartedRestoreViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "GetStartedRestoreViewController.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "Strings.h"


@interface GetStartedRestoreViewController ()

@end


@implementation GetStartedRestoreViewController

- (id)init
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"GetStartedRestore ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Welcome Back",
                                                       @"Title of app screen ...\n"
                                                       @"[1 line larger font].");
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)buttonAction:(id)sender
{
    [self setBusy:YES];

    [[PurchaseManager sharedManager] restoreAccount:^(BOOL success, id object)
    {
        if (success == YES && object != nil)    // Transaction is passed, but we don't need/use that.
        {
            [self setBusy:NO];

            [self restoreCreditAndData];
        }
        else if (success == YES && object == nil)
        {
            [self setBusy:NO];

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStarted NothingToRestoreTitle", nil,
                                                        [NSBundle mainBundle], @"Nothing To Restore",
                                                        @"Alert title telling there is no account that could be restored.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStarted NothingToRestoreMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"No initial credit was purchased earlier with the "
                                                        @"current App Store user's Apple ID.\n\nTap the Start "
                                                        @"button to buy some initial credit and have your "
                                                        @"number verified.",
                                                        @"Alert message telling there is no account that could be restored.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if (object != nil)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStarted FailedRestoreTitle", nil,
                                                        [NSBundle mainBundle], @"Restore Failed",
                                                        @"Alert title: An account could not be restored.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStarted FailedRestoreMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while restoring your credit "
                                                        @"and verified numbers: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that restoring an account failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [object localizedDescription]];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else
        {
            [self setBusy:NO];
        }
    }];
}

@end
