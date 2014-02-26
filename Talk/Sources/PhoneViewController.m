//
//  PhoneViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "PhoneViewController.h"
#import "Common.h"
#import "Strings.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockActionSheet.h"
#import "BlockAlertView.h"
#import "ForwardingData.h"
#import "NumberData.h"
#import "DataManager.h"
#import "VerifyPhoneViewController.h"


typedef enum
{
    TableSectionName        = 1UL << 0,
    TableSectionNumber      = 1UL << 1,
    TableSectionForwardings = 1UL << 2,
    TableSectionNumbers     = 1UL << 3,
} TableSections;


static const int TextFieldCellTag = 1111;


@interface PhoneViewController ()
{
    TableSections    sections;
    BOOL             isNew;

    NSString*        name;
    PhoneNumber*     phoneNumber;

    NSArray*         numbersArray;

    UIBarButtonItem* saveButtonItem;
    UIBarButtonItem* deleteButtonItem;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@end


@implementation PhoneViewController

- (instancetype)initWithPhone:(PhoneData*)phone
         managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title                = [Strings phoneString];

        self.phone                = phone;
        isNew                     = (phone == nil);
        self.managedObjectContext = managedObjectContext;

        name                      = phone.name;
        phoneNumber               = [[PhoneNumber alloc] initWithNumber:self.phone.e164];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:self.managedObjectContext];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    if (isNew)
    {
        // Create a new managed object context; set its parent to the fetched results controller's context.
        NSManagedObjectContext* managedObjectContext;
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setParentContext:self.managedObjectContext];
        self.managedObjectContext = managedObjectContext;

        self.phone = (PhoneData*)[NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                               inManagedObjectContext:self.managedObjectContext];
    }

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleManagedObjectsChange:)
                                                 name:NSManagedObjectContextObjectsDidChangeNotification
                                               object:self.managedObjectContext];

    [self updateRightBarButtonItem];
    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = buttonItem;
    }

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate             = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}


- (void)handleManagedObjectsChange:(NSNotification*)note
{
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath == nil)
    {
        [self.tableView reloadData];
    }
}


#pragma mark - Actions

- (void)deleteAction
{
    NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"PhoneView DeleteTitle", nil,
                                                              [NSBundle mainBundle], @"Delete Phone",
                                                              @"...\n"
                                                              @"[1/3 line small font].");

    [BlockActionSheet showActionSheetWithTitle:nil
                                    completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
    {
        if (destruct == YES)
        {
            [self.phone deleteFromManagedObjectContext:self.managedObjectContext
                                            completion:^(BOOL succeeded)
            {
                if (succeeded)
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }];
        }
    }
                             cancelButtonTitle:[Strings cancelString]
                        destructiveButtonTitle:buttonTitle
                             otherButtonTitles:nil];
}


- (void)saveAction
{
    self.phone.name = name;
    self.phone.e164 = [phoneNumber e164Format];

    [[WebClient sharedClient] updateVerifiedE164:self.phone.e164
                                        withName:self.phone.name
                                           reply:^(NSError *error)
    {
        if (error == nil)
        {
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            [self.managedObjectContext rollback];
            [self showSaveError:error];
        }
    }];

    [self dismissViewControllerAnimated:YES completion:nil];
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)showSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Phone SaveErrorTitle", nil, [NSBundle mainBundle],
                                                @"Failed To Save",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Phone SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Failed to save this Phone: %@.",
                                                @"...\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, [error localizedDescription]]
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"ANY forwarding.phones == %@", self.phone];
    numbersArray = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                             sortKeys:@[@"name"]
                                                            predicate:predicate
                                                 managedObjectContext:nil];
    
    sections  = 0;
    sections |= TableSectionName;
    sections |= TableSectionNumber;
    sections |= (self.phone.forwardings.count > 0) ? TableSectionForwardings : 0;
    sections |= (numbersArray.count > 0) ?           TableSectionNumbers     : 0;

    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger   numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            numberOfRows = 1;
            break;

        case TableSectionNumber:
            numberOfRows = 1;
            break;

        case TableSectionForwardings:
            numberOfRows = self.phone.forwardings.count;
            break;

        case TableSectionNumbers:
            numberOfRows = numbersArray.count;
            break;
    }

    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionForwardings:
            title = NSLocalizedStringWithDefaultValue(@"PhoneView ForwardingsHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used By Forwardings",
                                                      @"Table header above phone numbers\n"
                                                      @"[1 line larger font].");
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"PhoneView NumbersHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used By Numbers",
                                                      @"Table header above phone numbers\n"
                                                      @"[1 line larger font].");
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
            if (isNew)
            {
                title = [Strings nameFooterString];
            }
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"This Phone can't be deleted because it's in use.",
                                                      @"Table footer that app can't be deleted\n"
                                                      @"[1 line larger font].");
            break;
    }

    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNumber:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionForwardings:
            cell = [self forwardingsCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNumbers:
            cell = [self numbersCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UITextField*     textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NameCell"];
    if (cell == nil)
    {
        cell          = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NameCell"];
        textField     = [Common addTextFieldToCell:cell delegate:self];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    textField.placeholder = [Strings requiredString];
    textField.text        = name;

    cell.textLabel.text   = [Strings nameString];
    cell.imageView.image  = nil;
    cell.accessoryType    = UITableViewCellAccessoryNone;
    cell.selectionStyle   = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)numberCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NumberCell"];
    }

    cell.textLabel.text  = [Strings numberString];
    cell.imageView.image = nil;
    if (isNew)
    {
        cell.detailTextLabel.text      = [Strings requiredString];
        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        cell.accessoryType             = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle            = UITableViewCellSelectionStyleBlue;
    }
    else
    {
        cell.detailTextLabel.text      = [phoneNumber internationalFormat];
        cell.detailTextLabel.textColor = [UIColor blackColor];
        cell.accessoryType             = UITableViewCellAccessoryNone;
        cell.selectionStyle            = UITableViewCellSelectionStyleNone;
    }

    return cell;
}


