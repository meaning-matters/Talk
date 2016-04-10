//
//  DestinationViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/04/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "DestinationViewController.h"
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
#import "DestinationNumbersViewController.h"
#import "DataManager.h"


typedef enum
{
    TableSectionName       = 1UL << 0,  // User-given name.
    TableSectionPhone      = 1UL << 1,  //### Temporary
    TableSectionStatements = 1UL << 2,
    TableSectionNumbers    = 1UL << 3,
    TableSectionRecordings = 1UL << 4,
} TableSections;


@interface DestinationViewController ()
{
    TableSections        sections;
    BOOL                 isNew;
    BOOL                 isDeleting;

    PhoneData*           phone;
    NSMutableDictionary* action;
    NSArray*             numbersArray;
}

@property (nonatomic, assign) BOOL showCalledId;

@end


@implementation DestinationViewController

- (instancetype)initWithDestination:(DestinationData*)destination
               managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.name        = destination.name;
        phone            = [destination.phones anyObject];

        self.destination = destination;
        isNew            = (destination == nil);
        self.title       = isNew ? [Strings newDestinationString] : [Strings destinationString];

        if (isNew == YES)
        {
            // Create a new managed object context; set its parent to the fetched results controller's context.
            NSManagedObjectContext* managedObjectContext;
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            self.managedObjectContext = managedObjectContext;

            self.destination = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                             inManagedObjectContext:self.managedObjectContext];

            self.destination.action = [Common jsonStringWithObject:@{@"call" : @{@"e164s" : @[@""]}}];
        }
        else
        {
            self.managedObjectContext = managedObjectContext;

            [[Settings sharedSettings] addObserver:self
                                        forKeyPath:@"sortSegment"
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];
        }

        action = [Common mutableObjectWithJsonString:self.destination.action];

        self.showCalledId = [action[@"call"][@"showCalledId"] boolValue];
    }

    return self;
}


