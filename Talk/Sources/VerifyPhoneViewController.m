//
//  VerifyPhoneViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 02/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "VerifyPhoneViewController.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "Settings.h"
#import "Strings.h"
#import "WebClient.h"
#import "CallManager.h"
#import "Skinning.h"
#import "NSTimer+Blocks.h"


@interface VerifyPhoneViewController ()

@property (nonatomic, weak) IBOutlet UILabel*                 textLabel;
@property (nonatomic, weak) IBOutlet UIView*                  step1View;
@property (nonatomic, weak) IBOutlet UIView*                  step2View;
@property (nonatomic, weak) IBOutlet UIView*                  step3View;
@property (nonatomic, weak) IBOutlet UILabel*                 label1;
@property (nonatomic, weak) IBOutlet UILabel*                 label2;
@property (nonatomic, weak) IBOutlet UILabel*                 label3;
@property (nonatomic, weak) IBOutlet UIButton*                numberButton;
@property (nonatomic, weak) IBOutlet UIButton*                callButton;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* callActivityIndicator;
@property (nonatomic, weak) IBOutlet UILabel*                 codeLabel;
@property (nonatomic, weak) IBOutlet UIActivityIndicatorView* codeActivityIndicator;

@property (nonatomic, strong) PhoneNumber* phoneNumber;
@property (nonatomic, strong) NSString*    numberButtonTitle;
@property (nonatomic, copy)   void       (^completion)(PhoneNumber* phoneNumber);
@property (nonatomic, assign) BOOL         isCancelled;
@property (nonatomic, assign) int          step;
@property (nonatomic, strong) NSTimer*     codeTimer;
@property (nonatomic, assign) int          codeDigitsShown;

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
                                                                  @"To verify your number:\n"
                                                                  @"A. Enter your phone number,\n"
                                                                  @"B. Remember the code,\n"
                                                                  @"C. Request call & enter code.\n"
                                                                  @"The small cost for "
                                                                  @"this call is taken from your credit.",
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
        
        [self.codeTimer invalidate];
        self.codeTimer = nil;

        WebClient* webClient = [WebClient sharedClient];

        [webClient cancelAllRetrievePhoneVerificationCode];
        [webClient cancelAllRetrievePhoneVerificationStatus];
        [webClient cancelAllRequestPhoneVerificationCall];
        if ([self.phoneNumber isValid] == YES)
        {
            [webClient stopPhoneVerificationForE164:[self.phoneNumber e164Format] reply:nil];
        }

        self.completion(nil);
    }
}


#pragma mark - Helpers

- (void)getNumberWithCompletion:(void (^)(PhoneNumber* phoneNumber))completion
{
    __block NSString* title;
    __block NSString* message;
    
    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone EnterNumberTitle", nil,
                                                [NSBundle mainBundle], @"Enter Your Number",
                                                @"Title asking user to enter their phone number.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCancelMessage", nil,
                                                [NSBundle mainBundle],
                                                @"Enter the number of a phone you own, or are responsible for.",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                              message:message
                                          phoneNumber:self.phoneNumber
                                           completion:^(BOOL         cancelled,
                                                        PhoneNumber* phoneNumber)
    {
        if (cancelled == NO)
        {
            [[WebClient sharedClient] retrievePhoneWithE164:phoneNumber.e164Format reply:^(NSError *error, NSString *name)
            {
                if (error.code == WebStatusFailPhoneUnknown)
                {
                    completion(phoneNumber);
                    
                    return;
                }
                else if (error == nil)
                {
                    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone KnownTitle", nil, [NSBundle mainBundle],
                                                                @"Already Verified", @"...");
                    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone KnownMessage", nil, [NSBundle mainBundle],
                                                                @"You verified this Phone earlier.\n\n"
                                                                @"Please pull to refresh your Phones if you "
                                                                @"don't see it in the list.", @"...");
                }
                else
                {
                    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone KnownTitle", nil, [NSBundle mainBundle],
                                                                @"Couldn't Check Number", @"...");
                    message = NSLocalizedStringWithDefaultValue(@"VerifyPhone KnownMessage", nil, [NSBundle mainBundle],
                                                                @"Failed to check if you already verified this number: %@\n\n"
                                                                @"Please try again laeter.", @"...");
                    message = [NSString stringWithFormat:message, error.localizedDescription];
                }
                
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    // Without delay a 'ghost' keyboard may appear briefly: http://stackoverflow.com/q/32095734/1971013
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                    });
                }
                                     cancelButtonTitle:[Strings cancelString]
                                     otherButtonTitles:nil];
            }];
        }
    }
                                    cancelButtonTitle:[Strings cancelString]
                                    otherButtonTitles:[Strings okString], nil];
}


#pragma mark - Actions

