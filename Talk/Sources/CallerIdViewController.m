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
    TableSectionPhones  = 1UL << 0,
    TableSectionNumbers = 1UL << 1,
} TableSections;


@interface CallerIdViewController ()
{
    TableSections sections;
}

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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return (self.phones.count > 0) + (self.numbers.count > 0);
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:  return self.phones.count;
        case TableSectionNumbers: return self.numbers.count;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([self tableSectionForSection:section])
    {
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
    NSString* title = nil;

    switch ([self tableSectionForSection:section])
    {
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

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    CallableData* callable = nil;
    
    switch ([self tableSectionForSection:indexPath.section])
    {
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
        if (callable != self.selectedCallable)
        {
            self.completion ? self.completion(callable) : (void)0;
        }
        
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
    self.callerId.callable = nil;

    [self.managedObjectContext deleteObject:self.callerId];
    
    self.completion ? self.completion(nil) : (void)0;
    
    // We can only get here pushed from a contact.
    [self.navigationController popViewControllerAnimated:YES];
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


- (TableSections)tableSectionForSection:(NSInteger)section
{
    if (self.phones.count == 0)
    {
        return TableSectionNumbers;
    }
    else
    {
        return (TableSections)[Common nthBitSet:section inValue:sections];
    }
}


- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    CallableData* callable;
    switch ([self tableSectionForSection:indexPath.section])
    {
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
}

@end
