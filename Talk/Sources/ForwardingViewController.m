//
//  ForwardingViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingViewController.h"
#import "Common.h"
#import "Strings.h"
#import "NumberData.h"
#import "RecordingData.h"
#import "PhoneData.h"
#import "PhoneNumber.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockActionSheet.h"
#import "BlockAlertView.h"
#import "PhonesViewController.h"
#import "PhoneViewController.h"
#import "NumberViewController.h"
#import "DataManager.h"


typedef enum
{
    TableSectionName       = 1UL << 0,  // User-given name.
    TableSectionPhone      = 1UL << 1,  //### Temporary
    TableSectionStatements = 1UL << 2,
    TableSectionNumbers    = 1UL << 3,
    TableSectionRecordings = 1UL << 4,
} TableSections;


@interface ForwardingViewController ()
{
    TableSections    sections;
    BOOL             isNew;

    PhoneData*       phone;
    NSMutableArray*  statementsArray;
    NSArray*         numbersArray;
}

@end


@implementation ForwardingViewController

- (instancetype)initWithForwarding:(ForwardingData*)forwarding
              managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.name       = forwarding.name;
        phone           = [forwarding.phones anyObject];

        self.forwarding = forwarding;
        isNew           = (forwarding == nil);
        self.title      = isNew ? [Strings newForwardingString] : [Strings forwardingString];

        if (isNew == YES)
        {
            // Create a new managed object context; set its parent to the fetched results controller's context.
            NSManagedObjectContext* managedObjectContext;
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            self.managedObjectContext = managedObjectContext;

            self.forwarding = (ForwardingData*)[NSEntityDescription insertNewObjectForEntityForName:@"Forwarding"
                                                                             inManagedObjectContext:self.managedObjectContext];

            self.forwarding.statements = [Common jsonStringWithObject:@[@{@"call" : @{@"e164" : @[@""]}}]];
        }
        else
        {
            self.managedObjectContext = managedObjectContext;

            [[Settings sharedSettings] addObserver:self
                                        forKeyPath:@"numbersSortSegment"
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];
        }

        statementsArray = [Common mutableObjectWithJsonString:self.forwarding.statements];
    }
    
    return self;
}


