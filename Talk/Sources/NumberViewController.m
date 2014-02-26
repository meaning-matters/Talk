//
//  NumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <objc/runtime.h>
#import "NumberViewController.h"
#import "BuyNumberViewController.h"
#import "ProofImageViewController.h"
#import "NumberForwardingsViewController.h"
#import "Common.h"
#import "PhoneNumber.h"
#import "CountryNames.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "NumberLabel.h"
#import "ForwardingData.h"
#import "DataManager.h"
#import "Skinning.h"


typedef enum
{
    TableSectionName            = 1UL << 0,
    TableSectionNumber          = 1UL << 1,
    TableSectionForwarding      = 1UL << 2,
    TableSectionSubscription    = 1UL << 3,
    TableSectionArea            = 1UL << 4,    // The optional state will be placed in a row here.
    TableSectionContactName     = 1UL << 5,
    TableSectionContactAddress  = 1UL << 6,
} TableSections;

typedef enum
{
    AreaRowType                 = 1UL << 0,
    AreaRowAreaCode             = 1UL << 1,
    AreaRowAreaName             = 1UL << 2,
    AreaRowStateName            = 1UL << 3,
    AreaRowCountry              = 1UL << 4,
} AreaRows;

typedef enum
{
    ContactNameRowSalutation    = 1UL << 0,
    ContactNameRowCompany       = 1UL << 1,
    ContactNameRowFirstName     = 1UL << 2,
    ContactNameRowLastName      = 1UL << 3,
} ContactNameRows;

typedef enum
{
    ContactAddressRowStreet     = 1UL << 0,
    ContactAddressRowBuilding   = 1UL << 1,
    ContactAddressRowCity       = 1UL << 2,
    ContactAddressRowZipCode    = 1UL << 3,
    ContactAddressRowStateName  = 1UL << 4,
    ContactAddressRowCountry    = 1UL << 5,
    ContactAddressRowProofImage = 1UL << 6,
} ContactAddressRows;


static const int TextFieldCellTag = 1234;


@interface NumberViewController ()
{
    NumberData*        number;
    
    TableSections      sections;
    AreaRows           areaRows;
    ContactNameRows    contactNameRows;
    ContactAddressRows contactAddressRows;

    NSIndexPath*       nameIndexPath;
    NSString*          name;            // Mirror that's only processed when user taps Done.

    // Keyboard stuff.
    BOOL               keyboardShown;
    CGFloat            keyboardOverlap;
}

@end


@implementation NumberViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        number = theNumber;
        name   = number.name;

        self.title = NSLocalizedStringWithDefaultValue(@"Number:NumberDetails ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Number",
                                                       @"Title of app screen with details of a phone number\n"
                                                       @"[1 line larger font].");

        // Mandatory sections.
        sections |= TableSectionName;
        sections |= TableSectionNumber;
        sections |= TableSectionForwarding;
        sections |= TableSectionArea;
        sections |= TableSectionSubscription;

        // Optional sections.
        sections |= (number.salutation != nil) ? TableSectionContactName    : 0;
        sections |= (number.salutation != nil) ? TableSectionContactAddress : 0;

        // Area Rows
        areaRows |= AreaRowType;
        areaRows |= AreaRowAreaCode;
        areaRows |= (number.areaName  != nil) ? AreaRowAreaName  : 0;
        areaRows |= (number.stateName != nil) ? AreaRowStateName : 0;
        areaRows |= AreaRowCountry;

        // Contact Name Rows
        contactNameRows |= [number.salutation isEqualToString:@"COMPANY"] ? 0  : ContactNameRowSalutation;
        contactNameRows |= (number.company   != nil) ? ContactNameRowCompany   : 0;
        contactNameRows |= (number.firstName != nil) ? ContactNameRowFirstName : 0;
        contactNameRows |= (number.lastName  != nil) ? ContactNameRowLastName  : 0;

        // Contact Address Rows
        contactAddressRows |= ContactAddressRowStreet;
        contactAddressRows |= ContactAddressRowBuilding;
        contactAddressRows |= ContactAddressRowCity;
        contactAddressRows |= ContactAddressRowZipCode;
        contactAddressRows |= (number.stateName != nil)  ? ContactAddressRowStateName  : 0;
        contactAddressRows |= ContactAddressRowCountry;
        contactAddressRows |= (number.proofImage != nil) ? ContactAddressRowProofImage : 0;

        nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:[Common nOfBit:TableSectionName inValue:sections]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectsChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:[DataManager sharedManager].managedObjectContext];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:[DataManager sharedManager].managedObjectContext];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsSelectionDuringEditing = YES;//### Needed?

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];

    [self addKeyboardNotifications];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (void)handleManagedObjectsChange:(NSNotification*)note
{
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath == nil)
    {
        [self.tableView reloadData];
    }
}


