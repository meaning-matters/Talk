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
#import "Settings.h"
#import "CreditViewController.h"
#import "NumberCountriesViewController.h"
#import "AppDelegate.h"


@interface ProvisioningViewController ()
{
    UIView*         currentView;
    PhoneNumber*    verifyPhoneNumber;
    NSString*       verifyNumberButtonTitle;
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
                                                                @"\n\nWhen you already have an account: Restore your "
                                                                @"credit and numbers.",
                                                                @"...");
    [self.introRestoreButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Intro RestoreButtonTitle", nil,
                                                                        [NSBundle mainBundle], @"Restore",
                                                                        @"...")
                             forState:UIControlStateNormal];
    [self.introBuyButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Intro BuyButtonTitle", nil,
                                                                    [NSBundle mainBundle], @"Buy",
                                                                    @"...")
                         forState:UIControlStateNormal];

    self.verifyNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Verify BarTitle", nil,
                                                                               [NSBundle mainBundle], @"Verify Number",
                                                                               @"...");
    [self.verifyNumberButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Verify EnterNumberTitle", nil,
                                                                        [NSBundle mainBundle], @"Enter Number",
                                                                        @"...")
                             forState:UIControlStateNormal];
    verifyNumberButtonTitle = self.verifyNumberButton.titleLabel.text;
    [self.verifyCallButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Verify CallMeTitle", nil,
                                                                      [NSBundle mainBundle], @"CallMe",
                                                                      @"...")
                           forState:UIControlStateNormal];

    self.readyNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BarTitle", nil,
                                                                              [NSBundle mainBundle], @"Ready",
                                                                              @"...");
    [self.readyCreditButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Ready CreditButtonTitle", nil,
                                                                       [NSBundle mainBundle], @"Credit",
                                                                       @"...")
                            forState:UIControlStateNormal];
    [self.readyNumberButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Ready CreditButtonTitle", nil,
                                                                       [NSBundle mainBundle], @"Number",
                                                                       @"...")
                            forState:UIControlStateNormal];

    self.failNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Fail BarTitle", nil,
                                                                             [NSBundle mainBundle], @"Failed",
                                                                             @"...");

    [Common setCornerRadius:10 ofView:self.verifyStep1View];
    [Common setCornerRadius:10 ofView:self.verifyStep2View];
    [Common setCornerRadius:10 ofView:self.verifyStep3View];
    [Common setBorderWidth:0.8 color:[UIColor darkGrayColor] ofView:self.verifyStep1View];
    [Common setBorderWidth:0.8 color:[UIColor darkGrayColor] ofView:self.verifyStep2View];
    [Common setBorderWidth:0.8 color:[UIColor darkGrayColor] ofView:self.verifyStep3View];

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


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    // We deliberately set the KeypadView height to a fivefold, so that all keys
    // can be equally high.  This is assumed in the layout code of KeypadView!
    NSLog(@"%d", (int)self.view.frame.size.height);
    switch ((int)self.view.frame.size.height)
    {
        case 460:   // 320x480 screen, More tab.
        case 440:   // 320x480 screen, with in-call iOS flasher at top.
            [Common setHeight:75 ofView:self.verifyStep1View];
            [Common setHeight:75 ofView:self.verifyStep2View];
            [Common setHeight:75 ofView:self.verifyStep3View];
            [Common setY:199     ofView:self.verifyStep1View];
            [Common setY:282     ofView:self.verifyStep2View];
            [Common setY:365     ofView:self.verifyStep3View];
            [Common setY:-2      ofView:self.verifyStep1Label];
            [Common setY:-2      ofView:self.verifyStep2Label];
            [Common setY:-2      ofView:self.verifyStep3Label];
            [Common setY:28      ofView:self.verifyNumberButton];
            [Common setY:28      ofView:self.verifyCallButton];
            [Common setY:28      ofView:self.verifyCodeLabel];
            [Common setHeight:36 ofView:self.verifyNumberButton];
            [Common setHeight:36 ofView:self.verifyCallButton];
            [Common setHeight:36 ofView:self.verifyCodeLabel];
            break;

        case 548:   // 320x568 screen.
        case 528:   // 320x568 screen, with in-call iOS flasher at top.
            [Common setHeight:90 ofView:self.verifyStep1View];
            [Common setHeight:90 ofView:self.verifyStep2View];
            [Common setHeight:90 ofView:self.verifyStep3View];
            [Common setY:242     ofView:self.verifyStep1View];
            [Common setY:340     ofView:self.verifyStep2View];
            [Common setY:438     ofView:self.verifyStep3View];
            [Common setY:0       ofView:self.verifyStep1Label];
            [Common setY:0       ofView:self.verifyStep2Label];
            [Common setY:0       ofView:self.verifyStep3Label];
            [Common setY:37      ofView:self.verifyNumberButton];
            [Common setY:37      ofView:self.verifyCallButton];
            [Common setY:37      ofView:self.verifyCodeLabel];
            [Common setHeight:40 ofView:self.verifyNumberButton];
            [Common setHeight:40 ofView:self.verifyCallButton];
            [Common setHeight:40 ofView:self.verifyCodeLabel];
            break;
    }
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

    [self showView:self.verifyView];
    return;

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


