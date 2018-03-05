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
#import "UIViewController+Common.h"


typedef enum
{
    TableSectionNumber = 1UL << 0,
    TableSectionVerify = 1UL << 1,
} TableSections;

typedef enum
{
    NumberRowCountry   = 1UL << 0,
    NumberRowNumber    = 1UL << 1,
} NumberRows;


@interface VerifyPhoneVoiceEnterViewController ()

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) NumberRows    numberRows;

@property (nonatomic, strong) NSString*    uuid;
@property (nonatomic, strong) NSArray*     languages;
@property (nonatomic, assign) NSUInteger   codeLength;
@property (nonatomic, copy)   void       (^completion)(PhoneNumber* verifiedPhoneNumber, NSString* uuid);
@property (nonatomic, assign) BOOL         isCancelled;
@property (nonatomic, assign) BOOL         allowCancel;

@property (nonatomic, strong) PhoneNumberTextFieldDelegate* phoneNumberTextFieldDelegate;
@property (nonatomic, strong) NSString*                     isoCountryCode;

@property (nonatomic, strong) UITableViewCell*              numberCell;

@end


@implementation VerifyPhoneVoiceEnterViewController

- (instancetype)initWithAllowCancel:(BOOL)allowCancel
                         completion:(void (^)(PhoneNumber* verifiedPhoneNumber, NSString* uuid))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.completion     = completion;
        self.allowCancel    = allowCancel;
        self.isoCountryCode = [Settings sharedSettings].homeIsoCountryCode;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [Strings numberString];

    if (self.allowCancel)
    {
        UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
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
    static BOOL isValid;

    if (isValid != [self isNumberValid])
    {
        isValid = [self isNumberValid];

        NSMutableIndexSet* indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:[Common nOfBit:TableSectionVerify inValue:self.sections]];

        [self.tableView beginUpdates];
        [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];

        textField.textColor = isValid ? [Skinning tintColor] : [Skinning deleteTintColor];
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections   |= TableSectionNumber;
    self.sections   |= TableSectionVerify;

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
        case TableSectionVerify: numberOfRows = 1;
    }

    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumber:
        {
            if (self.allowCancel)
            {
                title = NSLocalizedString(@"1. Enter Your Number", @"");
            }
            else
            {
                title = NSLocalizedString(@"1. Enter Your Mobile Number", @"");
            }
            break;
        }
        case TableSectionVerify:
        {
            title = NSLocalizedString(@"2. Verify Your Number", @""); break;
        }
    }

    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumber: cell = [self numberCellForRowAtIndexPath:indexPath]; break;
        case TableSectionVerify: cell = [self verifyCellForRowAtIndexPath:indexPath]; break;
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

                            [self textFieldDidChange:self.phoneNumberTextFieldDelegate.textField];
                        }
                    }];

                    [self.navigationController pushViewController:countriesViewController animated:YES];

                    break;
                }
                case NumberRowNumber:
                {
                    if ([self isNumberValid])
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
        case TableSectionVerify:
        {
            if ([self isNumberValid])
            {
                [self performVerification];
            }
            else
            {
                [self showNumberInvalidAlertWithIndexPath:indexPath];
            }
        }
    }
}


- (void)performVerification
{
    [self.tableView endEditing:YES];

    // Add delay to prevent a ghost keyboard to appear briefly in case of error when the alert is closed and the
    // view is dismissed.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self getVerificationData:^(NSString* uuid, NSArray* languages, NSUInteger codeLength)
        {
            self.uuid       = uuid;
            self.languages  = languages;
            self.codeLength = codeLength;

            [self pushCallViewController];
        }];
    });
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

            textField.textColor = [self isNumberValid] ? [Skinning tintColor] : [Skinning deleteTintColor];

            break;
        }
    }

    return cell;
}


- (UITableViewCell*)verifyCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier = @"VerifyCell";

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    cell.textLabel.text    = [Strings verifyString];
    cell.accessoryType     = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.enabled = [self isNumberValid];

    return cell;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}