- (UITableViewCell*)forwardingsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*  cell;
    NSSortDescriptor* sortDescriptor   = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*          sortDescriptors  = [NSArray arrayWithObject:sortDescriptor];
    NSArray*          forwardingsArray = [self.phone.forwardings sortedArrayUsingDescriptors:sortDescriptors];
    ForwardingData*   forwarding       = forwardingsArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"ForwardingsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NumbersCell"];
    }

    cell.detailTextLabel.text = forwarding.name;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)numbersCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NumberData*      number = numbersArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumbersCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NumbersCell"];
    }

    [Common addCountryImageToCell:cell isoCountryCode:number.numberCountry];

    cell.detailTextLabel.text = number.name;
    cell.accessoryType        = UITableViewCellAccessoryNone;
    cell.selectionStyle       = UITableViewCellSelectionStyleNone;

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            break;

        case TableSectionNumber:
        {
            if (isNew)
            {
                VerifyPhoneViewController* viewController;
                viewController = [[VerifyPhoneViewController alloc] initWithCompletion:^(PhoneNumber* verifiedPhoneNumber)
                {
                    phoneNumber           = verifiedPhoneNumber;
                    UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];

                    if (verifiedPhoneNumber != nil)
                    {
                        cell.detailTextLabel.text      = [phoneNumber internationalFormat];
                        cell.detailTextLabel.textColor = [UIColor blackColor];
                    }
                    else
                    {
                        cell.detailTextLabel.text      = [Strings requiredString];
                        cell.detailTextLabel.textColor = [UIColor lightGrayColor];
                    }

                    [self updateRightBarButtonItem];
                }];

                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case TableSectionForwardings:
            break;

        case TableSectionNumbers:
            break;
    }
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] ||
        [touch.view isKindOfClass:[UIButton    class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    name = @"";

    [self updateRightBarButtonItem];

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString* text  = [textField.text stringByReplacingCharactersInRange:range withString:string];

    name = text;

    [self updateRightBarButtonItem];

    return YES;
}


// Called only for NumberTextField; not a delegate method.
- (void)textFieldDidChange:(UITextField*)textField
{
    [self updateRightBarButtonItem];
}


#pragma mark - Helper Methods

- (void)updateRightBarButtonItem
{
    UIBarButtonItem* buttonItem;
    BOOL             changed;
    BOOL             valid;

    changed = [name isEqualToString:self.phone.name] == NO;
    valid   = [name stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0 &&
              ((phoneNumber.isValid && [Settings sharedSettings].homeCountry.length > 0) || phoneNumber.isInternational);

    if (saveButtonItem == nil)
    {
        saveButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                       target:self
                                                                       action:@selector(saveAction)];
    }

    if (deleteButtonItem == nil)
    {
        deleteButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                         target:self
                                                                         action:@selector(deleteAction)];
    }

    if (isNew)
    {
        buttonItem = saveButtonItem;
        buttonItem.enabled = valid;
    }
    else
    {
        if (self.phone.forwardings.count == 0 && changed == NO)
        {
            buttonItem = deleteButtonItem;
        }
        else
        {
            buttonItem = saveButtonItem;
            buttonItem.enabled = (valid && changed);
        }
    }

    [self.navigationItem setRightBarButtonItem:buttonItem animated:YES];
}


- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    [[self.tableView superview] endEditing:YES];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
