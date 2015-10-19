//
//  CallerIdViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

//http://stackoverflow.com/questions/8997387/tableview-with-two-instances-of-nsfetchedresultscontroller

#import "CallerIdViewController.h"
#import "Common.h"
#import "Strings.h"
#import "DataManager.h"
#import "CallerIdData.h"
#import "PhoneData.h"
#import "NumberData.h"

typedef enum
{
    TableSectionShowCallerId = 1UL << 0,
    TableSectionPhones       = 1UL << 1,
    TableSectionNumbers      = 1UL << 2,
} TableSections;


@interface CallerIdViewController ()

@property (nonatomic, assign) TableSections           sections;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) CallerIdData*           callerId;
@property (nonatomic, strong) NSString*               contactId;
@property (nonatomic, strong) CallableData*           selectedCallable;
@property (nonatomic, copy) void (^completion)(CallableData* selectedCallable);
@property (nonatomic, strong) NSArray*                phones;
@property (nonatomic, strong) NSArray*                numbers;

@end


@implementation CallerIdViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                                    callerId:(CallerIdData*)callerId
                                   contactId:(NSString*)contactId
                                  completion:(void (^)(CallableData* selectedCallable))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title                = [Strings callerIdString];
        self.managedObjectContext = managedObjectContext ? managedObjectContext : [DataManager sharedManager].managedObjectContext;
        self.callerId             = callerId;
        self.contactId            = contactId;
        self.selectedCallable     = callerId.callable;
        self.completion           = completion;

        self.phones               = [self fetchPhones];
#if HAS_NUMBERS
        self.numbers              = [self fetchNumbers];
#endif
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.navigationController.presentingViewController != nil)
    {
        // We get here when selected to assign a caller ID right before a call.
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancelAction)];
        self.navigationItem.leftBarButtonItem = buttonItem;
    }
    else if (self.callerId != nil)
    {
        // We get here from contact info view.  A caller already been selected.
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                                   target:self
                                                                   action:@selector(deleteAction)];
        self.navigationItem.rightBarButtonItem = buttonItem;
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([self isMovingFromParentViewController])
    {
        self.completion ? self.completion(self.callerId.callable) : (void)0;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    self.sections = TableSectionShowCallerId;

    if (self.callerId == nil || self.callerId.callable != nil)
    {
        self.sections |= (self.phones.count  > 0) ? TableSectionPhones  : 0;
        self.sections |= (self.numbers.count > 0) ? TableSectionNumbers : 0;
    }
    
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ((TableSections)[Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionShowCallerId: return 1;
        case TableSectionPhones:       return self.phones.count;
        case TableSectionNumbers:      return self.numbers.count;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

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
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Numbers SectionHeader", nil, [NSBundle mainBundle],
                                                      @"Select A Number As Caller ID", @"...");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    switch ((TableSections)[Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionShowCallerId:
        {
            title = nil;
            break;
        }
        case TableSectionPhones:
        {
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionFooter", nil, [NSBundle mainBundle],
                                                      @"The selected Phone will be used as caller ID for all "
                                                      @"your calls to this contact.",
                                                      @"...\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Numbers SectionFooter", nil, [NSBundle mainBundle],
                                                      @"The selected Number will be used as caller ID for all "
                                                      @"your calls to this contact.",
                                                      @"...\n"
                                                      @"[* lines]");
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
        case TableSectionPhones:       cell = [self callableCell:[self.phones  objectAtIndex:indexPath.row]]; break;
        case TableSectionNumbers:      cell = [self callableCell:[self.numbers objectAtIndex:indexPath.row]]; break;
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
                                                            [NSBundle mainBundle], @"Show My Caller ID",
                                                            @"Title of switch if people called see my number\n"
                                                            @"[2/3 line - abbreviated: 'Show Caller ID', use "
                                                            @"exact same term as in iOS].");
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    switchView.on = ((self.callerId == nil) || (self.callerId.callable != nil));
    
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
    
    if (callable == self.callerId.callable)
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
    CallableData* callable = nil;
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionShowCallerId:
        {
            return;
        }
        case TableSectionPhones:
        {
            callable = [self.phones objectAtIndex:indexPath.row];
            break;
        }
        case TableSectionNumbers:
        {
            callable = [self.numbers objectAtIndex:indexPath.row];
            break;
        }
    }

    if (self.callerId == nil)
    {
        self.callerId = [NSEntityDescription insertNewObjectForEntityForName:@"CallerId"
                                                      inManagedObjectContext:self.managedObjectContext];
        self.callerId.contactId = self.contactId;
    }
    
    self.callerId.callable = callable;
    
    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

    if (self.navigationController.presentingViewController != nil)
    {
        [self dismissViewControllerAnimated:YES completion:^
        {
            self.completion ? self.completion(callable) : (void)0;
        }];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma Helpers

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)deleteAction
{
    [self.managedObjectContext deleteObject:self.callerId];
    
    self.completion ? self.completion(nil) : (void)0;
    
    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    
    // We can only get here pushed from a contact.
    [self.navigationController popViewControllerAnimated:YES];
}


- (void)showCallerIdSwitchAction:(UISwitch*)switchView
{
    if (switchView.on)
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
    else
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
        
        [self.tableView beginUpdates];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView endUpdates];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.333 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self.navigationController popViewControllerAnimated:YES];
        });
    }
    
    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
}


- (NSArray*)fetchPhones
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                     sortKeys:@[@"e164", @"name"]
                                                    predicate:nil
                                         managedObjectContext:self.managedObjectContext];
}


- (NSArray*)fetchNumbers
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                     sortKeys:@[@"e164", @"name"]
                                                    predicate:nil
                                         managedObjectContext:self.managedObjectContext];
}

@end