- (void)dealloc
{
    if (isNew == NO)
    {
        [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    if (isNew)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(createAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;

        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
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
    [self updateNumbersArray];
}


- (void)viewWillAppear:(BOOL)animated
{
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [super viewWillAppear:animated];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [self updateNumbersArray];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[Common nOfBit:TableSectionNumbers inValue:sections]]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Actions

- (void)deleteAction
{
    if (self.destination.numbers.count == 0)
    {
        NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"DestinationView DeleteTitle", nil,
                                                                  [NSBundle mainBundle], @"Delete Destination",
                                                                  @"...\n"
                                                                  @"[1/3 line small font].");

        [BlockActionSheet showActionSheetWithTitle:nil
                                        completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
        {
            if (destruct == YES)
            {
                isDeleting = YES;

                [self.destination removePhones:self.destination.phones];
                [self.destination deleteWithCompletion:^(BOOL succeeded)
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
        NSString* message;
        
        title   = NSLocalizedStringWithDefaultValue(@"DestinationView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                    @"Can't Delete Destination",
                                                    @"...\n"
                                                    @"[1/3 line small font].");
        message = NSLocalizedStringWithDefaultValue(@"DestinationView CantDeleteMessage", nil, [NSBundle mainBundle],
                                                    @"This Destination can't be deleted because it's used by one "
                                                    @"or more Numbers.",
                                                    @"Table footer that app can't be deleted\n"
                                                    @"[1 line larger font].");
        
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)createAction
{
    self.destination.name = self.name;
    action[@"call"][@"e164s"][0]     = phone.e164;
    action[@"call"][@"showCalledId"] = self.showCalledId ? @"true" : @"false";

    self.navigationItem.rightBarButtonItem.enabled = NO;

    [[WebClient sharedClient] createIvrWithName:self.name
                                         action:action
                                          reply:^(NSError* error, NSString* uuid)
    {
        if (error == nil)
        {
            self.destination.uuid   = uuid;
            self.destination.action = [Common jsonStringWithObject:action];
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            [self showSaveError:error];
        }
    }];

    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)saveAction
{
    if ([self.name isEqualToString:self.destination.name] == YES &&
        [Common object:action isEqualToJsonString:self.destination.action] == YES)
    {
        // Nothing has changed.
        return;
    }

    [[WebClient sharedClient] updateIvrForUuid:self.destination.uuid
                                          name:self.name
                                        action:action
                                         reply:^(NSError* error)
    {
        if (error == nil)
        {
            self.showCalledId       = [action[@"call"][@"showCalledId"] boolValue];
            self.destination.name   = self.name;
            self.destination.action = [Common jsonStringWithObject:action];
            
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            self.name = self.destination.name;
            [self showSaveError:error];
        }
    }];
}


- (void)showSaveError:(NSError*)error
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"Destination SaveErrorTitle", nil, [NSBundle mainBundle],
                                                @"Failed To Save",
                                                @"....\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Destination SaveErroMessage", nil, [NSBundle mainBundle],
                                                @"Failed to save this Destination: %@",
                                                @"...\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:[NSString stringWithFormat:message, [error localizedDescription]]
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        if (isNew == NO)
        {
            NSInteger        section    = [Common nOfBit:TableSectionStatements inValue:sections];
            NSIndexPath*     indexPath  = [NSIndexPath indexPathForItem:0 inSection:section];
            UITableViewCell* cell       = [self.tableView cellForRowAtIndexPath:indexPath];
            UISwitch*        switchView = (UISwitch*)cell.accessoryView;

            [switchView setOn:self.showCalledId animated:YES];
        }
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


#pragma mark - TableView Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    sections  = 0;
    sections |= TableSectionName;
    sections |= TableSectionPhone;
    sections |= TableSectionStatements;
    sections |= TableSectionNumbers;
    sections |= (self.destination.recordings.count > 0) ? TableSectionRecordings : 0;

    return [Common bitsSetCount:sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:sections])
    {
        case TableSectionName:       numberOfRows = 1;                                 break;
        case TableSectionPhone:      numberOfRows = 1;                                 break;
        case TableSectionStatements: numberOfRows = 1;                                 break;
        case TableSectionNumbers:    numberOfRows = 1;                                 break;
        case TableSectionRecordings: numberOfRows = self.destination.recordings.count; break;
    }
    
    return numberOfRows;
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
        case TableSectionStatements:
        {
            title = NSLocalizedStringWithDefaultValue(@"DestinationView RulesFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"By default you'll see the number of the person that's "
                                                      @"calling you as caller ID on your Phone. When switching on "
                                                      @"this option you'll see your Number as Caller ID instead. "
                                                      @"This can be useful when you have several Numbers and you "
                                                      @"want to know from which Number a call originates.",
                                                      @"Table footer ...\n"
                                                      @"[1 line larger font].");
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
        case TableSectionName:       cell = [self nameCellForRowAtIndexPath:indexPath];       break;
        case TableSectionPhone:      cell = [self phoneCellForRowAtIndexPath:indexPath];      break;
        case TableSectionStatements: cell = [self statementsCellForRowAtIndexPath:indexPath]; break;
        case TableSectionNumbers:    cell = [self numbersCellForRowAtIndexPath:indexPath];    break;
        case TableSectionRecordings: cell = [self recordingsCellForRowAtIndexPath:indexPath]; break;
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

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"DestinationView ForwardTo", nil, [NSBundle mainBundle],
                                                            @"Forward To",
                                                            @"Title of a table row\n"
                                                            @"[1/3 line small font].");
    cell.detailTextLabel.text = phone.name;

    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (UITableViewCell*)statementsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"StatementsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"StatementsCell"];

        switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchView.onTintColor = [Skinning onTintColor];
        cell.accessoryView = switchView;

        [switchView addTarget:self
                       action:@selector(showCalledIdSwitchAction:)
             forControlEvents:UIControlEventValueChanged];
    }
    else
    {
        switchView = (UISwitch*)cell.accessoryView;
    }

    switchView.on = self.showCalledId;

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"DestinationView RulesTitle", nil,
                                                            [NSBundle mainBundle], @"Show Called Number",
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

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumbersCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"NumbersCell"];
    }

    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"DestinationView NumbersTitle", nil,
                                                            [NSBundle mainBundle], @"Used By Numbers",
                                                            @"Title of an table row\n"
                                                            @"[1/3 line small font].");
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%lu", (unsigned long)self.destination.numbers.count];
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle  = UITableViewCellSelectionStyleDefault;

    return cell;
}


- (UITableViewCell*)recordingsCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSSortDescriptor*   sortDescriptor  = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray*            sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray*            recordingsArray = [self.destination.recordings sortedArrayUsingDescriptors:sortDescriptors];
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
        case TableSectionPhone:
        {
            PhonesViewController* viewController;
            viewController = [[PhonesViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                          selectedPhone:[self.destination.phones anyObject]
                                                                             completion:^(PhoneData* selectedPhone)
            {
                phone = selectedPhone;
                action[@"call"][@"e164s"][0] = phone.e164;

                [self updateSaveButtonItem];
                [self updateTable];

                [self save];
            }];

            viewController.headerTitle = @"";
            viewController.footerTitle = @"";

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionNumbers:
        {
            DestinationNumbersViewController* viewController;
            viewController = [[DestinationNumbersViewController alloc] initWithDestination:self.destination];

            [self.navigationController pushViewController:viewController animated:YES];
        }
    }
}


#pragma mark - TextField Delegate

- (BOOL)textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    BOOL shouldChange = [super textField:textField shouldChangeCharactersInRange:range replacementString:string];

    [self updateSaveButtonItem];

    return shouldChange;
}


#pragma mark - Action

- (void)showCalledIdSwitchAction:(UISwitch*)switchView
{
    action[@"call"][@"showCalledId"] = switchView.on ? @"true" : @"false";

    if (isNew == YES)
    {
        self.showCalledId = switchView.on;
    }
    else
    {
        [self saveAction];
    }
}


#pragma mark - Helper Methods

- (void)updateSaveButtonItem
{
    if (isNew == YES)
    {
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:phone.e164];
        BOOL         valid       = [self.name stringByRemovingWhiteSpace].length > 0 &&
                                   ((phoneNumber.isValid && [Settings sharedSettings].homeIsoCountryCode.length > 0) ||
                                    phoneNumber.isInternational);

        self.navigationItem.leftBarButtonItem.enabled = valid;
    }
}


- (void)updateNumbersArray
{
    NSSortDescriptor* sortDescriptorCountry = [[NSSortDescriptor alloc] initWithKey:@"e164" ascending:YES];
    NSSortDescriptor* sortDescriptorName    = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
    NSArray*          sortDescriptors;

    if ([Settings sharedSettings].sortSegment == 0)
    {
        sortDescriptors = @[sortDescriptorCountry, sortDescriptorName];
    }
    else
    {
        sortDescriptors = @[sortDescriptorName, sortDescriptorCountry];
    }

    numbersArray = [self.destination.numbers sortedArrayUsingDescriptors:sortDescriptors];
}


- (void)updateTable
{
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath == nil)
    {
        [self.tableView reloadData];
    }
    else
    {
        [self.tableView reloadRowsAtIndexPaths:@[selectedIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


#pragma mark - Baseclass Override

- (void)save
{
    if (isNew == NO && isDeleting == NO)
    {
        [self saveAction];
    }
}


- (void)update
{
    [self updateSaveButtonItem];
}

@end
