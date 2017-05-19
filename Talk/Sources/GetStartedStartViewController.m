//
//  GetStartedStartViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "GetStartedStartViewController.h"
#import "AnalyticsTransmitter.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "AppDelegate.h"

@interface GetStartedStartViewController ()

@property (nonatomic, assign) BOOL freeAccount;

@end

@implementation GetStartedStartViewController

- (instancetype)initWithFreeAccount:(BOOL)freeAccount
{
    AnalysticsTrace(@"init");

    if (self = [super init])
    {
        self.freeAccount = freeAccount;
    }

    return self;
}


- (void)viewDidLoad
{
    AnalysticsTrace(@"viewDidLoad");

    [super viewDidLoad];

    [self loadProducts];

    self.titleLabel.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart Welcome", nil, [NSBundle mainBundle],
                                                             @"Welcome!",
                                                             @"...\n"
                                                             @"[1 line large font].");

    if (self.freeAccount)
    {
        self.textView.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart Text", nil, [NSBundle mainBundle],
                                                               @"Receive some free credit and add your mobile number; "
                                                               @"that's all you need to make calls.\n\n"
                                                               @"Keep your mobile number private by buying a second "
                                                               @"number, or as many you wish. Choose from up to "
                                                               @"60 countries.\n\n"
                                                               @"NumberBay uses your real phone, not Wi-Fi/mobile "
                                                               @"internet calls. Means you can always be reached on the "
                                                               @"numbers you'll buy. And to call, internet is used for a "
                                                               @"second, then your real call starts.",
                                                               @"....\n"
                                                               @"[iOS alert title size].");
    }
    else
    {
        self.textView.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart Text", nil, [NSBundle mainBundle],
                                                               @"Get some credit and add your mobile number; "
                                                               @"that's all you need to make calls.\n\n"
                                                               @"Keep your mobile number private by buying a second "
                                                               @"number, or as many you wish. Choose from up to "
                                                               @"60 countries.\n\n"
                                                               @"NumberBay uses your real phone, not Wi-Fi/mobile "
                                                               @"internet calls. Means you can always be reached on the "
                                                               @"numbers you'll buy. And to call, internet is used for a "
                                                               @"second, then your real call starts.",
                                                               @"....\n"
                                                               @"[iOS alert title size].");
    }

    [self setButtonTitle];
}


- (void)viewDidAppear:(BOOL)animated
{
    AnalysticsTrace(@"viewDidAppear");

    [super viewDidAppear:animated];
}


- (void)loadProducts
{
    AnalysticsTrace(@"loadProducts");

    self.isLoading      = YES;
    self.button.enabled = NO;
    self.button.alpha   = 0.5f;
    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
         self.button.enabled = success;
         self.button.alpha   = success ? 1.0f : 0.5f;
         if (success == NO)
         {
             AnalysticsTrace(@"loadProducts_FAIL");

             [self.navigationController popViewControllerAnimated:YES];
         }
         else
         {
             self.isLoading = NO;
             [self setButtonTitle];
         }
    }];
}


- (void)setButtonTitle
{
    NSString* title;
    if (self.freeAccount)
    {
        title = NSLocalizedStringWithDefaultValue(@"GetStartedStart Button", nil, [NSBundle mainBundle],
                                                  @"Get Free Credit",
                                                  @"...\n"
                                                  @"[1 line larger font].");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"GetStartedStart Button", nil, [NSBundle mainBundle],
                                                  @"Buy %@ Credit",
                                                  @"...\n"
                                                  @"[1 line larger font].");
        title = [NSString stringWithFormat:title, [[PurchaseManager sharedManager] localizedPriceForAccount]];
    }

    [self.button setTitle:title forState:UIControlStateNormal];
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
            [self buyAccount];
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
                                                        @"You've already become a NumberBay insider earlier. "
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


- (void)buyAccount
{
    [self setBusy:YES];

    [[PurchaseManager sharedManager] buyAccountForFree:self.freeAccount completion:^(BOOL success, id object)
    {
        [self setBusy:NO];

        if (success == YES)
        {
            AnalysticsTrace(@"getStarted_success");

            [self restoreUserData];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            AnalysticsTrace(@"getStarted_popView");

            [self.navigationController popViewControllerAnimated:YES];
        }
        else if (object != nil)
        {
            AnalysticsTrace(@"getStarted_error_initial_credit");

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStarted FailedBuyTitle", nil,
                                                        [NSBundle mainBundle], @"Getting Credit Failed",
                                                        @"Alert title: Calling credit could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStarted FailedBuyMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while getting your initial credit: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that buying credit failed\n"
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