#pragma mark - Table View Delegates

- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionSubscription:
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Subscription",
                                                      @"....");
            break;

        case TableSectionArea:
            title = [Strings detailsString];
            break;

        case TableSectionContactName:
            title = NSLocalizedStringWithDefaultValue(@"Number:Address SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Contact Name",
                                                      @"....");
            break;

        case TableSectionContactAddress:
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Contact Address",
                                                      @"....");
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            title = NSLocalizedStringWithDefaultValue(@"Number:Name SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"Tap to edit.  A change will also be saved "
                                                      @"online.  Refresh the overview Numbers list on other "
                                                      @"devices to load changes.",
                                                      @"[* lines]");
            break;

        case TableSectionForwarding:
            title = NSLocalizedStringWithDefaultValue(@"Number:ForwardingDefault SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"With 'Default' all devices associated with this number "
                                                      @"will ring when an incoming call is received.",
                                                      @"Explanation about which phone will be called.\n"
                                                      @"[* lines]");
            break;

        case TableSectionSubscription:
            title = NSLocalizedStringWithDefaultValue(@"Number:Subscription SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"IMPORTANT: If you don't extend this subscription in time, "
                                                      @"your number can't be used anymore after it expires.  An "
                                                      @"expired number can not be reactivated.",
                                                      @"Explanation how/when the subscription, for "
                                                      @"using a phone number, will expire\n"
                                                      @"[* lines]");
            break;
    }

    return title;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            numberOfRows = 1;
            break;

        case TableSectionNumber:
            numberOfRows = 1;

        case TableSectionForwarding:
            numberOfRows = 1;
            break;

        case TableSectionSubscription:
            numberOfRows = 2;   // Second row leads to buying extention.
            break;

        case TableSectionArea:
            numberOfRows = [Common bitsSetCount:areaRows];
            break;

        case TableSectionContactName:
            numberOfRows = [Common bitsSetCount:contactNameRows];
            break;

        case TableSectionContactAddress:
            numberOfRows = (number.proofImage == nil) ? 5 : 6;
            break;
    }

    return numberOfRows;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    ProofImageViewController*        proofImageviewController;
    NumberForwardingsViewController* forwardingsViewController;

    if ([self.tableView cellForRowAtIndexPath:indexPath].selectionStyle == UITableViewCellSelectionStyleNone)
    {
        return;
    }

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            break;

        case TableSectionNumber:
            break;

        case TableSectionForwarding:
            forwardingsViewController = [[NumberForwardingsViewController alloc] initWithNumber:number];
            [self.navigationController pushViewController:forwardingsViewController animated:YES];
            break;

        case TableSectionSubscription:
            break;

        case TableSectionArea:
            break;

        case TableSectionContactName:
            break;
            
        case TableSectionContactAddress:
            if (indexPath.row == 5)
            {
                proofImageviewController = [[ProofImageViewController alloc] initWithImageData:number.proofImage];
                [self.navigationController pushViewController:proofImageviewController animated:YES];
            }
            break;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = nil;
    NSString*        identifier;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            identifier    = @"TextFieldCell";
            nameIndexPath = indexPath;
            break;

        case TableSectionNumber:
            identifier = @"NumberCell";
            break;

        case TableSectionForwarding:
            identifier = @"DisclosureCell";
            break;

        case TableSectionSubscription:
            identifier = (indexPath.row == 0) ? @"Value1Cell" : @"DisclosureCell";
            break;

        case TableSectionArea:
            if ([Common nthBitSet:indexPath.row inValue:areaRows] == AreaRowCountry)
            {
                identifier = @"CountryCell";
            }
            else
            {
                identifier = @"Value1Cell";
            }
            break;

        case TableSectionContactName:
            identifier = @"Value1Cell";
            break;

        case TableSectionContactAddress:
            identifier = (indexPath.row == 4) ? @"CountryCell"    : @"Value1Cell";
            identifier = (indexPath.row == 5) ? @"DisclosureCell" : identifier;
            break;
    }

    cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            [self updateNameCell:cell atIndexPath:indexPath];
            break;

        case TableSectionNumber:
            [self updateNumberCell:cell atIndexPath:indexPath];
            break;

        case TableSectionForwarding:
            [self updateForwardingCell:cell atIndexPath:indexPath];
            break;

        case TableSectionSubscription:
            [self updateSubscriptionCell:cell atIndexPath:indexPath];
            break;

        case TableSectionArea:
            [self updateAreaCell:cell atIndexPath:indexPath];
            break;

        case TableSectionContactName:
            [self updateContactNameCell:cell atIndexPath:indexPath];
            break;

        case TableSectionContactAddress:
            [self updateContactAddressCell:cell atIndexPath:indexPath];
            break;
    }
}


