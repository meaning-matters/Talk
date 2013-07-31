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
                                                                @"To use NumberBay, you need an account with credit, "
                                                                @"and your phone number needs to be verified. "
                                                                @"\n\nWhen you are new: Buy an account, and follow "
                                                                @"the steps to verify your number. The price of the "
                                                                @"account will be your initial credit, so does not "
                                                                @"cost you extra. "
                                                                @"\n\nLogged in, you can buy more credit, and numbers "
                                                                @"from 50 countries."
                                                                @"\n\nWhen you already have an account: Restore your "
                                                                @"credit and numbers.",
                                                                @"...");
    self.introRestoreButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro RestoreButtonTitle", nil,
                                                                                [NSBundle mainBundle], @"Restore",
                                                                                @"...");
    self.introBuyButton.titleLabel.text = NSLocalizedStringWithDefaultValue(@"Provisioning:Intro BuyButtonTitle", nil,
                                                                                [NSBundle mainBundle], @"Buy",
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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
         if (success == NO)
         {
             [self dismissViewControllerAnimated:YES completion:nil];
         }
    }];
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


- (void)setBusy:(BOOL)busy
{
    self.introRestoreButton.enabled = busy ? NO   : YES;
    self.introBuyButton.enabled     = busy ? NO   : YES;
    self.introRestoreButton.alpha   = busy ? 0.5f : 1.0f;
    self.introBuyButton.alpha       = busy ? 0.5f : 1.0f;
}


- (void)setRestoreBusy:(BOOL)busy
{
    [self setBusy:busy];

    if (busy)
    {
        [self.introRestoreActivityIndicator startAnimating];
    }
    else
    {
        [self.introRestoreActivityIndicator stopAnimating];
    }
}


- (void)setBuyBusy:(BOOL)busy
{
    [self setBusy:busy];

    if (busy)
    {
        [self.introBuyActivityIndicator startAnimating];
    }
    else
    {
        [self.introBuyActivityIndicator stopAnimating];
    }
}


- (void)restore
{
    NSString*   title   = nil;
    NSString*   message = nil;

    [[WebClient sharedClient] retrieveCredit:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
        }
        else
        {
            NSLog(@"####");
        }
    }];

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
    [self setBuyBusy:YES];

    [[PurchaseManager sharedManager] buyAccount:^(BOOL success, id object)
    {
        [self setBuyBusy:NO];

        if (success == YES)
        {
            [self setBuyBusy:NO];

            [self restore];            
        }
    }];
}


- (IBAction)introRestoreAction:(id)sender
{
    [self setRestoreBusy:YES];
    
    [[PurchaseManager sharedManager] restoreAccount:^(BOOL success, id object)
    {
        if (success == YES && object != nil)
        {
            [self setRestoreBusy:NO];

            [self restore];
        }
        else if (success == YES && object == nil)
        {
            [self setRestoreBusy:NO];

            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"Provisioning NothingToRestoreTitle", nil,
                                                      [NSBundle mainBundle], @"Nothing To Restore",
                                                      @"Alert title telling there is no account that could be restored.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning NothingToRestoreMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"No account was purchased earlier with the current Apple ID.",
                                                        @"Alert message telling there is no account that could be restored.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:nil
                                 cancelButtonTitle:[CommonStrings closeString]
                                 otherButtonTitles:nil];
            
            [self showView:self.introView];
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
        else
        {
            [self setRestoreBusy:NO];
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
