//
//  VerifyPhoneVoiceEnterViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/03/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "VerifyPhoneVoiceEnterViewController.h"
#import "VerifyPhoneVoiceCallViewController.h"
#import "CountriesViewController.h"
#import "BlockAlertView.h"
#import "PhoneNumberTextFieldDelegate.h"
#import "Common.h"
#import "Settings.h"
#import "Strings.h"
#import "WebClient.h"
#import "CallManager.h"
#import "Skinning.h"
#import "NSTimer+Blocks.h"
#import "PhoneNumber.h"
#import "CountryNames.h"


typedef enum
{
    TableSectionNumber = 1UL << 0,
} TableSections;

typedef enum
{
    NumberRowCountry   = 1UL << 0,
    NumberRowNumber    = 1UL << 1,
} NumberRows;


@interface VerifyPhoneVoiceEnterViewController ()

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) NumberRows    numberRows;

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
@property (nonatomic, strong) NSString*    uuid;
@property (nonatomic, strong) NSString*    numberButtonTitle;
@property (nonatomic, copy)   void       (^completion)(PhoneNumber* verifiedPhoneNumber, NSString* uuid);
@property (nonatomic, assign) BOOL         isCancelled;
@property (nonatomic, assign) int          step;

@property (nonatomic, strong) PhoneNumberTextFieldDelegate* phoneNumberTextFieldDelegate;
@property (nonatomic, strong) NSString*                     isoCountryCode;

@property (nonatomic, strong) UITableViewCell*              numberCell;

@end


@implementation VerifyPhoneVoiceEnterViewController

- (instancetype)initWithCompletion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.completion     = completion;

        self.isoCountryCode = [Settings sharedSettings].homeIsoCountryCode;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [Strings numberString];

    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = buttonItem;

    [self setStep:1];

    self.textLabel.text       = NSLocalizedStringWithDefaultValue(@"VerifyPhone", nil, [NSBundle mainBundle],
                                                                  @"To verify your number:\n"
                                                                  @"A. Enter your phone number,\n"
                                                                  @"B. Remember the code,\n"
                                                                  @"C. Request call & enter code.\n"
                                                                  @"This verification call requires some "
                                                                  @"of your Credit.",
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


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    UITextField* textField = self.phoneNumberTextFieldDelegate.textField;
    [textField becomeFirstResponder];
    if (textField.text.length > 0)
    {
        [textField selectAll:nil];
    }

    [textField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}


- (void)textFieldDidChange:(UITextField*)textField
{
    if (self.phoneNumberTextFieldDelegate.phoneNumber.isValid)
    {
        [self pushCallViewController];
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections   |= TableSectionNumber;

    self.numberRows |= NumberRowCountry;
    self.numberRows |= NumberRowNumber;

    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumber: numberOfRows = [Common bitsSetCount:self.numberRows]; break;
    }

    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumber: title = NSLocalizedString(@"Enter your phone number", @""); break;
    }

    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumber: cell = [self numberCellForRowAtIndexPath:indexPath]; break;
    }
    
    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumber:
        {
            switch ([Common nthBitSet:indexPath.row inValue:self.numberRows])
            {
                case NumberRowCountry:
                {
                    CountriesViewController* countriesViewController;
                    countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:self.isoCountryCode
                                                                                                title:[Strings homeCountryString]
                                                                                           completion:^(BOOL      cancelled,
                                                                                                        NSString* isoCountryCode)
                    {
                        if (cancelled == NO)
                        {
                            self.isoCountryCode = isoCountryCode;

                            // Set the cell to prevent quick update right after animations.
                            cell.imageView.image      = [UIImage imageNamed:self.isoCountryCode];
                            cell.textLabel.text       = nil;
                            cell.detailTextLabel.text = [self numberCellDetailText];

                            NSString* number = self.phoneNumberTextFieldDelegate.phoneNumber.number;
                            self.phoneNumberTextFieldDelegate.phoneNumber = [[PhoneNumber alloc] initWithNumber:number
                                                                                                 isoCountryCode:self.isoCountryCode];
                            [self.phoneNumberTextFieldDelegate update];
                        }
                    }];

                    [self.navigationController pushViewController:countriesViewController animated:YES];

                    break;
                }
                case NumberRowNumber:
                {
                    if (self.phoneNumberTextFieldDelegate.phoneNumber.isValid)
                    {
                        [self pushCallViewController];
                    }
                    else
                    {
                        [tableView deselectRowAtIndexPath:indexPath animated:YES];
                    }
                    break;
                }
            }
            break;
        }
    }
}


#pragma mark - Cell Methods

- (NSString*)numberCellDetailText
{
    if (self.isoCountryCode != nil)
    {
        NSString* name        = [[CountryNames sharedNames] nameForIsoCountryCode:self.isoCountryCode];
        NSString* callingCode = [Common callingCodeForCountry:self.isoCountryCode];

        return [NSString stringWithFormat:@"%@ +%@", name, callingCode];
    }
    else
    {
        return nil;
    }
}