#pragma mark - Cell Methods

- (void)updateNameCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    UITextField* textField;

    textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    if (textField == nil)
    {
        textField = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
        textField.enablesReturnKeyAutomatically = YES;
    }

    textField.placeholder            = [Strings requiredString];
    textField.text                   = name;
    textField.userInteractionEnabled = YES;
    objc_setAssociatedObject(textField, @"TextFieldKey", @"name", OBJC_ASSOCIATION_RETAIN);

    cell.selectionStyle              = UITableViewCellSelectionStyleNone;
    cell.textLabel.text              = [Strings nameString];

    if (name.length == 0)
    {
        [textField becomeFirstResponder];
    }
}


- (void)updateNumberCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberLabel* numberLabel = [Common addNumberLabelToCell:cell];

    numberLabel.text         = [[PhoneNumber alloc] initWithNumber:number.e164].internationalFormat;
    [Common addCountryImageToCell:cell isoCountryCode:number.numberCountry];
    cell.selectionStyle      = UITableViewCellSelectionStyleNone;
}


- (void)updateForwardingCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number Forwarding", nil,
                                                                  [NSBundle mainBundle], @"Forwarding",
                                                                  @"....");
    cell.textLabel.textColor  = [UIColor blackColor];
    cell.detailTextLabel.text = (number.forwarding == nil) ? [Strings defaultString] : number.forwarding.name;
    cell.selectionStyle       = UITableViewCellSelectionStyleBlue;
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
}


- (void)updateSubscriptionCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NSString*        dateFormat    = [NSDateFormatter dateFormatFromTemplate:@"E MMM d yyyy"
                                                                     options:0
                                                                      locale:[NSLocale currentLocale]];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    switch (indexPath.row)
    {
        case 0:
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionPurchaseDate Label", nil,
                                                                          [NSBundle mainBundle], @"Purchased",
                                                                          @"....");
            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.purchaseDate];
            cell.selectionStyle       = UITableViewCellSelectionStyleNone;
            break;

        case 1:
            cell.textLabel.text       = NSLocalizedStringWithDefaultValue(@"Number:SubscriptionRenewalDate Label", nil,
                                                                          [NSBundle mainBundle], @"Expiry",
                                                                          @"....");
            cell.detailTextLabel.text = [dateFormatter stringFromDate:number.renewalDate];
            cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle       = UITableViewCellSelectionStyleBlue;
            break;
    }
}


