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
    if ([self isNumberValid])
    {
        [textField resignFirstResponder];

        // Add delay to prevent a ghost keybpard to appear briefly in case of error when the alert is closed and the
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
            [self cancelAction];
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }];
}


- (BOOL)isNumberValid
{
    return self.phoneNumberTextFieldDelegate.phoneNumber.isValid &&
           (self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeFixedLine         ||
            self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeMobile            ||
            self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeFixedLineOrMobile ||
            self.phoneNumberTextFieldDelegate.phoneNumber.type == PhoneNumberTypeUnknown);
}


- (void)pushCallViewController
{
    VerifyPhoneVoiceCallViewController* viewController;
    viewController = [[VerifyPhoneVoiceCallViewController alloc] initWithPhoneNumber:self.phoneNumberTextFieldDelegate.phoneNumber
                                                                                uuid:self.uuid
                                                                           languageCodes:self.languages
                                                                          codeLength:self.codeLength
                                                                          completion:^(BOOL isVerified)
    {
        self.completion(self.phoneNumberTextFieldDelegate.phoneNumber, self.uuid);
        self.completion = nil;

        [self.navigationController popViewControllerAnimated:YES];
    }];

    [self.navigationController pushViewController:viewController animated:YES];
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
