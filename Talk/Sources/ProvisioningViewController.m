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
#import "Strings.h"
#import "Common.h"
#import "WebClient.h"
#import "Settings.h"
#import "CreditViewController.h"
#import "NumberCountriesViewController.h"
#import "AppDelegate.h"
#import "CallManager.h"


@interface ProvisioningViewController ()
{
    UIView*         currentView;

    NSString*       readyBuyText;                   // New user.
    NSString*       readyRestoreNoNumbersText;      // Existing user with no numbers yet.
    NSString*       readyRestoreHasNumberText;      // Existing user with only one number.
    NSString*       readyRestoreHasNumbersText;     // Existing user with multiple numbers.

    PhoneNumber*    verifyPhoneNumber;
    NSString*       verifyNumberButtonTitle;

    BOOL            isNewUser;
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
                                                                @"and your phone number needs to be verified."
                                                                @"\n\nAre you new? Buy an account, and follow "
                                                                @"the steps to verify your number. The price of the "
                                                                @"account will be your initial credit, so does not "
                                                                @"cost you extra."
                                                                @"\n\nAlready have an account? Restore your "
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
                                                                      [NSBundle mainBundle], @"Call Me",
                                                                      @"...")
                           forState:UIControlStateNormal];

    self.readyNavigationBar.topItem.title = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BarTitle", nil,
                                                                              [NSBundle mainBundle], @"Ready To Go",
                                                                              @"...");
    readyBuyText = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BuyText", nil,
                                                     [NSBundle mainBundle],
                                                     @"Welcome! With NumberBuy you're reachable in up to 50 countries. "
                                                     @"Call forwarding, for each of the geographic, national, or "
                                                     @"toll-free numbers you buy, can be changed instantly.\n\n"
                                                     @"Your initial credit is %@; you can top up now. Or, have a look "
                                                     @"at the extensive list of countries.\n\n",
                                                     @"Welcome text for a new user.");
    readyRestoreNoNumbersText = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready RestoreNoNumbersText", nil,
                                                                  [NSBundle mainBundle],
                                                                  @"Welcome back! Your current credit is %@. ...",
                                                                  @"Welcome text for existing user without telephone numbers.");
    readyRestoreHasNumberText = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready RestoreHasNumberText", nil,
                                                                  [NSBundle mainBundle],
                                                                  @"Welcome back! Your current credit is %@. ...",
                                                                  @"Welcome text for existing user without telephone numbers.");
    readyRestoreHasNumbersText = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready RestoreHasNumbersText", nil,
                                                                   [NSBundle mainBundle],
                                                                   @"Welcome back! Your current credit is %@, with %d numbers...",
                                                                   @"Welcome text for existing user without telephone numbers.");
    [self.readyCreditButton setTitle:[Strings creditString] forState:UIControlStateNormal];
    [self.readyNumberButton setTitle:[Strings numberString] forState:UIControlStateNormal];

    [Common setCornerRadius:10                     ofView:self.verifyStep1View];
    [Common setCornerRadius:10                     ofView:self.verifyStep2View];
    [Common setCornerRadius:10                     ofView:self.verifyStep3View];
    [Common setBorderWidth:0.8                     ofView:self.verifyStep1View];
    [Common setBorderWidth:0.8                     ofView:self.verifyStep2View];
    [Common setBorderWidth:0.8                     ofView:self.verifyStep3View];
    [Common setBorderColor:[UIColor darkGrayColor] ofView:self.verifyStep1View];
    [Common setBorderColor:[UIColor darkGrayColor] ofView:self.verifyStep2View];
    [Common setBorderColor:[UIColor darkGrayColor] ofView:self.verifyStep3View];

    [self.view addSubview:self.introView];
    currentView = self.introView;

    [self setIntroBusy:YES];    // Will be set to NO when products are loaded.
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
        if (success == YES)
        {
            [self setIntroBusy:NO];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    // 'Magic' Y & height values have been measured in XIB.
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
            [Common setY:28      ofView:self.verifyCallActivityIndicator];
            [Common setY:28      ofView:self.verifyCodeLabel];
            [Common setY:28      ofView:self.verifyCodeActivityIndicator];
            [Common setHeight:37 ofView:self.verifyNumberButton];
            [Common setHeight:37 ofView:self.verifyCallButton];
            [Common setHeight:37 ofView:self.verifyCodeLabel];
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
            [Common setY:39      ofView:self.verifyCallActivityIndicator];
            [Common setY:37      ofView:self.verifyCodeLabel];
            [Common setY:39      ofView:self.verifyCodeActivityIndicator];
            [Common setHeight:41 ofView:self.verifyNumberButton];
            [Common setHeight:41 ofView:self.verifyCallButton];
            [Common setHeight:41 ofView:self.verifyCodeLabel];
            break;
    }
}