- (void)updateAreaCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberTypeMask numberTypeMask;
    switch ([Common nthBitSet:indexPath.row inValue:areaRows])
    {
        case AreaRowType:
            cell.textLabel.text       = [Strings typeString];
            numberTypeMask            = [NumberType numberTypeMaskForString:number.numberType];
            cell.detailTextLabel.text = [NumberType localizedStringForNumberType:numberTypeMask];
            break;

        case AreaRowAreaCode:
            cell.textLabel.text       = [Strings areaCodeString];
            cell.detailTextLabel.text = number.areaCode;
            break;

        case AreaRowAreaName:
            cell.textLabel.text       = [Strings areaString];
            cell.detailTextLabel.text = number.areaName;
            break;

        case AreaRowStateName:
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = number.stateName;
            break;

        case AreaRowCountry:
            cell.textLabel.text       = [Strings countryString];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:number.numberCountry];
            break;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;
}


- (void)updateContactNameCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.row inValue:contactNameRows])
    {
        case ContactNameRowSalutation:
            cell.textLabel.text       = [Strings salutationString];
            cell.detailTextLabel.text = [Strings localizedSalutation:number.salutation];
            break;

        case ContactNameRowCompany:
            cell.textLabel.text       = [Strings companyString];
            cell.detailTextLabel.text = number.company;
            break;

        case ContactNameRowFirstName:
            cell.textLabel.text       = [Strings firstNameString];
            cell.detailTextLabel.text = number.firstName;
            break;

        case ContactNameRowLastName:
            cell.textLabel.text       = [Strings lastNameString];
            cell.detailTextLabel.text = number.lastName;
            break;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;
}


- (void)updateContactAddressCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.row inValue:contactAddressRows])
    {
        case ContactAddressRowStreet:
            cell.textLabel.text       = [Strings streetString];
            cell.detailTextLabel.text = number.street;
            break;

        case ContactAddressRowBuilding:
            cell.textLabel.text       = [Strings buildingString];
            cell.detailTextLabel.text = number.building;
            break;

        case ContactAddressRowCity:
            cell.textLabel.text       = [Strings cityString];
            cell.detailTextLabel.text = number.city;
            break;

        case ContactAddressRowZipCode:
            cell.textLabel.text       = [Strings zipCodeString];
            cell.detailTextLabel.text = number.zipCode;
            break;

        case ContactAddressRowStateName:
            cell.textLabel.text       = [Strings stateString];
            cell.detailTextLabel.text = number.stateName;
            break;

        case ContactAddressRowCountry:
            cell.textLabel.text = @" ";  // Without this, detailTextLabel is on the left.
            [Common addCountryImageToCell:cell isoCountryCode:number.addressCountry];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:number.addressCountry];
            break;
    }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType  = UITableViewCellAccessoryNone;
}


#pragma mark - Helpers

- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (name.length > 0)
    {
        [[self.tableView superview] endEditing:YES];

        [self save];
    }
}


