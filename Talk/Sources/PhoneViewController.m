//
//  PhoneViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/01/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "PhoneViewController.h"
#import "Common.h"
#import "Strings.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockActionSheet.h"
#import "BlockAlertView.h"
#import "DestinationData.h"
#import "NumberData.h"
#import "CallerIdData.h"
#import "DataManager.h"
#import "VerifyPhoneViewController.h"

typedef enum
{
    TableSectionName         = 1UL << 0,
    TableSectionE164         = 1UL << 1,
    TableSectionUsage        = 1UL << 2,
    TableSectionDestinations = 1UL << 3,
    TableSectionNumbers      = 1UL << 4,
    TableSectionCallerIds    = 1UL << 5,
} TableSections;


@interface PhoneViewController () <UITextFieldDelegate>
{
    TableSections sections;
    BOOL          isNew;
    BOOL          isDeleting;

    PhoneNumber*  phoneNumber;

    NSArray*      numbersArray;
    NSArray*      namesArray;
}

@end


@implementation PhoneViewController

- (instancetype)initWithPhone:(PhoneData*)phone
         managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        isNew                     = (phone == nil);
        self.phone                = phone;
        self.managedObjectContext = managedObjectContext;
        self.title                = isNew ? [Strings newPhoneString] : [Strings phoneString];
        
        self.name                 = phone.name;
        phoneNumber               = [[PhoneNumber alloc] initWithNumber:self.phone.e164];

        namesArray                = [NSMutableArray array];
    }

    return self;
}


- (void)dealloc
{
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
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

        self.phone = [NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                   inManagedObjectContext:self.managedObjectContext];
    }

    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
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

    if (isNew)
    {
        [self updateSaveButtonItem];
    }
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [self.tableView reloadData];
}


#pragma mark - Actions

- (void)deleteAction
{
    NSString* cantDeleteMessage = [self.phone cantDeleteMessage];

    if (cantDeleteMessage == nil)
    {
        NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"PhoneView DeleteTitle", nil, [NSBundle mainBundle],
                                                                  @"Delete Phone",
                                                                  @"...\n"
                                                                  @"[1/3 line small font].");
        
        [BlockActionSheet showActionSheetWithTitle:nil
                                        completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
        {
            if (destruct == YES)
            {
                isDeleting = YES;
                
                [self.phone deleteFromManagedObjectContext:self.managedObjectContext
                                                completion:^(BOOL succeeded)
                {
                    if (succeeded)
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        isDeleting = NO;
                    }
                }];
            }
        }
                                 cancelButtonTitle:[Strings cancelString]
                            destructiveButtonTitle:buttonTitle
                                 otherButtonTitles:nil];
    }
    else
    {
        NSString* title;
        
        title   = NSLocalizedStringWithDefaultValue(@"PhoneView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                    @"Can't Delete Phone",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        
        [BlockAlertView showAlertViewWithTitle:title
                                       message:cantDeleteMessage
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)saveAction
{
    if (isNew == NO && [self.phone.name isEqualToString:self.name] == YES)
    {
        return;
    }

    if (isNew == YES)
    {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    }

    [[WebClient sharedClient] updateVerifiedE164:[phoneNumber e164Format] withName:self.name reply:^(NSError *error)
    {
        if (error == nil)
        {
            self.phone.name = self.name;
            self.phone.e164 = [phoneNumber e164Format];
            
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            [self.view endEditing:YES];
            if (isNew == YES)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
        }
        else
        {
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
        [self.view endEditing:YES];
        
        if (isNew)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [self.tableView reloadRowsAtIndexPaths:@[self.nameIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
                         cancelButtonTitle:[Strings cancelString]
                         otherButtonTitles:nil];
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"ANY destination.phones == %@", self.phone];
    numbersArray = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                             sortKeys:[Common sortKeys]
                                                            predicate:predicate
                                                 managedObjectContext:nil];
    
    NSMutableArray* array = [NSMutableArray array];
    CallableData* callable = self.phone;
    for (CallerIdData* callerId in [callable.callerIds allObjects])
    {
        NSString* name = [[AppDelegate appDelegate] contactNameForId:callerId.contactId];
        [array addObject:name];
    }

    namesArray = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    sections  = 0;
    sections |= TableSectionName;
    sections |= TableSectionE164;
    sections |= (isNew == NO)                       ? TableSectionUsage        : 0;
    sections |= (self.phone.destinations.count > 0) ? TableSectionDestinations : 0;
    sections |= (numbersArray.count > 0) ?            TableSectionNumbers      : 0;
    sections |= (namesArray.count > 0) ?              TableSectionCallerIds    : 0;

    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:         numberOfRows = 1;                             break;
        case TableSectionE164:         numberOfRows = 1;                             break;
        case TableSectionUsage:        numberOfRows = 2;                             break;
        case TableSectionDestinations: numberOfRows = self.phone.destinations.count; break;
        case TableSectionNumbers:      numberOfRows = numbersArray.count;            break;
        case TableSectionCallerIds:    numberOfRows = namesArray.count;              break;
    }

    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionDestinations:
        {
            title = NSLocalizedStringWithDefaultValue(@"PhoneView DestinationsHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used By Destinations",
                                                      @"Table header above destinations\n"
                                                      @"[1 line larger font].");
            break;
        }
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"PhoneView NumbersHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used By Numbers",
                                                      @"Table header above phone numbers\n"
                                                      @"[1 line larger font].");
            break;
        }
        case TableSectionCallerIds:
        {
            title = NSLocalizedStringWithDefaultValue(@"PhoneView CallerIdsHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Used As Caller Id For Contacts",
                                                      @"Table header above contacts\n"
                                                      @"[1 line larger font].");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
        {
            if (isNew)
            {
                title = [Strings nameFooterString];
            }
            break;
        }
    }

    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:         cell = [self nameCellForRowAtIndexPath:indexPath];         break;
        case TableSectionE164:         cell = [self numberCellForRowAtIndexPath:indexPath];       break;
        case TableSectionUsage:        cell = [self usageCellForRowAtIndexPath:indexPath];        break;
        case TableSectionDestinations: cell = [self destinationsCellForRowAtIndexPath:indexPath]; break;
        case TableSectionNumbers:      cell = [self numbersCellForRowAtIndexPath:indexPath];      break;
        case TableSectionCallerIds:    cell = [self callerIdsCellForRowAtIndexPath:indexPath];    break;
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
        cell.detailTextLabel.textColor = [Skinning placeholderColor];
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


- (UITableViewCell*)usageCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SelectCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SelectCell"];
    }
    
    if (indexPath.row == 0)
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:UseCallback CellText", nil,
                                                                [NSBundle mainBundle], @"Use As Callback Phone",
                                                                @"..."
                                                                @"[....");
        if ([[Settings sharedSettings].callbackE164 isEqualToString:self.phone.e164])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    else
    {
        cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"Settings:UseDefaultCallerId CellText", nil,
                                                                [NSBundle mainBundle], @"Use As Default Caller ID",
                                                                @"..."
                                                                @"[....");
        if ([[Settings sharedSettings].callerIdE164 isEqualToString:self.phone.e164])
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
    }
    
    cell.textLabel.textColor = [Skinning tintColor];

    return cell;
}


