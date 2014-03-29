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


@interface PhoneViewController ()
{
    TableSections sections;
    BOOL          isNew;

    PhoneNumber*  phoneNumber;

    NSArray*      numbersArray;
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

        self.name                 = phone.name;
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

    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(saveAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    else
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }

    [self updateSaveButtonItem];
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
    self.phone.name = self.name;
    self.phone.e164 = [phoneNumber e164Format];

    [[WebClient sharedClient] updateVerifiedE164:self.phone.e164
                                        withName:self.phone.name
                                           reply:^(NSError *error)
    {
        if (error == nil)
        {
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            if (isNew)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        else
        {
            [self.managedObjectContext rollback];
            self.name = self.phone.name;
            [self showSaveError:error];
        }
    }];
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
                                                @"Failed to save this Phone: %@",
                                                @"...\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, [error localizedDescription]]
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self.tableView reloadData];
    }
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


- (UITableViewCell*)numberCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"NumberCell"];
    }

    cell.textLabel.text  = [Strings numberString];
    cell.imageView.image = nil;
    if (isNew)
    {
        cell.detailTextLabel.text      = [Strings requiredString];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
        cell.selectionStyle            = UITableViewCellSelectionStyleDefault;
        cell.accessoryType             = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        NumberLabel* numberLabel = [Common addNumberLabelToCell:cell];
        numberLabel.text         = [phoneNumber internationalFormat];
        cell.selectionStyle      = UITableViewCellSelectionStyleNone;
        cell.accessoryType       = UITableViewCellAccessoryNone;
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
                        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.75f alpha:1.0f];
                    }

                    [self updateSaveButtonItem];
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


#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    BOOL shouldChange = [super textField:textField shouldChangeCharactersInRange:range replacementString:string];

    [self updateSaveButtonItem];

    return shouldChange;
}


#pragma mark - Helper Methods

- (void)updateSaveButtonItem
{
    self.navigationItem.rightBarButtonItem.enabled = (self.name.length > 0) && (phoneNumber != nil);
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Baseclass Override

- (void)save
{
    if (isNew == NO)
    {
        [self saveAction];
    }
}

@end