- (void)save
{
    if ([name isEqualToString:number.name] == YES)
    {
        // Nothing has changed.
        return;
    }

    [[WebClient sharedClient] updateNumberE164:number.e164 withName:name reply:^(NSError* error)
    {
        if (error == nil)
        {
            number.name = name;
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"Number NameUpdateFailedTitle", nil,
                                                        [NSBundle mainBundle], @"Name Not Updated",
                                                        @"Alert title telling that a name was not saved.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Number NameUpdateFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Saving the name via the internet failed: %@\n\n"
                                                        @"Please try again later.",
                                                        @"Alert message telling that a name must be supplied\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 name = number.name;
                 [self updateNameCell:[self.tableView cellForRowAtIndexPath:nameIndexPath] atIndexPath:nameIndexPath];
             }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    textField.returnKeyType = UIReturnKeyDone;
#warning The method reloadInputViews messes up two-byte keyboards (e.g. Kanji).
    [textField reloadInputViews];

    return YES;
}


- (NSIndexPath*)findCellIndexPathForSubview:(UIView*)subview
{
    UIView* superview = subview.superview;
    while ([superview class] != [UITableViewCell class])
    {
        superview = superview.superview;
    }

    return [self.tableView indexPathForCell:(UITableViewCell*)superview];
}


- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    name = @"";

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [self save];

    [textField resignFirstResponder];

    // we can always return YES, because the Done button will be disabled when there's no text.
    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self.tableView scrollToRowAtIndexPath:nameIndexPath
                          atScrollPosition:UITableViewScrollPositionNone
                                  animated:YES];

    return YES;
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] || [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - Keyboard Handling
// http://stackoverflow.com/questions/13845426/generic-uitableview-keyboard-resizing-algorithm

- (void)addKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}


- (void)keyboardWillShow:(NSNotification*)notification
{
    if (keyboardShown == YES)
    {
        return;
    }
    else
    {
        keyboardShown = YES;
    }

    // Get keyboard size.
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    // Get the keyboard's animation details.
    NSTimeInterval  animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    // Determine how much overlap exists between tableView and the keyboard
    CGRect tableFrame = self.tableView.frame;
    CGFloat tableLowerYCoord = tableFrame.origin.y + tableFrame.size.height;
    keyboardOverlap = tableLowerYCoord - keyboardRect.origin.y;
    if (self.inputAccessoryView && keyboardOverlap > 0)
    {
        CGFloat accessoryHeight = self.inputAccessoryView.frame.size.height;
        keyboardOverlap -= accessoryHeight;

        self.tableView.contentInset          = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
        self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, accessoryHeight, 0);
    }

    if (keyboardOverlap < 0)
    {
        keyboardOverlap = 0;
    }

    if (keyboardOverlap != 0)
    {
        tableFrame.size.height -= keyboardOverlap;

        NSTimeInterval delay = 0;
        if (keyboardRect.size.height)
        {
            delay = (1 - keyboardOverlap / keyboardRect.size.height) * animationDuration;
            animationDuration = animationDuration * keyboardOverlap / keyboardRect.size.height;
        }

        [UIView animateWithDuration:animationDuration delay:delay
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^
         {
             self.tableView.frame = tableFrame;
         }
                         completion:^(BOOL finished)
         {
             [self tableAnimationEnded:nil finished:nil contextInfo:nil];
         }];
    }
}


- (void)keyboardWillHide:(NSNotification*)notification
{
    if (keyboardShown == NO)
    {
        return;
    }
    else
    {
        keyboardShown = NO;
    }

    if (keyboardOverlap == 0)
    {
        return;
    }

    // Get the size & animation details of the keyboard
    NSDictionary*   userInfo = [notification userInfo];
    NSValue*        value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect          keyboardRect = [self.tableView.superview convertRect:[value CGRectValue] fromView:nil];

    NSTimeInterval animationDuration;
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    UIViewAnimationCurve animationCurve;
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];

    CGRect tableFrame = self.tableView.frame;
    tableFrame.size.height += keyboardOverlap;

    if(keyboardRect.size.height)
    {
        animationDuration = animationDuration * keyboardOverlap/keyboardRect.size.height;
    }

    [UIView animateWithDuration:animationDuration delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState
                     animations:^
     {
         self.tableView.frame = tableFrame;
     }
                     completion:nil];
}


- (void)tableAnimationEnded:(NSString*)animationID finished:(NSNumber*)finished contextInfo:(void*)context
{
    // Scroll to the Name cell
    dispatch_time_t when = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC));
    dispatch_after(when, dispatch_get_main_queue(), ^
    {
        [self.tableView scrollToRowAtIndexPath:nameIndexPath
                              atScrollPosition:UITableViewScrollPositionNone
                                      animated:YES];
    });
}

@end