#pragma mark -  Verify UI Actions

- (IBAction)verifyCancelAction:(id)sender
{
    NSString*   title;
    NSString*   message;

    title = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCancelTitle", nil,
                                              [NSBundle mainBundle], @"Cancel Account Activation",
                                              @"Cancel user account activation.\n"
                                              @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Are you sure you want to cancel the activation of your account?\n\n"
                                                @"(You can restore it later, on any device.)",
                                                @"Alert message if user wants to cancel.\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        if (buttonIndex == 1)
        {
            [[Settings sharedSettings] resetAll];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
                         cancelButtonTitle:[CommonStrings noString]
                         otherButtonTitles:[CommonStrings yesString], nil];
}


- (IBAction)verifyNumberAction:(id)sender
{
    __block BlockAlertView*  alert;
    NSString*                title;
    NSString*                message;

    title = NSLocalizedStringWithDefaultValue(@"Provisioning EnterNumberTitle", nil,
                                              [NSBundle mainBundle], @"Enter Your Number",
                                              @"Title asking user to enter their phone number.\n"
                                              @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Enter a number you own; it will be linked to your account.",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    alert = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                      message:message
                                                  phoneNumber:verifyPhoneNumber
                                                   completion:^(BOOL         cancelled,
                                                                PhoneNumber* phoneNumber)
    {
        if (cancelled == NO)
        {
            verifyPhoneNumber = phoneNumber;

            if ([phoneNumber isValid])
            {
                [self.verifyNumberButton setTitle:[phoneNumber internationalFormat] forState:UIControlStateNormal];
            }
            else
            {
                NSString*   title;
                NSString*   message;

                title = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidTitle", nil,
                                                          [NSBundle mainBundle], @"Invalid Number",
                                                          @"Phone number is not correct.\n"
                                                          @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"The phone number you entered is invalid, "
                                                            @"please correct.",
                                                            @"Alert message that entered phone number is invalid.\n"
                                                            @"[iOS alert message size]");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:nil
                                     cancelButtonTitle:[CommonStrings closeString]
                                     otherButtonTitles:nil];
                
                [self.verifyNumberButton setTitle:verifyNumberButtonTitle forState:UIControlStateNormal];
            }
        }
    }
                                            cancelButtonTitle:[CommonStrings cancelString]
                                            otherButtonTitles:[CommonStrings okString], nil];
}


- (IBAction)verifyCallAction:(id)sender
{

}


#pragma mark - Ready UI Actions

- (IBAction)readyDoneAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)readyCreditAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^
    {
        CreditViewController*   viewController = [[CreditViewController alloc] init];
        viewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [AppDelegate.appDelegate.tabBarController presentViewController:viewController animated:YES completion:nil];
    }];
}


- (IBAction)readyNumberAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^
     {
         UINavigationController*         modalViewController;
         NumberCountriesViewController*  numberCountriesViewController;

         numberCountriesViewController = [[NumberCountriesViewController alloc] init];

         modalViewController = [[UINavigationController alloc] initWithRootViewController:numberCountriesViewController];
         modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

         [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                                animated:YES
                                                              completion:nil];
     }];
}


#pragma mark - Fail UI Actions

- (IBAction)failCancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)failCloseAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
