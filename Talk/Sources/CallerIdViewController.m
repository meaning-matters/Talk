//
//  CallerIdViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//
//  This view can be shown in two quite different situations:
//  A. From Contacts, to select the called ID for a contact.
//  B. From Settings, to select the default caller ID (does not get 'callerId'
//     nor 'contactId' parameters.
//
//  When making changes, make sure to test all possible states & transitions
//  for both situations above.
//

//http://stackoverflow.com/questions/8997387/tableview-with-two-instances-of-nsfetchedresultscontroller

#import "CallerIdViewController.h"
#import "Common.h"
#import "Strings.h"
#import "DataManager.h"
#import "CallerIdData.h"
#import "PhoneData.h"
#import "NumberData.h"
#import "Settings.h"

typedef enum
{
    TableSectionShowCallerId = 1UL << 0,
    TableSectionPhones       = 1UL << 1,
} TableSections;


@interface CallerIdViewController ()

@property (nonatomic, assign) TableSections           sections;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) CallerIdData*           callerId;
@property (nonatomic, strong) NSString*               contactId;
@property (nonatomic, strong) CallableData*           selectedCallable;
@property (nonatomic, copy) void (^completion)(CallableData* selectedCallable, BOOL showCallerId);
@property (nonatomic, strong) NSArray*                phones;

@end


@implementation CallerIdViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                                    callerId:(CallerIdData*)callerId
                            selectedCallable:(CallableData*)selectedCallable
                                   contactId:(NSString*)contactId   // Used as mode switch for Contacts or Settings.
                                  completion:(void (^)(CallableData* selectedCallable, BOOL showCallerId))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title                = [Strings callerIdString];
        self.managedObjectContext = managedObjectContext;
        self.callerId             = callerId;
        self.contactId            = contactId;
        self.selectedCallable     = selectedCallable;
        self.completion           = completion;

        self.phones               = [self fetchPhones];
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

    if (self.callerId != nil && self.callerId.callable != nil)
    {
        // We get here from contact info view.  A caller already been selected.
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectedCallable != nil)
    {
        // Needs to run on next run loop or else does not properly scroll to bottom items.
        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.tableView scrollToRowAtIndexPath:[self selectedIndexPath]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:NO];
        });
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self isMovingFromParentViewController])
    {
         self.completion ? self.completion(self.selectedCallable, [self showCallerId]) : 0;
    }
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    self.phones  = [self fetchPhones];
    [self.tableView reloadData];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections = (self.contactId != nil) ? TableSectionShowCallerId : 0;

    if ([self showCallerId] || (self.contactId == nil))
    {
        self.sections |= (self.phones.count  > 0) ? TableSectionPhones  : 0;
    }
    
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((TableSections)[Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionShowCallerId: return 1;
        case TableSectionPhones:       return self.phones.count;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ((TableSections)[Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionShowCallerId:
        {
            title = nil;
            break;
        }
        case TableSectionPhones:
        {
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Select A Phone As Caller ID", @"...");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ((TableSections)[Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionShowCallerId:
        {
            title = nil;
            break;
        }
        case TableSectionPhones:
        {
            if (self.contactId != nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionFooterA", nil, [NSBundle mainBundle],
                                                          @"The selected Phone will be used as Caller ID for all "
                                                          @"your calls to this contact.",
                                                          @"...\n"
                                                          @"[* lines]");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionFooterB", nil, [NSBundle mainBundle],
                                                          @"The selected Phone will be used when dialling a number, or "
                                                          @"when calling a contact you did not assign a Caller ID.",
                                                          @"...\n"
                                                          @"[* lines]");
            }
            break;
        }
    }
    
    return title;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    
    switch ((TableSections)[Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionShowCallerId: cell = [self switchCell];                                              break;
        case TableSectionPhones:       cell = [self callableCell:[self.phones objectAtIndex:indexPath.row]]; break;
    }

    return cell;
}


- (UITableViewCell*)switchCell
{
    UITableViewCell* cell;
    UISwitch*        switchView;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SwitchCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SwitchCell"];
        switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        switchView.onTintColor = [Skinning onTintColor];
        cell.accessoryView = switchView;
    }
    else
    {
        switchView = (UISwitch*)cell.accessoryView;
    }
    
    cell.textLabel.text = NSLocalizedStringWithDefaultValue(@"CallerId:ShowCallId CellText", nil,
                                                            [NSBundle mainBundle], @"Hide My Caller ID",
                                                            @"Title of switch if people called see my number\n"
                                                            @"[2/3 line - abbreviated: 'Show Caller ID', use "
                                                            @"exact same term as in iOS].");
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switchView.on = ![self showCallerId];
    
    [switchView removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
    [switchView addTarget:self
                   action:@selector(showCallerIdSwitchAction:)
         forControlEvents:UIControlEventValueChanged];
    
    return cell;
}


- (UITableViewCell*)callableCell:(CallableData*)callable
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    cell.textLabel.text       = callable.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:callable.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.imageView.image      = [UIImage imageNamed:[phoneNumber isoCountryCode]];
    
    if (callable == self.selectedCallable)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionShowCallerId:
        {
            return;
        }
        case TableSectionPhones:
        {
            self.selectedCallable = [self.phones objectAtIndex:indexPath.row];

            [self selectCallerId];
            [self.navigationController popViewControllerAnimated:YES];
            break;
        }
    }
}


