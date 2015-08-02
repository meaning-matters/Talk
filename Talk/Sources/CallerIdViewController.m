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
#import "CallableData.h"
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
@property (nonatomic, strong) CallableData*           selectedCallable;
@property (nonatomic, copy) void (^completion)(CallableData* selectedCallable);
@property (nonatomic, strong) NSArray*                phones;
@property (nonatomic, strong) NSArray*                numbers;

@end


@implementation CallerIdViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            selectedCallable:(CallableData*)selectedCallable
                                  completion:(void (^)(CallableData*  selectedCallable))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title                = [Strings callerIdString];
        self.managedObjectContext = managedObjectContext;
        self.selectedCallable     = selectedCallable;
        self.completion           = completion;

        self.phones               = [self fetchPhones];
        self.numbers              = [self fetchNumbers];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.navigationController.presentingViewController != nil)
    {
        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                   target:self
                                                                   action:@selector(cancel)];
        self.navigationItem.leftBarButtonItem = buttonItem;
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
            title = [Strings phonesString];
            break;
        }
        case TableSectionNumbers:
        {
            title = [Strings numbersString];
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
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"....",
                                                      @"...\n"
                                                      @"[* lines]");
            break;
        }
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Numbers SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"....",
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

    [self dismissViewControllerAnimated:YES completion:^
    {
        self.completion(callable);
    }];
}


#pragma Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSArray*)fetchPhones
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                     sortKeys:@[@"name"]
                                                    predicate:nil
                                         managedObjectContext:nil];
}


- (NSArray*)fetchNumbers
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                     sortKeys:@[@"name"]
                                                    predicate:nil
                                         managedObjectContext:nil];
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

    if (callable == self.selectedCallable)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
