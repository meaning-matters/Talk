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


typedef enum
{
    TableSectionName       = 1UL << 0, // User-given name.
    TableSectionRules      = 1UL << 1,
    TableSectionNumbers    = 1UL << 2,
    TableSectionRecordings = 1UL << 3,
} TableSections;


static const int    TextFieldCellTag = 1111;


@interface ForwardingViewController ()
{
    TableSections               sections;
    BOOL                        isNew;

    NSString*                   name;

    NSFetchedResultsController* fetchedResultsController;
    NSManagedObjectContext*     managedObjectContext;
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
        sections |= TableSectionRules;
        sections |= (self.forwarding.numbers.count > 0)    ? TableSectionNumbers    : 0;
        sections |= (self.forwarding.recordings.count > 0) ? TableSectionRecordings : 0;
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
    }
    else
    {
    }
    
    self.navigationItem.rightBarButtonItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                                            target:self
                                                                                            action:@selector(saveAction)];
    [self enableSaveButton];

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

    if (managedObjectContext != nil)
    {
        if ([managedObjectContext save:&error] == NO || [[fetchedResultsController managedObjectContext] save:&error] == NO)
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

    [self.navigationController popViewControllerAnimated:YES];
}


#pragma mark TableView Delegates

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

        case TableSectionRules:
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

        case TableSectionRules:
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

        case TableSectionRules:
            cell = [self rulesCellForRowAtIndexPath:indexPath];
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
    UITextField*        textField;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NameCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"NameCell"];
        textField = [self addTextFieldToCell:cell];
        textField.tag = TextFieldCellTag;
    }
    else
    {
        textField = (UITextField*)[cell viewWithTag:TextFieldCellTag];
    }

    textField.placeholder = [CommonStrings requiredString];
    textField.text = self.forwarding.name;

    cell.textLabel.text   = [CommonStrings nameString];
    cell.imageView.image  = nil;
    cell.accessoryType    = UITableViewCellAccessoryNone;
    cell.selectionStyle   = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)rulesCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"RulesCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"RulesCell"];
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

        case TableSectionRules:
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

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];

    return YES;
}


- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    name = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self enableSaveButton];

    return YES;
}


#pragma mark - Helper Methods

- (void)enableSaveButton
{
    self.navigationItem.rightBarButtonItem.enabled = (name.length > 0);
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


@end
