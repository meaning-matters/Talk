//
//  ForwardingViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingViewController.h"
#import "Common.h"
#import "CommonStrings.h"
#import "NumberData.h"
#import "RecordingData.h"
#import "PhoneNumber.h"
#import "Settings.h"


typedef enum
{
    TableSectionName       = 1UL << 0,  // User-given name.
    TableSectionNumber     = 1UL << 1,  //### Temporary
    TableSectionStatements = 1UL << 2,
    TableSectionNumbers    = 1UL << 3,
    TableSectionRecordings = 1UL << 4,
} TableSections;


static const int    TextFieldCellTag = 1111;


@interface ForwardingViewController ()
{
    TableSections               sections;
    BOOL                        isNew;

    NSString*                   name;
    PhoneNumber*                phoneNumber;
    NSMutableArray*             statementsArray;

    NSFetchedResultsController* fetchedResultsController;
    NSManagedObjectContext*     managedObjectContext;

    UITextField*                nameTextField;
    UITextField*                numberTextField;
}

@end


@implementation ForwardingViewController

- (id)initWithFetchedResultsController:(NSFetchedResultsController*)resultsController
                            forwarding:(ForwardingData*)forwarding
{
    fetchedResultsController = resultsController;
    self.forwarding          = forwarding;
    isNew                    = (forwarding == nil);

    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"ForwardingView ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Forwarding",
                                                       @"Title of app screen with details of a call forwarding\n"
                                                       @"[1 line larger font].");

        sections |= TableSectionName;
        sections |= TableSectionNumber;
#if FULL_FORWARDINGS
        sections |= TableSectionStatements;
#endif
        sections |= (self.forwarding.numbers.count > 0)    ? TableSectionNumbers    : 0;
        sections |= (self.forwarding.recordings.count > 0) ? TableSectionRecordings : 0;

        name = forwarding.name;
        phoneNumber = [[PhoneNumber alloc] init];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (isNew)
    {
        // Create a new managed object context for the new recording; set its parent to the fetched results controller's context.
        managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext setParentContext:[fetchedResultsController managedObjectContext]];
        self.forwarding = (ForwardingData*)[NSEntityDescription insertNewObjectForEntityForName:@"Forwarding"
                                                                         inManagedObjectContext:managedObjectContext];

        // Default is call all user's devices without timeout.
        self.forwarding.statements = [Common jsonDataWithObject: @[ @{ @"call" : @{ @"e164" : @[ @"" ] } } ] ];
    }

    statementsArray = [Common mutableObjectWithJsonData:self.forwarding.statements];
    phoneNumber.number = statementsArray[0][@"call"][@"e164"][0];

    UIBarButtonItem*    buttonItem;

    if (isNew)
    {
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(saveAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;
        [self enableSaveButton];

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}


#pragma mark - Actions

- (void)saveAction
{
    NSError*    error;

    self.forwarding.name = name;
    statementsArray[0][@"call"][@"e164"][0] = phoneNumber.number;
    self.forwarding.statements = [Common jsonDataWithObject:statementsArray];

    if (managedObjectContext != nil)
    {
        if ([managedObjectContext save:&error] == NO ||
            [[fetchedResultsController managedObjectContext] save:&error] == NO)
        {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }

    if ([[fetchedResultsController managedObjectContext] save:&error] == NO)
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    if (isNew)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
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

        case TableSectionStatements:
            numberOfRows = 1;
            break;

        case TableSectionNumbers:
            numberOfRows = self.forwarding.numbers.count;
            break;

        case TableSectionRecordings:
            numberOfRows = self.forwarding.recordings.count;
            break;
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            if (isNew)
            {
                title = [CommonStrings nameFooterString];
            }
            break;

        case TableSectionStatements:
            break;

        case TableSectionNumbers:
            break;

        case TableSectionRecordings:
            break;
    }

    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            cell = [self nameCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNumber:
            cell = [self numberCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionStatements:
            cell = [self statementsCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionNumbers:
            cell = [self numbersCellForRowAtIndexPath:indexPath];
            break;

        case TableSectionRecordings:
            cell = [self recordingsCellForRowAtIndexPath:indexPath];
            break;
    }

    return cell;
}


- (UITableViewCell*)nameCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NameCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NameCell"];
        nameTextField = [self addTextFieldToCell:cell];
        nameTextField.tag = TextFieldCellTag;
    }
    else
    {
        nameTextField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    nameTextField.placeholder = [CommonStrings requiredString];
    nameTextField.text        = name;

    cell.textLabel.text  = [CommonStrings nameString];
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)numberCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NumberCell"];
        numberTextField = [self addTextFieldToCell:cell];
        numberTextField.tag = TextFieldCellTag;
    }
    else
    {
        numberTextField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    numberTextField.placeholder  = [CommonStrings requiredString];
    numberTextField.text         = phoneNumber.asYouTypeFormat;
    numberTextField.keyboardType = UIKeyboardTypePhonePad;
    [numberTextField addTarget:self
                        action:@selector(textFieldDidChange:)
              forControlEvents:UIControlEventEditingChanged];

    cell.textLabel.text  = [CommonStrings numberString];
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)statementsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"StatementsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StatementsCell"];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"ForwardingView RulesTitle", nil,
                                                            [NSBundle mainBundle], @"Rules",
                                                            @"Title of an table row\n"
                                                            @"[1/3 line small font].");
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;

    return cell;
}


