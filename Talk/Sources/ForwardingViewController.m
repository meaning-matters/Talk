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


static const int    TextFieldCellTag = 1111;


@interface ForwardingViewController ()
{
    TableSections    sections;
    BOOL             isNew;

    NSString*        name;
    PhoneData*       phone;
    PhoneNumber*     phoneNumber;
    NSMutableArray*  statementsArray;
    NSArray*         numbersArray;

    UIBarButtonItem* rightBarButtonItem;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@end


@implementation ForwardingViewController

- (instancetype)initWithForwarding:(ForwardingData*)forwarding
              managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title  = [Strings forwardingString];
        name        = forwarding.name;
        phone       = [forwarding.phones anyObject];
        phoneNumber = [[PhoneNumber alloc] init];

        self.managedObjectContext = managedObjectContext;
        self.forwarding           = forwarding;
        isNew                     = (forwarding == nil);

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
            [[Settings sharedSettings] addObserver:self
                                        forKeyPath:@"numbersSortSegment"
                                           options:NSKeyValueObservingOptionNew
                                           context:nil];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleManagedObjectsChange:)
                                                     name:NSManagedObjectContextObjectsDidChangeNotification
                                                   object:self.managedObjectContext];

        statementsArray    = [Common mutableObjectWithJsonString:self.forwarding.statements];
        phoneNumber.number = statementsArray[0][@"call"][@"e164"][0];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextObjectsDidChangeNotification
                                                  object:self.managedObjectContext];

    if (isNew == NO)
    {
        [[Settings sharedSettings] removeObserver:self forKeyPath:@"numbersSortSegment" context:nil];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    if (isNew == YES)
    {
        UIBarButtonItem* leftBarButtonItem;
        leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = leftBarButtonItem;

        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                           target:self
                                                                           action:@selector(saveAction)];
    }
    else
    {
        rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                           target:self
                                                                           action:@selector(deleteAction)];
    }

    self.navigationItem.rightBarButtonItem = rightBarButtonItem;
    [self updateRightBarButtonItem];
    [self updateNumbersArray];

    // Let keyboard be hidden when user taps outside text fields.
    UITapGestureRecognizer* gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    gestureRecognizer.delegate             = self;
    [self.tableView addGestureRecognizer:gestureRecognizer];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        if (self.forwarding.phones.count != 0)
        {
            phone              = [self.forwarding.phones anyObject];
            phoneNumber.number = phone.e164;
        }

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


- (void)handleManagedObjectsChange:(NSNotification*)note
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

    [self updateRightBarButtonItem];
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


- (void)create
{
    self.forwarding.name = name;
    statementsArray[0][@"call"][@"e164"][0] = phoneNumber.e164Format;
    self.forwarding.statements = [Common jsonStringWithObject:statementsArray];

    NSString* uuid = [[NSUUID UUID] UUIDString];
    self.forwarding.uuid = uuid;
    [[WebClient sharedClient] createIvrForUuid:uuid
                                          name:name
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


- (void)save
{
    if ([name isEqualToString:self.forwarding.name] == YES &&
        [Common object:statementsArray isEqualToJsonString:self.forwarding.statements] == YES)
    {
        // Nothing has changed.
        return;
    }

    self.forwarding.name = name;
    statementsArray[0][@"call"][@"e164"][0] = phoneNumber.e164Format;
    self.forwarding.statements = [Common jsonStringWithObject:statementsArray];

    [[WebClient sharedClient] updateIvrForUuid:self.forwarding.uuid
                                          name:name
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
#if FULL_FORWARDINGS
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


- (UITableViewCell*)phoneCellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"PhoneCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:@"PhoneCell"];
    }

    cell.textLabel.text  = [Strings phoneString];
    [Common addCountryImageToCell:cell isoCountryCode:phoneNumber.isoCountryCode];

    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;
    if (isNew)
    {
        if (phone == nil)
        {
            cell.detailTextLabel.text      = [Strings requiredString];
            cell.detailTextLabel.textColor = [UIColor lightGrayColor];
        }
        else
        {
            cell.detailTextLabel.text      = phone.name;
            cell.detailTextLabel.textColor = [UIColor blackColor];
        }
    }
    else
    {
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
    cell.selectionStyle  = UITableViewCellSelectionStyleBlue;

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

    cell.textLabel.text = @" ";  // Without this, detailTextLabel is on the left.
    [Common addCountryImageToCell:cell isoCountryCode:number.numberCountry];

    cell.detailTextLabel.text = number.name;
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle       = UITableViewCellSelectionStyleBlue;

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

        case TableSectionPhone:
        {
            if (isNew)
            {
                PhonesViewController* viewController;
                viewController = [[PhonesViewController alloc] initWithForwarding:self.forwarding
                                                             managedObjectContext:self.managedObjectContext];

                [self.navigationController pushViewController:viewController animated:YES];
            }
            else
            {
                PhoneViewController* viewController;
                viewController = [[PhoneViewController alloc] initWithPhone:phone
                                                       managedObjectContext:self.managedObjectContext];
                [self.navigationController pushViewController:viewController animated:YES];
            }
            break;
        }
        case TableSectionStatements:
            break;

        case TableSectionNumbers:
        {
            NumberData*           number         = numbersArray[indexPath.row];
            NumberViewController* viewController = [[NumberViewController alloc] initWithNumber:number];

            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionRecordings:
            break;
    }
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


#pragma mark - TextField Delegate

- (BOOL)textFieldShouldClear:(UITextField*)textField
{
    name = @"";

    [self updateRightBarButtonItem];

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
    NSString* text = [textField.text stringByReplacingCharactersInRange:range withString:string];

    name = text;
    [self updateRightBarButtonItem];

    return YES;
}


#pragma mark - Helper Methods

- (void)updateRightBarButtonItem
{
    BOOL valid;

    valid   = [name stringByReplacingOccurrencesOfString:@" " withString:@""].length > 0 &&
              ((phoneNumber.isValid && [Settings sharedSettings].homeCountry.length > 0) || phoneNumber.isInternational);

    if (isNew == YES)
    {
        rightBarButtonItem.enabled = valid;
    }
    else
    {
        rightBarButtonItem.enabled = (self.forwarding.numbers.count == 0);
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


- (void)hideKeyboard:(UIGestureRecognizer*)gestureRecognizer
{
    if (name.length > 0)
    {
        [[self.tableView superview] endEditing:YES];

        [self save];
    }
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