- (IBAction)numberAction:(id)sender
{
    [self getNumberWithCompletion:^(PhoneNumber *phoneNumber)
    {
        [self setStep:1];
        self.phoneNumber = phoneNumber;

        if ([phoneNumber isValid])
        {
            [self.numberButton setTitle:[phoneNumber internationalFormat] forState:UIControlStateNormal];

            self.codeDigitsShown = 0;
            [self.codeTimer invalidate];
            self.codeTimer = nil;
            
            [self.codeActivityIndicator startAnimating];
            WebClient* webClient = [WebClient sharedClient];
            [webClient retrievePhoneVerificationCodeForE164:[phoneNumber e164Format]
                                                      reply:^(NSError* error, NSString* code)
            {
                if (self.isCancelled)
                {
                    return;
                }

                [self setStep:2];

                [self.codeActivityIndicator stopAnimating];
                if (error == nil)
                {
                    self.codeTimer = [NSTimer scheduledTimerWithTimeInterval:0.7 repeats:YES block:^(NSTimer * _Nonnull timer)
                    {
                        self.codeDigitsShown++;
                        self.codeLabel.text = [code substringToIndex:self.codeDigitsShown];
                        for (int n = self.codeDigitsShown; n < code.length; n++)
                        {
                            self.codeLabel.text = [self.codeLabel.text stringByAppendingString:@"-"];
                        }
                        
                        if (self.codeDigitsShown == code.length)
                        {
                            [self.codeTimer invalidate];
                            self.codeTimer = nil;
                            
                            [self setStep:3];
                        }
                    }];
                }
                else
                {
                    NSString* title;
                    NSString* message;

                    title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCodeErrorTitle", nil,
                                                                [NSBundle mainBundle], @"Couldn't Get Code",
                                                                @"Something went wrong.\n"
                                                                @"[iOS alert title size].");
                    if (error.code == WebStatusFailE164Disallowed)
                    {
                        message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCodeErrorMessage", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Failed to get a verification code: %@",
                                                                    @"Alert message if user wants.\n"
                                                                    @"[iOS alert message size]");
                    }
                    else
                    {
                        message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCodeErrorMessage", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Failed to get a verification code: %@\n\n"
                                                                    @"Please try again later.",
                                                                    @"Alert message if user wants.\n"
                                                                    @"[iOS alert message size]");
                    }

                    message = [NSString stringWithFormat:message, error.localizedDescription];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        self.completion(nil);
                        self.completion = nil;

                        // Without this delay, a keyboard appears briefly after popping.
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
                                       dispatch_get_main_queue(),
                                       ^
                        {
                            [self.navigationController popViewControllerAnimated:YES];
                        });
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
    }];

    [self buttonUp:self.numberButton];
}


- (IBAction)callAction:(id)sender
{
    WebClient* webClient = [WebClient sharedClient];

    [self setStep:4];

    // Initiate call.
    [webClient requestPhoneVerificationCallForE164:[self.phoneNumber e164Format] reply:^(NSError* error)
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
                                                        @"Calling you, to enter the verification code, failed: %@\n\n"
                                                        @"Please try again later.",
                                                        @"Alert message that calling the user failed.\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
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
        self.step3View.backgroundColor = [Skinning tintColor];
        self.label3.textColor          = [UIColor whiteColor];
    }
}


- (IBAction)buttonUp:(id)sender
{
    if (sender == self.numberButton)
    {
        [self setStep:1];
        self.step1View.backgroundColor = [Skinning backgroundTintColor];
        self.label1.textColor = (self.step == 1) ? [Skinning tintColor] : [UIColor whiteColor];
    }
    else
    {
        self.step3View.backgroundColor = [Skinning backgroundTintColor];
        self.label3.textColor = ((self.step == 3) || (self.step == 4)) ? [Skinning tintColor] : [UIColor whiteColor];
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
        [self setStep:3];
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

    [webClient retrievePhoneVerificationStatusForE164:[self.phoneNumber e164Format]
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
            self.codeLabel.textColor = [UIColor whiteColor];
            self.codeLabel.text = @"----";
            [self setColor:[UIColor whiteColor] forButton:self.callButton];

            [self.callActivityIndicator stopAnimating];
            break;
        }
        case 2:
        {
            self.numberButton.userInteractionEnabled = YES;
            self.callButton.userInteractionEnabled   = NO;

            self.label1.textColor = [UIColor grayColor];
            self.label2.textColor = [Skinning tintColor];
            self.label3.textColor = [UIColor whiteColor];

            [self setColor:[UIColor grayColor] forButton:self.numberButton];
            self.codeLabel.textColor = [Skinning tintColor];
            [self setColor:[UIColor whiteColor] forButton:self.callButton];

            [self.callActivityIndicator stopAnimating];
            break;
        }
        case 3:
        {
            self.numberButton.userInteractionEnabled = NO;
            self.callButton.userInteractionEnabled   = YES;

            self.label1.textColor = [UIColor grayColor];
            self.label2.textColor = [UIColor grayColor];
            self.label3.textColor = [Skinning tintColor];

            [self setColor:[UIColor grayColor] forButton:self.numberButton];
            self.codeLabel.textColor = [UIColor grayColor];
            [self setColor:[Skinning tintColor] forButton:self.callButton];
            
            [self.callActivityIndicator stopAnimating];
            break;
        }
        case 4:
        {
            self.numberButton.userInteractionEnabled = NO;
            self.callButton.userInteractionEnabled   = NO;

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