- (void)dealloc
{
    if (isNew == NO)
    {
        [[Settings sharedSettings] removeObserver:self forKeyPath:@"numbersSortSegment" context:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(createAction)];
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

    [self updateRightBarButtonItem];
    [self updateNumbersArray];
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


- (void)observeValueForKeyPath:(NSString*)keyPath
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
    [self updateNumbersArray];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[Common nOfBit:TableSectionNumbers inValue:sections]]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Actions

- (void)deleteAction
{
    NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"ForwardingView DeleteTitle", nil,
                                                              [NSBundle mainBundle], @"Delete Forwarding",
                                                              @"...\n"
                                                              @"[1/3 line small font].");

    [BlockActionSheet showActionSheetWithTitle:nil
                                    completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
    {
        if (destruct == YES)
        {
            [self.forwarding deleteFromManagedObjectContext:self.managedObjectContext
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


- (void)createAction
{
    self.forwarding.name = self.name;
    statementsArray[0][@"call"][@"e164"][0] = phone.e164;
    self.forwarding.statements = [Common jsonStringWithObject:statementsArray];

    NSString* uuid = [[NSUUID UUID] UUIDString];
    self.forwarding.uuid = uuid;
    [[WebClient sharedClient] createIvrForUuid:uuid
                                          name:self.name
                                    statements:statementsArray
                                         reply:^(NSError* error)
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
}


- (void)saveAction
{
    if ([self.name isEqualToString:self.forwarding.name] == YES &&
        [Common object:statementsArray isEqualToJsonString:self.forwarding.statements] == YES)
    {
        // Nothing has changed.
        return;
    }

    self.forwarding.name = self.name;
    statementsArray[0][@"call"][@"e164"][0] = phone.e164;
    self.forwarding.statements = [Common jsonStringWithObject:statementsArray];

    [[WebClient sharedClient] updateIvrForUuid:self.forwarding.uuid
                                          name:self.name
                                    statements:statementsArray
                                         reply:^(NSError* error)
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
}


- (void)showSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Forwarding SaveErrorTitle", nil, [NSBundle mainBundle],
                                                @"Failed To Save",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Forwarding SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Failed to save this Forwarding: %@.",
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
    sections  = 0;
    sections |= TableSectionName;
    sections |= TableSectionPhone;
#if HAS_FULL_FORWARDINGS
    sections |= TableSectionStatements;
#endif
    sections |= (self.forwarding.numbers.count    > 0) ? TableSectionNumbers    : 0;
    sections |= (self.forwarding.recordings.count > 0) ? TableSectionRecordings : 0;

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

        case TableSectionPhone:
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


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionPhone:
            title = NSLocalizedStringWithDefaultValue(@"ForwardingView PhoneHeader", nil,
                                                      [NSBundle mainBundle],
                                                      @"Calls Go To Phone",
                                                      @"Table header above phone numbers\n"
                                                      @"[1 line larger font].");
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"ForwardingView NumbersHeader", nil,
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
    NSString*   title = nil;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:
            if (isNew)
            {
                title = [Strings nameFooterString];
            }
            break;

        case TableSectionStatements:
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"ForwardingView CanNotDeleteFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"This Forwarding can't be deleted because it's in use.",
                                                      @"Table footer that app can't be deleted\n"
                                                      @"[1 line larger font].");
            break;

        case TableSectionRecordings:
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

        case TableSectionPhone:
            cell = [self phoneCellForRowAtIndexPath:indexPath];
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


- (UITableViewCell*)phoneCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"PhoneCell"];
    }

    if (phone != nil)
    {
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:phone.e164];
        [Common addCountryImageToCell:cell isoCountryCode:phoneNumber.isoCountryCode];
    }
    else
    {
        cell.textLabel.text = [Strings phoneString];
    }

    cell.selectionStyle  = UITableViewCellSelectionStyleDefault;
    if (isNew)
    {
        if (phone == nil)
        {
            cell.accessoryType             = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.text      = [Strings requiredString];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
        else
        {
            cell.accessoryType             = UITableViewCellAccessoryDetailDisclosureButton;
            cell.detailTextLabel.text      = phone.name;
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
    }
    else
    {
        cell.accessoryType             = UITableViewCellAccessoryDetailDisclosureButton;
        cell.detailTextLabel.text      = phone.name;
        cell.detailTextLabel.textColor = [UIColor blackColor];
    }

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
    cell.selectionStyle  = UITableViewCellSelectionStyleDefault;

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
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle       = UITableViewCellSelectionStyleDefault;

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
    cell.selectionStyle  = UITableViewCellSelectionStyleDefault;

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:sections])
    {
        case TableSectionName:
            break;

        case TableSectionPhone:
        {
            PhonesViewController* viewController;
            viewController = [[PhonesViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                          selectedPhone:[self.forwarding.phones anyObject]
                                                                             completion:^(PhoneData* selectedPhone)
            {
                phone = selectedPhone;
                [self.forwarding removePhones:self.forwarding.phones];
                [self.forwarding addPhonesObject:phone];

                [self updateTable];
            }];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionStatements:
        {
            break;
        }
        case TableSectionNumbers:
        {
            NumberData*           number         = numbersArray[indexPath.row];
            NumberViewController* viewController = [[NumberViewController alloc] initWithNumber:number];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionRecordings:
        {
            break;
        }
    }
}


- (void)tableView:(UITableView*)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath*)indexPath
{
    PhoneViewController* viewController;
    viewController = [[PhoneViewController alloc] initWithPhone:phone
                                           managedObjectContext:self.managedObjectContext];
    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    BOOL shouldChange = [super textField:textField shouldChangeCharactersInRange:range replacementString:string];

    self.name = textField.text;
    [self updateRightBarButtonItem];

    return shouldChange;
}


#pragma mark - Helper Methods

- (void)updateRightBarButtonItem
{
    PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:phone.e164];
    BOOL         valid;

    valid = [self.name stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0 &&
            ((phoneNumber.isValid && [Settings sharedSettings].homeCountry.length > 0) || phoneNumber.isInternational);

    if (isNew == YES)
    {
        self.navigationItem.rightBarButtonItem.enabled = valid;
    }
    else
    {
        self.navigationItem.rightBarButtonItem.enabled = (self.forwarding.numbers.count == 0);
    }
}


- (void)updateNumbersArray
{
    NSSortDescriptor* sortDescriptorCountry = [[NSSortDescriptor alloc] initWithKey:@"numberCountry" ascending:YES];
    NSSortDescriptor* sortDescriptorName    = [[NSSortDescriptor alloc] initWithKey:@"name"          ascending:YES];
    NSArray*          sortDescriptors;

    if ([Settings sharedSettings].numbersSortSegment == 0)
    {
        sortDescriptors = @[sortDescriptorCountry, sortDescriptorName];
    }
    else
    {
        sortDescriptors = @[sortDescriptorName, sortDescriptorCountry];
    }

    numbersArray = [self.forwarding.numbers sortedArrayUsingDescriptors:sortDescriptors];
}


#pragma mark - Baseclass Override

- (void)save
{
    if (isNew == NO)
    {
        [self saveAction];
    }
}


- (void)update
{
    [self updateRightBarButtonItem];
}

@end
