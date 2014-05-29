//
//  VerifyPhoneViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 02/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "VerifyPhoneViewController.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "Settings.h"
#import "Strings.h"
#import "WebClient.h"
#import "CallManager.h"
#import "Skinning.h"


@interface VerifyPhoneViewController ()

@property (nonatomic, strong) PhoneNumber* phoneNumber;
@property (nonatomic, strong) NSString*    numberButtonTitle;
@property (nonatomic, copy)   void       (^completion)(PhoneNumber* phoneNumber);
@property (nonatomic, assign) BOOL         isCancelled;
@property (nonatomic, assign) int          step;

@end


@implementation VerifyPhoneViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber))completion
{
    if (self = [super initWithNibName:@"VerifyPhoneView" bundle:nil])
    {
        self.completion = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setStep:1];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"VerifyPhone BarTitle", nil,
                                                                  [NSBundle mainBundle], @"Verify Number",
                                                                  @"...");

    self.textLabel.text       = NSLocalizedStringWithDefaultValue(@"VerifyPhone", nil, [NSBundle mainBundle],
                                                                  @"To verify, enter your number (A). Then, request to "
                                                                  @"be called (B). Finally, enter the code (C) "
                                                                  @"on the keypad of your phone. (The small cost for "
                                                                  @"this call is taken from your credit.)",
                                                                  @"...");

    [self.numberButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Verify EnterNumberTitle", nil,
                                                                  [NSBundle mainBundle], @"Enter Number",
                                                                  @"...")
                       forState:UIControlStateNormal];

    self.numberButtonTitle = self.numberButton.titleLabel.text;

    [self.callButton setTitle:NSLocalizedStringWithDefaultValue(@"Provisioning:Verify CallMeTitle", nil,
                                                                [NSBundle mainBundle], @"Call Me",
                                                                @"...")
                     forState:UIControlStateNormal];

    [Common setCornerRadius:5 ofView:self.step1View];
    [Common setCornerRadius:5 ofView:self.step2View];
    [Common setCornerRadius:5 ofView:self.step3View];

    self.step1View.backgroundColor = [Skinning backgroundTintColor];
    self.step2View.backgroundColor = [Skinning backgroundTintColor];
    self.step3View.backgroundColor = [Skinning backgroundTintColor];
}


- (void)willMoveToParentViewController:(UIViewController*)parent
{
    if (parent == nil && self.completion != nil)
    {
        // We get here when user pops this view via navigation controller.
        self.isCancelled = YES;

        WebClient* webClient = [WebClient sharedClient];

        [webClient cancelAllRetrieveVerificationCode];
        [webClient cancelAllRetrieveVerificationStatus];
        [webClient cancelAllRequestVerificationCall];
        if ([self.phoneNumber isValid] == YES)
        {
            [webClient stopVerificationForE164:[self.phoneNumber e164Format] reply:nil];
        }

        self.completion(nil);
    }
}


#pragma mark - Actions

- (void)cancel
{
}


- (IBAction)numberAction:(id)sender
{
    __block BlockAlertView* alert;
    NSString*               title;
    NSString*               message;

    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone EnterNumberTitle", nil,
                                                [NSBundle mainBundle], @"Enter Your Number",
                                                @"Title asking user to enter their phone number.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Enter the number of a phone you own, or are responsible for.",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    alert   = [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                                        message:message
                                                    phoneNumber:self.phoneNumber
                                                     completion:^(BOOL         cancelled,
                                                                  PhoneNumber* phoneNumber)
    {
        if (cancelled == NO)
        {
            [self setStep:1];
            self.codeLabel.text = NSLocalizedStringWithDefaultValue(@"VerifyPhone CodeTitle", nil,
                                                                    [NSBundle mainBundle], @"CODE",
                                                                    @".\n"
                                                                    @"[iOS alert title size].");
            self.phoneNumber = phoneNumber;

            if ([phoneNumber isValid])
            {
                [self.numberButton setTitle:[phoneNumber internationalFormat] forState:UIControlStateNormal];

                [self.codeActivityIndicator startAnimating];
                WebClient* webClient = [WebClient sharedClient];
                [webClient retrieveVerificationCodeForE164:[phoneNumber e164Format]
                                                     reply:^(NSError* error, NSString* code)
                {
                    if (self.isCancelled)
                    {
                        return;
                    }

                    [self.codeActivityIndicator stopAnimating];
                    if (error == nil)
                    {
                        self.codeLabel.text = code;
                        [self setStep:2];
                    }
                    else
                    {
                        NSString* title;
                        NSString* message;

                        title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCodeErrorTitle", nil,
                                                                    [NSBundle mainBundle], @"Couldn't Get Code",
                                                                    @"Something went wrong.\n"
                                                                    @"[iOS alert title size].");
                        message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCodeErrorMessage", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Failed to get a verification code.\n\n"
                                                                    @"Please try again later.",
                                                                    @"Alert message if user wants.\n"
                                                                    @"[iOS alert message size]");
                        [BlockAlertView showAlertViewWithTitle:title
                                                       message:message
                                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
                        {
                            self.completion(nil);
                            self.completion = nil;
                            [self.navigationController popViewControllerAnimated:YES];
                        }
                                             cancelButtonTitle:[Strings closeString]
                                             otherButtonTitles:nil];
                    }
                }];
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyInvalidTitle", nil,
                                                            [NSBundle mainBundle], @"Invalid Number",
                                                            @"Phone number is not correct.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyInvalidMessage", nil,
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

                [self.numberButton setTitle:self.numberButtonTitle forState:UIControlStateNormal];
            }
        }
    }
                                              cancelButtonTitle:[Strings cancelString]
                                              otherButtonTitles:[Strings okString], nil];

    [self buttonUp:self.numberButton];
}