#pragma mark - Utility Methods

- (void)showView:(UIView*)toShowView
{
    [Common setHeight:self.view.frame.size.height ofView:toShowView];
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


- (void)setIntroBusy:(BOOL)busy
{
    self.introRestoreButton.enabled = busy ? NO   : YES;
    self.introBuyButton.enabled     = busy ? NO   : YES;
    self.introRestoreButton.alpha   = busy ? 0.5f : 1.0f;
    self.introBuyButton.alpha       = busy ? 0.5f : 1.0f;

    if (busy == NO)
    {
        [self.introRestoreActivityIndicator stopAnimating];
        [self.introBuyActivityIndicator     stopAnimating];
    }
}


- (void)restoreCreditAndNumbers
{
    [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                      reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            [Settings sharedSettings].credit = [[content objectForKey:@"credit"] floatValue];
            [[WebClient sharedClient] retrieveNumberList:^(WebClientStatus status, id content)
            {
                if (status == WebClientStatusOk)
                {
                    //### Process & Store numbers array!
                    
                    NSArray*  numbers = content;
                    float     credit;
                    NSString* creditString;

                    credit       = [Settings sharedSettings].credit;
                    creditString = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

                    if ([PurchaseManager sharedManager].isNewAccount == YES && numbers.count == 0)
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyBuyText, creditString];
                    }
                    else if (numbers.count == 0)
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreNoNumbersText, creditString];
                    }
                    else if (numbers.count == 1)
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreHasNumberText, creditString];
                    }
                    else
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreHasNumbersText, creditString,
                                                                                                         numbers.count];
                    }

                    if ([Settings sharedSettings].verifiedE164.length == 0)
                    {
                        [self setVerifyStep:1];
                        [self showView:self.verifyView];
                    }
                    else
                    {
                        [self showView:self.readyView];
                        [[AppDelegate appDelegate] refresh];
                    }
                }
                else
                {
                    NSString*   title;
                    NSString*   message;

                    title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedNumbersTitle", nil,
                                                                [NSBundle mainBundle], @"Loading Numbers Failed",
                                                                @"Alart title: Phone numbers could not be downloaded.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedNumbersMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Your phone numbers could not be restored.\n\n"
                                                                @"Please try again later.",
                                                                @"Alert message: Phone numbers could not be downloaded.\n"
                                                                @"[iOS alert message size]");
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        [[Settings sharedSettings] resetAll];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                                         cancelButtonTitle:[Strings closeString]
                                         otherButtonTitles:nil];
                }
            }];
        }
        else
        {
            NSString*   title;
            NSString*   message;

            title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Credit Failed",
                                                        @"Alart title: Calling credit could not be downloaded.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Your credit could not be loaded.\n\n"
                                                        @"Please try again later.",
                                                        @"Alert message: Calling credit could not be loaded.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [[Settings sharedSettings] resetAll];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)setVerifyStep:(int)step
{
    self.verifyStep1View.alpha = (step >= 1) ? 1 : 0.5;
    self.verifyStep2View.alpha = (step >= 2) ? 1 : 0.5;
    self.verifyStep3View.alpha = (step >= 3) ? 1 : 0.5;

    self.verifyNumberButton.enabled = (step == 1 || step == 2) ? YES : NO;
    self.verifyCallButton.enabled   =              (step == 2) ? YES : NO;

    if (step == 3)
    {
        [self.verifyCallActivityIndicator startAnimating];
    }
    else
    {
        [self.verifyCallActivityIndicator stopAnimating];
    }
}


#pragma mark - Intro UI Actions

- (IBAction)introCancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)introBuyAction:(id)sender
{
    [self.introBuyActivityIndicator startAnimating];
    [self setIntroBusy:YES];

    [[PurchaseManager sharedManager] buyAccount:^(BOOL success, id object)
    {
        [self setIntroBusy:NO];

        if (success == YES)
        {
            [self restoreCreditAndNumbers];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if (object != nil)
        {
            NSString* title;
            NSString* message;
            
            title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedBuyTitle", nil,
                                                        [NSBundle mainBundle], @"Buying Account Failed",
                                                        @"Alart title: An account could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedBuyMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while buying your account: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that buying an account failed\n"
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
    }];
}


- (IBAction)introRestoreAction:(id)sender
{
    [self.introRestoreActivityIndicator startAnimating];
    [self setIntroBusy:YES];

    [[PurchaseManager sharedManager] restoreAccount:^(BOOL success, id object)
    {
        if (success == YES && object != nil)    // Transaction is passed, but we don't need/use that.
        {
            [self setIntroBusy:NO];

            [self restoreCreditAndNumbers];
        }
        else if (success == YES && object == nil)
        {
            [self setIntroBusy:NO];

            NSString*   title;
            NSString*   message;

            title   = NSLocalizedStringWithDefaultValue(@"Provisioning NothingToRestoreTitle", nil,
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
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
            
            [self showView:self.introView];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if (object != nil)
        {
            NSString* title;
            NSString* message;
            
            title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedRestoreTitle", nil,
                                                        [NSBundle mainBundle], @"Restoring Account Failed",
                                                        @"Alart title: An account could not be restored.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedRestoreMessage", nil,
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
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
        else
        {
            [self setIntroBusy:NO];
        }
    }];
}


#pragma mark - Verify UI Actions

- (IBAction)verifyCancelAction:(id)sender
{
    NSString*   title;
    NSString*   message;
    
    title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCancelTitle", nil,
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
                         cancelButtonTitle:[Strings noString]
                         otherButtonTitles:[Strings yesString], nil];
}


- (IBAction)verifyNumberAction:(id)sender
{
    __block BlockAlertView*  alert;
    NSString*                title;
    NSString*                message;
    
    title   = NSLocalizedStringWithDefaultValue(@"Provisioning EnterNumberTitle", nil,
                                                [NSBundle mainBundle], @"Enter Your Number",
                                                @"Title asking user to enter their phone number.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Enter a number you own; it will be linked to your account.",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    alert   = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                        message:message
                                                    phoneNumber:verifyPhoneNumber
                                                     completion:^(BOOL         cancelled,
                                                                  PhoneNumber* phoneNumber)
    {
        if (cancelled == NO)
        {
            [self setVerifyStep:1];
            self.verifyCodeLabel.text = nil;
            
            verifyPhoneNumber = phoneNumber;

            if ([phoneNumber isValid])
            {
                [self.verifyNumberButton setTitle:[phoneNumber internationalFormat] forState:UIControlStateNormal];

                [self.verifyCodeActivityIndicator startAnimating];
                WebClient* webClient = [WebClient sharedClient];
                [webClient retrieveVerificationCodeForPhoneNumber:phoneNumber
                                                       deviceName:[UIDevice currentDevice].name
                                                            reply:^(WebClientStatus status, NSString* code)
                {
                    [self.verifyCodeActivityIndicator stopAnimating];
                    if (status == WebClientStatusOk)
                    {
                        self.verifyCodeLabel.text = code;
                        [self setVerifyStep:2];
                    }
                    else
                    {
                        NSString*   title;
                        NSString*   message;
        
                        title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCodeErrorTitle", nil,
                                                                    [NSBundle mainBundle], @"Couldn't Get Code",
                                                                    @"Something went wrong.\n"
                                                                    @"[iOS alert title size].");
                        message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCodeErrorMessage", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Failed to get a verification code.\n\n"
                                                                    @"Please restore your account and try again later.",
                                                                    @"Alert message if user wants.\n"
                                                                    @"[iOS alert message size]");
                        [BlockAlertView showAlertViewWithTitle:title
                                                       message:message
                                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
                        {
                            [[Settings sharedSettings] resetAll];
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                                               cancelButtonTitle:[Strings closeString]
                                               otherButtonTitles:nil];
                    }
                }];
            }
            else
            {
                NSString*   title;
                NSString*   message;

                title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyInvalidTitle", nil,
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
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
                
                [self.verifyNumberButton setTitle:verifyNumberButtonTitle forState:UIControlStateNormal];
            }
        }
    }
                                            cancelButtonTitle:[Strings cancelString]
                                            otherButtonTitles:[Strings okString], nil];
}


- (IBAction)verifyCallAction:(id)sender
{
    WebClient* webClient = [WebClient sharedClient];

    [self setVerifyStep:3];

    // Initiate call.
    [webClient requestVerificationCallForPhoneNumber:verifyPhoneNumber
                                               reply:^(WebClientStatus status)
    {
        if (status == WebClientStatusOk)
        {
            // We get here when the user either answered or declined the call.
            [Common dispatchAfterInterval:1.0 onMain:^
            {
                [self checkVerifyStatusWithRepeatCount:12];
            }];
        }
        else
        {
            NSString*   title;
            NSString*   message;

            title   = NSLocalizedStringWithDefaultValue(@"Provisioning CallFailedTitle", nil,
                                                        [NSBundle mainBundle], @"Failed To Call",
                                                        @"Calling the user failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning CallFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Calling you, to enter the verification code, failed.\n\n"
                                                        @"Please restore your account, and try again, later.",
                                                        @"Alert message that calling the user failed.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [[Settings sharedSettings] resetAll];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)checkVerifyStatusWithRepeatCount:(int)count
{
    WebClient* webClient = [WebClient sharedClient];

    if (--count == 0)
    {
        NSString*   title;
        NSString*   message;

        //### This is a duplicate of the alert below.
        title   = NSLocalizedStringWithDefaultValue(@"Provisioning NotVerifiedTitle", nil,
                                                    [NSBundle mainBundle], @"Number Not Verified",
                                                    @"The user's phone number was not verified.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Provisioning NotVerifiedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Your number has not been verified.\n\n"
                                                    @"Make sure the phone number is correct, and that you "
                                                    @"entered the correct code.",
                                                    @"Alert message verifying the user's number failed.\n"
                                                    @"[iOS alert message size]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             [self setVerifyStep:2];
         }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return;
    }

    [webClient retrieveVerificationStatusForPhoneNumber:verifyPhoneNumber
                                                  reply:^(WebClientStatus status, BOOL calling, BOOL verified)
    {
        if (status == WebClientStatusOk)
        {
            if (verified == YES)
            {
                [Settings sharedSettings].verifiedE164 = verifyPhoneNumber.e164Format;

                [[CallManager sharedManager] resetSipAccount];

                [self showView:self.readyView];
                [[AppDelegate appDelegate] refresh];
            }
            else if (calling == NO)
            {
                NSString*   title;
                NSString*   message;

                title   = NSLocalizedStringWithDefaultValue(@"Provisioning NotVerifiedTitle", nil,
                                                            [NSBundle mainBundle], @"Number Not Verified",
                                                            @"The user's phone number was not verified.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Provisioning NotVerifiedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Your number has not been verified.\n\n"
                                                            @"Make sure the phone number is correct, and that you "
                                                            @"entered the correct code.",
                                                            @"Alert message verifying the user's number failed.\n"
                                                            @"[iOS alert message size]");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self setVerifyStep:2];
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
            else
            {
                [Common dispatchAfterInterval:1.0 onMain:^
                {
                    [self checkVerifyStatusWithRepeatCount:count];
                }];
            }
        }
        else
        {
            NSString*   title;
            NSString*   message;

            title   = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCheckErrorTitle", nil,
                                                        [NSBundle mainBundle], @"Verification Check Failed",
                                                        @"Something went wrong.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning VerifyCheckErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Failed to check if verification is ready.\n\n"
                                                        @"Please restore your account, and try again, later.",
                                                        @"Alert message if user wants.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 [[Settings sharedSettings] resetAll];
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
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
        [AppDelegate.appDelegate.tabBarController presentViewController:viewController.navigationController
                                                               animated:YES
                                                             completion:nil];
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

@end