- (UITableViewCell*)numbersCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSSortDescriptor*   sortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*            sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray*            numbersArray    = [self.forwarding.numbers sortedArrayUsingDescriptors:sortDescriptors];
    NumberData*         number          = numbersArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumbersCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NumbersCell"];
    }

    cell.textLabel.text  = number.name;
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;

    return cell;
}


- (UITableViewCell*)recordingsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSSortDescriptor*   sortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*            sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray*            recordingsArray = [self.forwarding.recordings sortedArrayUsingDescriptors:sortDescriptors];
    RecordingData*      recording       = recordingsArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"RecordingsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RecordingsCell"];
    }

    cell.textLabel.text  = recording.name;
    cell.imageView.image = nil;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            break;

        case TableSectionStatements:
            break;

        case TableSectionNumbers:
            break;

        case TableSectionRecordings:
            break;
    }
}


#pragma mark - Gesture Recognizer Delegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer*)gestureRecognizer shouldReceiveTouch:(UITouch*)touch
{
    if ([touch.view isKindOfClass:[UITextField class]] ||
        [touch.view isKindOfClass:[UIButton class]])
    {
        return NO;
    }
    else
    {
        return YES;
    }
}


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldBeginEditing:(UITextField*)textField
{
    if (textField == numberTextField)
    {
        return [Common checkCountryOfPhoneNumber:phoneNumber];
    }
    else
    {
        return YES;
    }
}


- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    if (textField == nameTextField)
    {
        name = @"";
    }
    else
    {
        phoneNumber.number = @"";
    }

    [self enableSaveButton];

    return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    NSString*   text  = [textField.text stringByReplacingCharactersInRange:range withString:string];

    if (textField == nameTextField)
    {
        name = text;
    }
    else
    {
        phoneNumber.number = text;
    }

    [self enableSaveButton];

    return YES;
}


// Called only for NumberTextField; not a delegate method.
- (void)textFieldDidChange:(UITextField*)textField
{
    textField.text = phoneNumber.asYouTypeFormat;
}


#pragma mark - Helper Methods

- (void)enableSaveButton
{
    self.navigationItem.leftBarButtonItem.enabled = (name.length > 0) && phoneNumber.isValid;
}


- (UITextField*)addTextFieldToCell:(UITableViewCell*)cell
{
    UITextField*    textField;
    CGRect          frame = CGRectMake(83, 6, 198, 30);

    textField = [[UITextField alloc] initWithFrame:frame];
    [textField setFont:[UIFont boldSystemFontOfSize:15]];

    textField.adjustsFontSizeToFitWidth = NO;
    textField.autocapitalizationType    = UITextAutocapitalizationTypeWords;
    textField.clearButtonMode           = UITextFieldViewModeWhileEditing;
    textField.contentVerticalAlignment  = UIControlContentVerticalAlignmentCenter;
    textField.returnKeyType             = UIReturnKeyDone;

    textField.delegate                  = self;

    [cell.contentView addSubview:textField];

    return textField;
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
