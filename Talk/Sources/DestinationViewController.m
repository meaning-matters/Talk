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

@property (nonatomic, assign) TableSections sections;
@property (nonatomic, assign) BOOL          isNew;
@property (nonatomic, assign) BOOL          isDeleting;
@property (nonatomic, strong) PhoneData*    phone;
@property (nonatomic, strong) NSMutableDictionary* action;
@property (nonatomic, strong) NSArray*      numbersArray;
@property (nonatomic, copy) void (^completion)(DestinationData* destination);

@property (nonatomic, assign) BOOL showCalledId;

@end


@implementation DestinationViewController

- (instancetype)initWithDestination:(DestinationData*)destination
               managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    return [self initWithDestination:destination managedObjectContext:managedObjectContext completion:nil];
}


- (instancetype)initWithCompletion:(void (^)(DestinationData* destination))completion
{
    return [self initWithDestination:nil
                managedObjectContext:[DataManager sharedManager].managedObjectContext
                          completion:completion];
}


- (instancetype)initWithDestination:(DestinationData*)destination
               managedObjectContext:(NSManagedObjectContext*)managedObjectContext
                         completion:(void (^)(DestinationData* destination))completion
{
    if (self = [super initWithManagedObjectContext:managedObjectContext])
    {
        self.phone       = [destination.phones anyObject];

        self.destination = destination;
        self.completion  = completion;
        self.isNew       = (destination == nil);
        self.title       = self.isNew ? [Strings newDestinationString] : [Strings destinationString];

        if (self.isNew == YES)
        {
            // Create a new managed object context; set its parent to the fetched results controller's context.
            NSManagedObjectContext* managedObjectContext;
            managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
            [managedObjectContext setParentContext:self.managedObjectContext];
            self.managedObjectContext = managedObjectContext;

            self.destination = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                             inManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            self.managedObjectContext = managedObjectContext;

            [[Settings sharedSettings] addObserver:self
                                        forKeyPath:@"sortSegment"
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];

            self.action       = [Common mutableObjectWithJsonString:self.destination.action];
            self.showCalledId = [self.action[@"call"][@"showCalledId"] boolValue];
        }

        self.item = self.destination;

        NSInteger section  = [Common nOfBit:TableSectionName inValue:self.sections];
        self.nameIndexPath = [NSIndexPath indexPathForRow:0 inSection:section];
    }

    return self;
}


- (void)dealloc
{
    if (self.isNew == NO)
    {
        [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    if (self.isNew)
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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:[Common nOfBit:TableSectionNumbers inValue:self.sections]]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - Actions

- (void)cancelAction
{
    self.completion ? self.completion(nil) : 0;
    self.completion = nil;

    [super cancelAction];
}


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
                self.isDeleting = YES;

                [self.destination removePhones:self.destination.phones];
                [self.destination deleteWithCompletion:^(BOOL succeeded)
                {
                    if (succeeded)
                    {
                        [self.navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        self.isDeleting = NO;
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
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [self.destination createForE164:self.phone.e164
                               name:self.destination.name
                       showCalledId:self.showCalledId
                         completion:^(NSError* error)
    {
        if (error == nil)
        {
            // This saves the object on the child MOC (created during init) which
            // propagates to the main MOC.
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

            // Now get the saved object from parent/main MOC.
            NSManagedObjectContext* mainContext = [DataManager sharedManager].managedObjectContext;
            self.destination = [mainContext existingObjectWithID:self.destination.objectID error:nil];

            self.completion ? self.completion(self.destination) : 0;
            self.completion = nil;
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
    if (self.destination.changedValues.count == 0 &&
        [Common object:self.action isEqualToJsonString:self.destination.action] == YES)
    {
        // Nothing has changed.
        return;
    }

    [[WebClient sharedClient] updateDestinationForUuid:self.destination.uuid
                                                  name:self.destination.name
                                                action:self.action
                                                 reply:^(NSError* error)
    {
        if (error == nil)
        {
            self.showCalledId       = [self.action[@"call"][@"showCalledId"] boolValue];
            self.destination.action = [Common jsonStringWithObject:self.action];
            
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }
        else
        {
            [self.destination.managedObjectContext refreshObject:self.destination mergeChanges:NO];
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
        self.completion ? self.completion(nil) : 0;
        self.completion = nil;

        if (self.isNew == NO)
        {
            NSInteger        section    = [Common nOfBit:TableSectionStatements inValue:self.sections];
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
    self.sections  = 0;
    self.sections |= TableSectionName;
    self.sections |= TableSectionPhone;
    self.sections |= TableSectionStatements;
    self.sections |= self.isNew ? 0 : TableSectionNumbers;
    self.sections |= (self.destination.recordings.count > 0) ? TableSectionRecordings : 0;

    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:self.sections])
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

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionName:
        {
            if (self.isNew)
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

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
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
    cell.detailTextLabel.text = self.phone.name;

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
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionPhone:
        {
            PhoneData*            phone = self.isNew ? self.phone : [self.destination.phones anyObject];
            PhonesViewController* viewController;

            viewController = [[PhonesViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                          selectedPhone:phone
                                                                           hasAddButton:NO
                                                                             completion:^(PhoneData *selectedPhone)
            {
                self.phone = selectedPhone;
                self.action[@"call"][@"e164s"][0] = self.phone.e164;

                [self updateSaveButtonItem];
                [self updateTable];

                [self save];
            }];

            viewController.headerTitle = NSLocalizedStringWithDefaultValue(@"DestinationView Phones Footer Title", nil,
                                                                           [NSBundle mainBundle],
                                                                           @"Select Phone to receive calls",
                                                                           @"Title of an table row\n"
                                                                           @"[1/3 line small font].");
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
    self.action[@"call"][@"showCalledId"] = switchView.on ? @YES : @NO;

    if (self.isNew == YES)
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
    if (self.isNew == YES)
    {
        PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:self.phone.e164];
        BOOL         valid       = [self.destination.name stringByRemovingWhiteSpace].length > 0 &&
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

    self.numbersArray = [self.destination.numbers sortedArrayUsingDescriptors:sortDescriptors];
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
    if (self.isNew == NO && self.isDeleting == NO)
    {
        [self saveAction];
    }
}


- (void)update
{
    [self updateSaveButtonItem];
}

@end
