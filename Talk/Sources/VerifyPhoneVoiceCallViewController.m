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

@property (nonatomic, strong) UITableViewCell* codeCell;

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

      //  self.completion(NO);
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections |= TableSectionCall;
    self.sections |= TableSectionCode;

    self.callRows |= CallRowLanguage;
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
                    return 44.0;
                }
                case CallRowCallMe:
                {
                    return 84.0;
                }
            }
        }
        case TableSectionCode:
        {
            return 44.0;
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
                UITextField* textField = [cell viewWithTag:CommonTextFieldCellTag];
                [textField becomeFirstResponder];
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
                CellButton* button = [CellButton buttonWithType:UIButtonTypeCustom];
                button.frame = CGRectMake(20.0, 20.0, 280.0, 44.0);
                [button setTitle:NSLocalizedString(@"Call Me", @"") forState:UIControlStateNormal];
                [Common styleButton:button];
                [button addTarget:self action:@selector(callMeAction) forControlEvents:UIControlEventTouchUpInside];

                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                [cell addSubview:button];
                break;
            }
        }
    }

    return cell;
}


- (UITableViewCell*)codeCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString* identifier;

    identifier = @"CodeCell";
    self.codeCell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (self.codeCell == nil)
    {
        self.codeCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        self.codeCell.textLabel.text = NSLocalizedString(@"Code", @"");
        self.codeCell.selectionStyle = UITableViewCellSelectionStyleNone;

        UITextField* textField = [Common addTextFieldToCell:self.codeCell delegate:self];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.tag          = CommonTextFieldCellTag;
        textField.placeholder  = [NSString stringWithFormat:NSLocalizedString(@"%d Digits", @""), self.codeLength];
    }

    return self.codeCell;
}


#pragma mark - Textfield Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString* code = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (code.length == self.codeLength)
    {
        self.isLoading = YES;

        [[WebClient sharedClient] checkVoiceVerificationCode:code
                                                     forUuid:self.uuid
                                                       reply:^(NSError *error, BOOL isVerified)
        {
            self.isLoading = NO;
            
            if (isVerified == YES)
            {
                [self.navigationController popViewControllerAnimated:YES];

                self.completion(isVerified);
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedString(@"Incorrect Code", @"");
                message = NSLocalizedString(@"The code you entered seems to be incorrect.\n\nPlease tap 'Call Me' to "
                                            @"hear the code again.", @"");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    UITextField* textField = [self.codeCell viewWithTag:CommonTextFieldCellTag];
                    textField.text = nil;
                    [textField resignFirstResponder];

                    self.canEnterCode = NO;
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    }

    return code.length <= self.codeLength;
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
                                                        @"Failed to check if verification is ready.\n\n"
                                                        @"Please try again, later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)showCantCallAlert
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedString(@"Can't Enter Code", @"");
    message = NSLocalizedString(@"You must first tap 'Call Me' and receive an automatic phone call. During that short "
                                @"call, you will hear a %d-digit code.\n\nAfter the call has ended, you must enter the "
                                @"code you heard.", @"");
    message = [NSString stringWithFormat:message, self.codeLength];
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
            [self checkCallStatusWithRepeatCount:20];
        }
        else
        {
            //#### Show error.
        }
    }];
}


- (void)cancelAction
{
    self.isCancelled = YES;
    self.completion  = nil;

    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

@end