- (IBAction)callAction:(id)sender
{
    WebClient* webClient = [WebClient sharedClient];

    [self setStep:3];

    // Initiate call.
    [webClient requestVerificationCallForE164:[self.phoneNumber e164Format] reply:^(NSError* error)
    {
        if (self.isCancelled)
        {
            return;
        }

        if (error == nil)
        {
            // We get here when the user either answered or declined the call.
            [Common dispatchAfterInterval:1.0 onMain:^
            {
                [self checkVerifyStatusWithRepeatCount:30];
            }];
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone CallFailedTitle", nil,
                                                        [NSBundle mainBundle], @"Failed To Call",
                                                        @"Calling the user failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"VerifyPhone CallFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Calling you, to enter the verification code, failed.\n\n"
                                                        @"Please try again later.",
                                                        @"Alert message that calling the user failed.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                self.completion(nil);
                self.completion = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];

    [self buttonUp:self.callButton];
}


- (IBAction)buttonDown:(id)sender
{
    if (sender == self.numberButton)
    {
        self.step1View.backgroundColor = [Skinning tintColor];
        self.label1.textColor          = [UIColor whiteColor];
    }
    else
    {
        self.step2View.backgroundColor = [Skinning tintColor];
        self.label2.textColor          = [UIColor whiteColor];
    }
}


- (IBAction)buttonUp:(id)sender
{
    if (sender == self.numberButton)
    {
        self.step1View.backgroundColor = [Skinning backgroundTintColor];
        self.label1.textColor = (self.step == 1) ? [Skinning tintColor] : [UIColor whiteColor];
    }
    else
    {
        self.step2View.backgroundColor = [Skinning backgroundTintColor];
        self.label2.textColor = (self.step == 2) ? [Skinning tintColor] : [UIColor whiteColor];
    }
}


- (void)showNumberNotVerifiedAlert
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone NotVerifiedTitle", nil,
                                                [NSBundle mainBundle], @"Number Not Verified",
                                                @"The user's phone number was not verified.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone NotVerifiedMessage", nil,
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
         [self setStep:2];
     }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)checkVerifyStatusWithRepeatCount:(int)count
{
    WebClient* webClient = [WebClient sharedClient];

    if (--count == 0)
    {
        [self showNumberNotVerifiedAlert];

        return;
    }

    [webClient retrieveVerificationStatusForE164:[self.phoneNumber e164Format]
                                           reply:^(NSError* error, BOOL calling, BOOL verified)
    {
        if (self.isCancelled)
        {
            return;
        }

        if (error == nil)
        {
            if (verified == YES)
            {
                self.completion(self.phoneNumber);
                self.completion = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
            else if (calling == NO)
            {
                [self showNumberNotVerifiedAlert];
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
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorTitle", nil,
                                                        [NSBundle mainBundle], @"Verification Check Failed",
                                                        @"Something went wrong.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Failed to check if verification is ready.\n\n"
                                                        @"Please try again, later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                self.completion(nil);
                self.completion = nil;
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)setStep:(int)step
{
    switch (step)
    {
        case 1:
        {
            self.numberButton.userInteractionEnabled = YES;
            self.callButton.userInteractionEnabled   = NO;

            self.label1.textColor = [Skinning tintColor];
            self.label2.textColor = [UIColor whiteColor];
            self.label3.textColor = [UIColor whiteColor];

            [self setColor:[Skinning tintColor] forButton:self.numberButton];
            [self setColor:[UIColor whiteColor] forButton:self.callButton];
            self.codeLabel.textColor = [UIColor whiteColor];

            [self.callActivityIndicator stopAnimating];
            break;
        }
        case 2:
        {
            self.numberButton.userInteractionEnabled = YES;
            self.callButton.userInteractionEnabled   = YES;

            self.label1.textColor = [UIColor whiteColor];
            self.label2.textColor = [Skinning tintColor];
            self.label3.textColor = [UIColor whiteColor];

            [self setColor:[Skinning tintColor] forButton:self.numberButton];
            [self setColor:[Skinning tintColor] forButton:self.callButton];
            self.codeLabel.textColor = [UIColor blackColor];

            [self.callActivityIndicator stopAnimating];
            break;
        }
        case 3:
        {
            self.numberButton.userInteractionEnabled = NO;
            self.callButton.userInteractionEnabled   = NO;

            self.label1.textColor = [UIColor whiteColor];
            self.label2.textColor = [UIColor whiteColor];
            self.label3.textColor = [UIColor blackColor];

            [self setColor:[UIColor whiteColor] forButton:self.numberButton];
            [self setColor:[UIColor whiteColor] forButton:self.callButton];
            self.codeLabel.textColor = [UIColor blackColor];

            [self.callActivityIndicator startAnimating];
            break;
        }
    }

    _step = step;
}


- (void)setColor:(UIColor*)color forButton:(UIButton*)button
{
    [button setTitleColor:color forState:UIControlStateNormal];
}

@end
