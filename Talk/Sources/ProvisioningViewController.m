//
//  ProvisioningViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 10/02/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

// 1. Show intro + Buy-Account button (A) + Restore-Account button (B)
// -  Show large activity indicator after tapping either button.
// -  (A) -> Purchase is started.
// -  (A) -> When account was already purchased (C) does iOS show alert
//    about downloading Account content???  If so, how to avoid this?
// -  (C) -> Get user credentials and number and credit info (D).
// -  (D) + has number(s), no credit -> 2.
// -  (D) + has no numbers -> 3.
// 2. Explain situation + Buy-Credit button (E) + Cancel button (F)
// 3. Explain situation + Buy-Number button (G) + Cancel button (H)
// 

#import "ProvisioningViewController.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"
#import "Common.h"
#import "WebClient.h"


@interface ProvisioningViewController ()
{
    UIView* currentView;
}

@end


@implementation ProvisioningViewController

- (id)init
{
    if (self = [super initWithNibName:@"ProvisioningView" bundle:nil])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.introNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro BarTitle", nil,
                                                                              [NSBundle mainBundle], @"Get Started",
                                                                              @"...");
    self.introTextView.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro Text", nil,
                                                                [NSBundle mainBundle],
                                                                @"To make calls you need an account, a phone number, "
                                                                @"and credit.\n\nIf you have set up things earlier, "
                                                                @"you can restore everything.\n\nWhen you are new, "
                                                                @"start with buying an account, and follow the steps."
                                                                @"The price of the account will be added to your "
                                                                @"credit, so does not cost you extra.",
                                                                @"...");
    self.introRestoreButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro RestoreButtonTitle", nil,
                                                                                [NSBundle mainBundle], @"Restore",
                                                                                @"...");
    self.introBuyButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro BuyButtonTitle", nil,
                                                                                [NSBundle mainBundle], @"Buy",
                                                                                @"...");

    self.busyNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Busy BarTitle", nil,
                                                                             [NSBundle mainBundle], @"Busy",
                                                                             @"...");

    self.failNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Fail BarTitle", nil,
                                                                             [NSBundle mainBundle], @"Failed",
                                                                             @"...");

    self.readyNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BarTitle", nil,
                                                                              [NSBundle mainBundle], @"Ready",
                                                                              @"...");
    self.readyCreditButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready CreditButtonTitle", nil,
                                                                               [NSBundle mainBundle], @"Credit",
                                                                               @"...");
    self.readyNumberButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready CreditButtonTitle", nil,
                                                                               [NSBundle mainBundle], @"Number",
                                                                               @"...");

    [self.view addSubview:self.introView];
    currentView = self.introView;
}


#pragma mark - Utility Methods

- (void)showView:(UIView*)toShowView
{
    if (toShowView != currentView)
    {
        [UIView transitionFromView:currentView
                            toView:toShowView
                          duration:0.5
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        completion:nil];

        currentView = toShowView;
    }
}


#pragma mark - Intro UI Actions

- (IBAction)introCancelAction:(id)sender
{
#warning  //### Stop any purchase or server actions, or at least make sure they don't mess up/crash things.

    [self dismissViewControllerAnimated:YES
                             completion:^
    {
        //### ?
    }];
}


- (IBAction)introBuyAction:(id)sender
{
}


- (IBAction)introRestoreAction:(id)sender
{
    self.busyLabel.text = NSLocalizedStringWithDefaultValue(@"Purchase:BusyAccount LabelText", nil,
                                                            [NSBundle mainBundle], @"Restoring account...",
                                                            @"Label text telling that app is busy restoring the account\n"
                                                            @"[1 line]");
    [self showView:self.busyView];

    [[PurchaseManager sharedManager] restoreOrBuyAccount:^(BOOL success, id object)
    {
        if (success == YES)
        {
            self.busyLabel.text = NSLocalizedStringWithDefaultValue(@"Purchase:BusyCredit LabelText", nil,
                                                                    [NSBundle mainBundle], @"Checking credit...",
                                                                    @"Label text telling that app is busy checking credit\n"
                                                                    @"[1 line]");
            [self showView:self.busyView];

            [[WebClient sharedClient] retrieveCredit:^(WebClientStatus status, id content)
            {
                if (status == WebClientStatusOk)
                {
                    self.busyLabel.text = NSLocalizedStringWithDefaultValue(@"Purchase:BusyNumbers LabelText", nil,
                                                                            [NSBundle mainBundle], @"Retrieving numbers...",
                                                                            @"Label text telling that app is busy retrieving "
                                                                            @"the user's telephone numbers\n"
                                                                            @"[1 line]");

                    [[WebClient sharedClient] retrieveNumbers:^(WebClientStatus status, id content)
                    {
                        if (status == WebClientStatusOk)
                        {
                            //### Set ready text telling about current credit and number of numbers that are available.

                            [self showView:self.readyView];
                        }
                        else
                        {
                            NSLog(@"####");
                        }
                    }];
                }
                else
                {
                    NSLog(@"####");
                }
            }];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if (object != nil)
        {
            NSString*   format;

            format = NSLocalizedStringWithDefaultValue(@"Purchase:Failure AlertMessage", nil,
                                                       [NSBundle mainBundle],
                                                       @"Something went wrong while getting your account: %@.\n\n"
                                                       @"Please try again later.",
                                                       @"Message telling that getting an account failed\n"
                                                       @"[iOS alert message size]");
            self.failTextView.text = [NSString stringWithFormat:format, [(NSError*)object localizedDescription]];
            [self showView:self.failView];
        }
    }];
}


#pragma mark - Busy UI Actions

- (IBAction)busyCancelAction:(id)sender
{
#warning //### Stop any purchase or server actions, or at least make sure they don't mess up/crash things.

    [self dismissViewControllerAnimated:YES
                             completion:^
    {
        //### ?
    }];
}


#pragma mark - Fail UI Actions

- (IBAction)failCancelAction:(id)sender
{
#warning //### Stop any purchase or server actions, or at least make sure they don't mess up/crash things.

    [self dismissViewControllerAnimated:YES
                             completion:^
    {
        //### ?
    }];
}


- (IBAction)failCloseAction:(id)sender
{
    [self dismissViewControllerAnimated:YES
                             completion:^
    {
        //### ?
    }];
}


#pragma mark - Ready UI Actions

- (IBAction)readyCancelAction:(id)sender
{
#warning //### Stop any purchase or server actions, or at least make sure they don't mess up/crash things.

    [self dismissViewControllerAnimated:YES
                             completion:^
     {
         //### ?
     }];
}


- (IBAction)readyCreditAction:(id)sender
{

}


- (IBAction)readyNumberAction:(id)sender
{

}

@end