- (UITableViewCell*)destinationsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*  cell;
    NSSortDescriptor* sortDescriptor    = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*          sortDescriptors   = [NSArray arrayWithObject:sortDescriptor];
    NSArray*          destinationsArray = [self.phone.destinations sortedArrayUsingDescriptors:sortDescriptors];
    DestinationData*  destination       = destinationsArray[indexPath.row];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DestinationsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DestinationsCell"];
    }

    cell.textLabel.text = destination.name;
    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (UITableViewCell*)numbersCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NumberData*      number = numbersArray[indexPath.row];
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumbersCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NumbersCell"];
    }
    
    cell.imageView.image = [UIImage imageNamed:number.isoCountryCode];
    cell.textLabel.text  = number.name;
    cell.accessoryType   = UITableViewCellAccessoryNone;
    cell.selectionStyle  = UITableViewCellSelectionStyleNone;
    
    return cell;
}


- (UITableViewCell*)callerIdsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"CallerIdsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CallerIdsCell"];
    }

    cell.textLabel.text = namesArray[indexPath.row];
    cell.accessoryType  = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
        {
            break;
        }
        case TableSectionE164:
        {
            if (isNew == YES)
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
                        cell.detailTextLabel.textColor = [Skinning placeholderColor];
                    }

                    [self updateSaveButtonItem];
                }];

                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case TableSectionUsage:
        {
            if (indexPath.row == 0)
            {
                [Settings sharedSettings].callbackE164 = self.phone.e164;
            }
            else
            {
                [Settings sharedSettings].callerIdE164 = self.phone.e164;
            }
            
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            break;
        }
        case TableSectionDestinations:
        {
            break;
        }
        case TableSectionNumbers:
        {
            break;
        }
    }
}


#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    BOOL shouldChange = [super textField:textField shouldChangeCharactersInRange:range replacementString:string];

    if (isNew == YES)
    {
        [self updateSaveButtonItem];
    }

    return shouldChange;
}


#pragma mark - Helper Methods

- (void)updateSaveButtonItem
{
    self.navigationItem.rightBarButtonItem.enabled = ([self.name stringByRemovingWhiteSpace].length > 0) &&
                                                     [phoneNumber isValid];
}


#pragma mark - Baseclass Override

- (void)save
{
    if (isNew == NO && isDeleting == NO)
    {
        [self saveAction];
    }
}

@end
