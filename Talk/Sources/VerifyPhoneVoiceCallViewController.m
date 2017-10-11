//
//  VerifyPhoneVoiceCallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "VerifyPhoneVoiceCallViewController.h"
#import "LanguagesViewController.h"
#import "Common.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "CellButton.h"


typedef enum
{
    TableSectionCall = 1UL << 0,
    TableSectionCode = 1UL << 1,
} TableSections;

typedef enum
{
    CallRowLanguage  = 1UL << 0,
    CallRowCallMe    = 1UL << 1,
} CallRows;


// #### GET LANGUAGE INFO
// http://stackoverflow.com/questions/5120641/how-to-get-localized-list-of-available-iphone-language-names-in-objective-c

@interface VerifyPhoneVoiceCallViewController () <UITextFieldDelegate>

@property (nonatomic, assign) TableSections    sections;
@property (nonatomic, assign) CallRows         callRows;
@property (nonatomic, strong) PhoneNumber*     phoneNumber;
@property (nonatomic, strong) NSString*        uuid;
@property (nonatomic, strong) NSArray*         languageCodes;
@property (nonatomic, strong) NSString*        languageCode;
@property (nonatomic, assign) NSUInteger       codeLength;
@property (nonatomic, copy)   void           (^completion)(BOOL isVerified);

@property (nonatomic, assign) BOOL             isCancelled;
@property (nonatomic, assign) BOOL             isCalling;
@property (nonatomic, assign) BOOL             canEnterCode;

@property (nonatomic, strong) UITextField*     codeTextField;
@property (nonatomic, strong) CellButton*      callButton;

@end


@implementation VerifyPhoneVoiceCallViewController

- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber
                               uuid:(NSString*)uuid
                      languageCodes:(NSArray*)languageCodes
                         codeLength:(NSUInteger)codeLength
                         completion:(void (^)(BOOL isVerified))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.phoneNumber   = phoneNumber;
        self.uuid          = uuid;
        self.languageCodes = (languageCodes.count == 0) ? @[ @"en", @"nl" ] : languageCodes;
        self.languageCode  = self.languageCodes[0];
        self.codeLength    = codeLength;
        self.completion    = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedString(@"Verify", @"");

    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = buttonItem;

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}


- (void)willMoveToParentViewController:(UIViewController*)parent
{
    // We get here when user pops this view via navigation controller.
    if (parent == nil && self.isLoading)
    {
        [self cancel];
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections |= TableSectionCall;
    self.sections |= TableSectionCode;

    //### self.callRows |= CallRowLanguage;
    self.callRows |= CallRowCallMe;

    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionCall: numberOfRows = [Common bitsSetCount:self.callRows]; break;
        case TableSectionCode: numberOfRows = 1;                                   break;
    }

    return numberOfRows;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCall: cell = [self callCellForRowAtIndexPath:indexPath]; break;
        case TableSectionCode: cell = [self codeCellForRowAtIndexPath:indexPath]; break;
    }

    return cell;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCall:
        {
            switch ([Common nthBitSet:indexPath.row inValue:self.callRows])
            {
                case CallRowLanguage:
                {
                    return 45.0;
                }
                case CallRowCallMe:
                {
                    return 84.0;
                }
            }
        }
        case TableSectionCode:
        {
            return 45.0;
        }
        default:
        {
            // Keep the compiler happy.
            return 0.0;
        }
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionCall:
        {
            title = NSLocalizedString(@"Receive call to hear %d-digit code", @"");
            title = [NSString stringWithFormat:title, self.codeLength];
            break;
        }
        case TableSectionCode:
        {
            title = NSLocalizedString(@"Enter the code you heard", @"");
            break;
        }
    }

    return title;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionCall:
        {
            switch ([Common nthBitSet:indexPath.row inValue:self.callRows])
            {
                case CallRowLanguage:
                {
                    LanguagesViewController* viewController;
                    viewController = [[LanguagesViewController alloc] initWithLanguageCodes:self.languageCodes
                                                                               languageCode:self.languageCode
                                                                                 completion:^(NSString *languageCode)
                                      {
                                          cell.detailTextLabel.text = [Common languageNameForCode:languageCode];
                                          self.languageCode = languageCode;
                                      }];

                    [self.navigationController pushViewController:viewController animated:YES];
                    break;
                }
                case CallRowCallMe:
                {
                    break;
                }
            }

            break;
        }
        case TableSectionCode:
        {
            if (self.canEnterCode == NO)
            {
                [self showCantCallAlert];
            }
            else
            {
                [self.codeTextField becomeFirstResponder];
            }

            break;
        }
    }
}


#pragma mark - Cell Methods

- (UITableViewCell*)callCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    switch ([Common nthBitSet:indexPath.row inValue:self.callRows])
    {
        case CallRowLanguage: identifier = @"LanguageCell"; break;
        case CallRowCallMe:   identifier = @"CallMeCell";   break;
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];

        switch ([Common nthBitSet:indexPath.row inValue:self.callRows])
        {
            case CallRowLanguage:
            {
                cell.textLabel.text = [Strings languageString];
                cell.detailTextLabel.text = [Common languageNameForCode:self.languageCode];
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                break;
            }
            case CallRowCallMe:
            {
                self.callButton = [CellButton buttonWithType:UIButtonTypeCustom];
                self.callButton.frame = CGRectMake(20.0, 20.0, 280.0, 44.0);
                [self.callButton setTitle:[self callMeTitle] forState:UIControlStateNormal];
                [Common styleButton:self.callButton];
                [self.callButton addTarget:self action:@selector(callMeAction) forControlEvents:UIControlEventTouchUpInside];

                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell addSubview:self.callButton];
                break;
            }
        }
    }

    return cell;
}