- (void)selectCallerId
{
    if (self.contactId != nil)
    {
        if (self.callerId == nil)
        {
            self.callerId = [NSEntityDescription insertNewObjectForEntityForName:@"CallerId"
                                                          inManagedObjectContext:self.managedObjectContext];
            self.callerId.contactId = self.contactId;
        }

        self.callerId.callable = self.selectedCallable;

        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    }
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}


#pragma Helpers

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)deleteAction
{
    [self.managedObjectContext deleteObject:self.callerId];
    self.callerId = nil;
    self.selectedCallable = nil;
    
    self.completion ? self.completion(nil, [self showCallerId]) : 0;
    
    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    
    // We can only get here pushed from a contact.
    [self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)showCallerId
{
    if (self.contactId != nil)
    {
        return ((self.callerId == nil) || (self.callerId.callable != nil));
    }
    else
    {
        return [Settings sharedSettings].showCallerId;
    }
}


- (void)showCallerIdSwitchAction:(UISwitch*)switchView
{
    // This method can only be called for contacts, so we don't have to check self.contactId here.
    if (switchView.on)
    {
        NSInteger   numberOfSections = [self numberOfSectionsInTableView:self.tableView];
        NSRange     range            = NSMakeRange(1, numberOfSections - 1);
        NSIndexSet* indexSet         = [NSIndexSet indexSetWithIndexesInRange:range];

        if (self.callerId == nil)
        {
            self.callerId = [NSEntityDescription insertNewObjectForEntityForName:@"CallerId"
                                                          inManagedObjectContext:self.managedObjectContext];
            self.callerId.contactId = self.contactId;
        }
    
        self.callerId.callable = nil;
        self.selectedCallable  = nil;
        
        [self.tableView beginUpdates];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.333 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    else
    {
        [self.managedObjectContext deleteObject:self.callerId];
        self.callerId = nil;
        
        NSInteger   numberOfSections = [self numberOfSectionsInTableView:self.tableView];
        NSRange     range            = NSMakeRange(1, numberOfSections - 1);
        NSIndexSet* indexSet         = [NSIndexSet indexSetWithIndexesInRange:range];
        
        [self.tableView beginUpdates];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
    }

    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
}


- (NSArray*)fetchPhones
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                     sortKeys:[Common sortKeys]
                                                    predicate:nil
                                         managedObjectContext:self.managedObjectContext];
}


- (NSIndexPath*)selectedIndexPath
{
    NSUInteger index;
    
    if ((index = [self.phones indexOfObject:self.selectedCallable]) != NSNotFound)
    {
        NSInteger section = [Common nOfBit:TableSectionPhones inValue:self.sections];
        
        return [NSIndexPath indexPathForItem:index inSection:section];
    }

    return nil;
}

@end
