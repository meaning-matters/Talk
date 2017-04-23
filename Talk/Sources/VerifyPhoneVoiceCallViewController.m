//
//  VerifyPhoneVoiceCallViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "VerifyPhoneVoiceCallViewController.h"
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

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) CallRows      callRows;
@property (nonatomic, strong) PhoneNumber*  phoneNumber;
@property (nonatomic, strong) NSString*     uuid;
@property (nonatomic, strong) NSArray*      languages;
@property (nonatomic, assign) NSUInteger    codeLength;
@property (nonatomic, copy)   void        (^completion)(BOOL isVerified);

@property (nonatomic, assign) BOOL         isCancelled;

@end


@implementation VerifyPhoneVoiceCallViewController

- (instancetype)initWithPhoneNumber:(PhoneNumber*)phoneNumber
                               uuid:(NSString*)uuid
                          languages:(NSArray*)languages
                         codeLength:(NSUInteger)codeLength
                         completion:(void (^)(BOOL isVerified))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.phoneNumber = phoneNumber;
        self.uuid        = uuid;
        self.languages   = (languages.count == 0) ? @[ @"en" ] : languages;
        self.codeLength  = codeLength;
        self.completion  = completion;
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
            title = NSLocalizedString(@"Call to hear %d-digit code", @"");
            title = [NSString stringWithFormat:title, self.codeLength];
            break;
        }
        case TableSectionCode:
        {
            title = NSLocalizedString(@"Enter code you heard", @"");
            break;
        }
    }

    return title;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if ([Common nthBitSet:indexPath.section inValue:self.sections] == TableSectionCall)
    {
        switch ([Common nthBitSet:indexPath.row inValue:self.callRows])
        {
            case CallRowLanguage:
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                break;
            }
            case CallRowCallMe:
            {
                break;
            }
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
                cell.textLabel.text = NSLocalizedString(@"Language", @"");
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
    UITableViewCell* cell;
    NSString*        identifier;

    identifier = @"CodeCell";
    cell       = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
        cell.textLabel.text = NSLocalizedString(@"Code", @"");

        UITextField* textField = [Common addTextFieldToCell:cell delegate:self];
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.tag          = CommonTextFieldCellTag;
    }

    return cell;
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
            [self.navigationController popViewControllerAnimated:YES];

            self.completion(isVerified);
        }];
    }

    return code.length <= self.codeLength;
}


#pragma mark - Helpers

- (void)checkCallStatusWithRepeatCount:(int)count
{
    if (--count == 0)
    {
        self.isLoading = NO;

        return;
    }
    else
    {
        self.isLoading = YES;
    }

    [[WebClient sharedClient] retrievePhoneVerificationStatusForUuid:self.uuid
                                                               reply:^(NSError* error, BOOL calling, BOOL verified)
    {
        if (self.isCancelled)
        {
            self.isLoading = NO;

            return;
        }

        if (error == nil)
        {
            if (calling == YES)
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
       //  [self setStep:3];
     }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - Actions

- (void)callMeAction
{
    [[WebClient sharedClient] requestPhoneVerificationCallForUuid:self.uuid reply:^(NSError* error)
    {
        if (error == nil)
        {
            [self checkCallStatusWithRepeatCount:20];
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