- (void)willMoveToParentViewController:(UIViewController*)parent
{
    // We get here when user pops this view via navigation controller.
    if (parent == nil && self.completion != nil)
    {
        [self cancel];
    }
}


#pragma mark - Helpers

- (void)cancel
{
    self.isCancelled = YES;

    [[WebClient sharedClient] cancelAllRetrievePhoneVerificationCode];
    if (self.uuid != nil)
    {
        [[WebClient sharedClient] stopPhoneVerificationForUuid:self.uuid reply:nil];
    }
}


- (void)getVerificationData:(void (^)(NSString* uuid, NSArray* languages, NSUInteger codeLength))completion
{
    __block NSString* title;
    __block NSString* message;

    self.isLoading = YES;

    // Check if this Phone already exists on the user's account.
    NSString* e164 = [self.phoneNumberTextFieldDelegate.phoneNumber e164Format];
    [[WebClient sharedClient] beginPhoneVerificationForE164:e164
                                                       mode:@"voice"
                                                      reply:^(NSError*  error,
                                                              NSString* uuid,
                                                              BOOL      verified,
                                                              NSString* code,
                                                              NSArray*  languageCodes)
    {
        self.isLoading = NO;

        if (error == nil && verified == NO)
        {
            completion(uuid, languageCodes, code.length);

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
                                                        @"Couldn't Start Verification", @"...");
            message = NSLocalizedStringWithDefaultValue(@"VerifyPhone KnownMessage", nil, [NSBundle mainBundle],
                                                        @"Something went wrong while starting the verification: %@\n\n"
                                                        @"Please try again later.", @"...");
            message = [NSString stringWithFormat:message, error.localizedDescription];
        }

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (self.allowCancel)
            {
                [self cancelAction];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }];
}


- (BOOL)isNumberValid
{
    if (self.allowCancel)
    {
        return self.phoneNumberTextFieldDelegate.phoneNumber.isValid &&
               (self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeFixedLine         ||
                self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeMobile            ||
                self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeFixedLineOrMobile ||
                self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeUnknown);
    }
    else
    {
        return self.phoneNumberTextFieldDelegate.phoneNumber.isValid &&
               (self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeMobile            ||
                self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeFixedLineOrMobile ||
                self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeUnknown);
    }
}


- (void)pushCallViewController
{
    VerifyPhoneVoiceCallViewController* viewController;
    viewController = [[VerifyPhoneVoiceCallViewController alloc] initWithPhoneNumber:self.phoneNumberTextFieldDelegate.phoneNumber
                                                                                uuid:self.uuid
                                                                           languageCodes:self.languages
                                                                          codeLength:self.codeLength
                                                                         allowCancel:self.allowCancel
                                                                          completion:^(BOOL isVerified)
    {
        self.completion(self.phoneNumberTextFieldDelegate.phoneNumber, self.uuid);
        self.completion = nil;

        [self.navigationController popViewControllerAnimated:YES];
    }];

    [self.navigationController pushViewController:viewController animated:YES];
}


- (void)showNumberInvalidAlertWithIndexPath:(NSIndexPath*)indexPath
{
    NSString* title;
    NSString* message;

    if (self.phoneNumberTextFieldDelegate.phoneNumber.number.length == 0)
    {
        title   = NSLocalizedString(@"No Number Entered", @"");
        message = NSLocalizedString(@"Please, first enter your number above, then tap here again to verify it.", @"");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        title   = NSLocalizedString(@"Number Seems Invalid", @"");
        message = NSLocalizedString(@"The number you entered seems invalid.\n\n"
                                    @"Tap %@ if the number you entered is indeed valid, or else tap %@ to correct the number.", @"");
        message = [NSString stringWithFormat:message, [Strings verifyString], [Strings closeString]];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (cancelled)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            else
            {
                [self performVerification];
            }
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:[Strings verifyString], nil];
    }
}


#pragma mark - Actions

- (void)cancelAction
{
    self.completion = nil;

    [self cancel];

    [self.phoneNumberTextFieldDelegate.textField resignFirstResponder];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