- (UITableViewCell*)codeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        identifier;

    identifier = @"cell";
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.textLabel.text = NSLocalizedString(@"Code", @"");
        cell.selectionStyle = UITableViewCellSelectionStyleNone;

        self.codeTextField = [Common addTextFieldToCell:cell delegate:self];
        self.codeTextField.keyboardType = UIKeyboardTypeNumberPad;
    }

    return cell;
}


#pragma mark - Textfield Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString* code = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (code.length <= self.codeLength)
    {
        textField.text = code;
    }
    else
    {
        return NO;
    }

    if (code.length == self.codeLength)
    {
        self.isLoading = YES;

        [self.callButton setTitle:[self callMeTitle] forState:UIControlStateNormal];

        [[WebClient sharedClient] checkVoiceVerificationCode:code
                                                     forUuid:self.uuid
                                                       reply:^(NSError *error, BOOL isVerified)
        {
            self.isLoading = NO;
            
            if (isVerified == YES)
            {
                NSUInteger        index               = self.navigationController.viewControllers.count - 2 - 1;
                UIViewController* phoneViewController = self.navigationController.viewControllers[index];
                [self.navigationController popToViewController:phoneViewController animated:YES];

                self.completion(isVerified);
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedString(@"Incorrect Code", @"");
                message = NSLocalizedString(@"The code you entered seems to be incorrect.\n\nPlease tap '%@' to "
                                            @"try again and hear a new code.", @"");
                message = [NSString stringWithFormat:message, [self callMeTitle]];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    self.codeTextField.text = nil;

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
                    {
                        [textField resignFirstResponder];
                    });

                    self.canEnterCode = NO;
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    }

    return NO;
}


- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    if (self.canEnterCode == NO)
    {
        [self showCantCallAlert];

        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Helpers

- (void)cancel
{
    self.isCancelled = YES;

    if (self.uuid != nil)
    {
        [[WebClient sharedClient] cancelAllRequestPhoneVerificationCallForUuid:self.uuid];
        [[WebClient sharedClient] cancelAllRetrievePhoneVerificationStatusForUuid:self.uuid];
        [[WebClient sharedClient] cancelAllCheckVoiceVerificationCodeForUuid:self.uuid];
        [[WebClient sharedClient] stopPhoneVerificationForUuid:self.uuid reply:nil];
    }
}


- (NSString*)callMeTitle
{
    return NSLocalizedString(@"Call Me", @"");
}


- (NSString*)callMeAgainTitle
{
    return NSLocalizedString(@"Hear Code Again", @"");
}


- (void)checkCallStatusWithRepeatCount:(int)count
{
    if (--count == 0)
    {
        self.isLoading = NO;

        return;
    }

    [[WebClient sharedClient] retrievePhoneVerificationStatusForUuid:self.uuid
                                                               reply:^(NSError* error, BOOL isCalling, BOOL isVerified)
    {
        if (self.isCancelled)
        {
            self.isLoading = NO;

            return;
        }

        if (error == nil)
        {
            self.canEnterCode = isCalling ? NO : self.isCalling;
            self.isCalling    = isCalling;

            if (self.canEnterCode == YES)
            {
                [self.codeTextField becomeFirstResponder];
                [self.callButton setTitle:[self callMeAgainTitle] forState:UIControlStateNormal];
            }

            if (isCalling == YES)
            {
                [Common dispatchAfterInterval:1.0 onMain:^
                {
                    [self checkCallStatusWithRepeatCount:count];
                }];
            }
            else
            {
                self.isLoading = NO;
            }
        }
        else
        {
            self.isLoading = NO;

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorTitle", nil,
                                                        [NSBundle mainBundle], @"Verification Check Failed",
                                                        @"Something went wrong.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Checking the verification status of your number failed: %@\n\n"
                                                        @"Please try again, later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self cancelAction];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)showCantCallAlert
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedString(@"Can't Enter Code Yet", @"");
    message = NSLocalizedString(@"First tap '%@' to receive an automatic phone call. During that short "
                                @"call, you will hear the %d-digit code you must enter.", @"");
    message = [NSString stringWithFormat:message, [self callMeTitle], self.codeLength];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - Actions

- (void)callMeAction
{
    self.canEnterCode = NO;
    self.isLoading    = YES;
    [[WebClient sharedClient] requestPhoneVerificationCallForUuid:self.uuid reply:^(NSError* error)
    {
        if (error == nil)
        {
            [self checkCallStatusWithRepeatCount:30];
        }
        else
        {
            self.isLoading = NO;

            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorTitle", nil,
                                                        [NSBundle mainBundle], @"Failed To Call You",
                                                        @"Something went wrong.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"VerifyPhone VerifyCheckErrorMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while trying to call you: %@\n\n"
                                                        @"Please try again, later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self cancelAction];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)cancelAction
{
    self.completion = nil;

    [self.codeTextField resignFirstResponder];

    [self cancel];

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