- (UITableViewCell*)numberCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    switch ([Common nthBitSet:indexPath.row inValue:self.numberRows])
    {
        case NumberRowCountry: identifier = @"CountryCell"; break;
        case NumberRowNumber:  identifier = @"NumberCell";  break;
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    switch ([Common nthBitSet:indexPath.row inValue:self.numberRows])
    {
        case NumberRowCountry:
        {
            if (self.isoCountryCode != nil)
            {
                cell.imageView.image = [UIImage imageNamed:self.isoCountryCode];
                cell.textLabel.text  = nil;
            }
            else
            {
                cell.imageView.image = nil;
                cell.textLabel.text  = NSLocalizedString(@"No Country Selected", @""); // TODO: Same string used elsewhere, combine!
            }

            cell.detailTextLabel.text = [self numberCellDetailText];
            cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;

            break;
        }
        case NumberRowNumber:
        {
            self.numberCell = cell;
            cell.textLabel.text = [Strings numberString];

            UITextField* textField = (UITextField*)[cell viewWithTag:CommonTextFieldCellTag];

            if (textField == nil)
            {
                textField = [Common addTextFieldToCell:cell delegate:nil];
                self.phoneNumberTextFieldDelegate = [[PhoneNumberTextFieldDelegate alloc] initWithTextField:textField];
                self.phoneNumberTextFieldDelegate.phoneNumber = [[PhoneNumber alloc] initWithNumber:@""
                                                                                     isoCountryCode:self.isoCountryCode];

                textField.delegate     = self.phoneNumberTextFieldDelegate;
                textField.keyboardType = UIKeyboardTypeNumberPad;
                textField.tag          = CommonTextFieldCellTag;
            }

            break;
        }
    }

    return cell;
}


- (void)willMoveToParentViewController:(UIViewController*)parent
{
    if (parent == nil && self.completion != nil)
    {
        // We get here when user pops this view via navigation controller.
        self.isCancelled = YES;

        if (self.uuid != nil)
        {
            [[WebClient sharedClient] cancelAllRetrievePhoneVerificationCode];
            [[WebClient sharedClient] cancelAllRetrievePhoneVerificationStatusForUuid:self.uuid];
            [[WebClient sharedClient] cancelAllRequestPhoneVerificationCallForUuid:self.uuid];
            if ([self.phoneNumber isValid] == YES)
            {
                [[WebClient sharedClient] stopPhoneVerificationForUuid:self.uuid reply:nil];
            }
        }

        self.completion(nil, nil);
    }
}


#pragma mark - Helpers

- (void)pushCallViewController
{
    VerifyPhoneVoiceCallViewController* viewController;
    viewController = [[VerifyPhoneVoiceCallViewController alloc] initWithPhoneNumber:self.phoneNumber
                                                                          completion:^(PhoneNumber* verifiedPhoneNumber,
                                                                                       NSString*    uuid)
                      {
                          [self.navigationController popViewControllerAnimated:YES];
                      }];

    [self.navigationController pushViewController:viewController animated:YES];
}


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
                                                @"Enter the number of a fixed-line or mobile phone you own, or are "
                                                @"explicitly allowed to use by its owner.",
                                                @"Message explaining about the phone number they need to enter.\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showPhoneNumberAlertViewWithTitle:title
                                              message:message
                                          phoneNumber:self.phoneNumber
                                           completion:^(BOOL         cancelled,
                                                        PhoneNumber* phoneNumber)
     {
         if (cancelled == NO && phoneNumber.number.length > 0)
         {
             // Check if this Phone already exists on the user's account.
             [[WebClient sharedClient] beginPhoneVerificationForE164:[phoneNumber e164Format]
                                                                mode:@"voice"
                                                               reply:^(NSError*  error,
                                                                       NSString* uuid,    // This UUID ignored.
                                                                       BOOL      verified,
                                                                       NSString* code,
                                                                       NSArray*  languages)
              {
                  if (error == nil && verified == NO)
                  {
                      completion(phoneNumber);

                      return;
                  }
                  else if (error == nil && verified == YES)
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
                       [self.navigationController popViewControllerAnimated:YES];
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

- (void)cancelAction
{
    self.completion = nil;

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (IBAction)callAction:(id)sender
{
    [self setStep:4];

    // Initiate call.
    [[WebClient sharedClient] requestPhoneVerificationCallForUuid:self.uuid reply:^(NSError* error)
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
                  self.completion(nil, nil);
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
    if (--count == 0)
    {
        [self showNumberNotVerifiedAlert];

        return;
    }

    [[WebClient sharedClient] retrievePhoneVerificationStatusForUuid:self.uuid
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
                 self.completion(self.phoneNumber, self.uuid);
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
                  self.completion(nil, nil);
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
