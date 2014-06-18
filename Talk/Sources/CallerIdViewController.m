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
#import "E164Data.h"
#import "PhoneData.h"
#import "NumberData.h"

typedef enum
{
    TableSectionPhones  = 1UL << 0,
    TableSectionNumbers = 1UL << 1,
} TableSections;


@interface CallerIdViewController () <NSFetchedResultsControllerDelegate>
{
    TableSections               sections;
    NSFetchedResultsController* fetchedE164Controller;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSMutableArray*         phones;
@property (nonatomic, strong) NSMutableArray*         numbers;
@property (nonatomic, strong) PhoneData*              selectedPhone;
@property (nonatomic, strong) NumberData*             selectedNumber;
@property (nonatomic, copy) void (^completion)(PhoneData* selectedPhone, NumberData* selectedNumber);

@end


@implementation CallerIdViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                                selectedPhone:nil
                               selectedNumber:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                               selectedPhone:(PhoneData*)selectedPhone
                              selectedNumber:(NumberData*)selectedNumber
                                  completion:(void (^)(PhoneData*  selectedPhone,
                                                       NumberData* selectedNumber))completion;
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title                = [Strings callerIdString];
        self.managedObjectContext = managedObjectContext;
        self.selectedPhone        = selectedPhone;
        self.selectedNumber       = selectedNumber;
        self.completion           = completion;
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

    fetchedE164Controller = [[DataManager sharedManager] fetchResultsForEntityName:@"E164"
                                                                      withSortKeys:@[@"name"]
                                                              managedObjectContext:self.managedObjectContext];
    fetchedE164Controller.delegate = self;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return ([self phones].count > 0) + ([self numbers].count > 0);
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:  return [self phones].count;
        case TableSectionNumbers: return [self numbers].count;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:
            title = [Strings phonesString];
            break;

        case TableSectionNumbers:
            title = [Strings numbersString];
            break;
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"....",
                                                      @"...\n"
                                                      @"[* lines]");
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Numbers SectionFooter", nil,
                                                      [NSBundle mainBundle],
                                                      @"....",
                                                      @"...\n"
                                                      @"[* lines]");
            break;
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
    self.completion(nil, nil);

    [self dismissViewControllerAnimated:YES completion:nil];

    /*    PhoneData*  phone  = [fetchedPhonesController  objectAtIndexPath:indexPath];
    NumberData* number = [fetchedNumbersController objectAtIndexPath:indexPath];

    switch ([self tableSectionForSection:indexPath.section])
    {
        case TableSectionPhones:
            
            break;

        case TableSectionNumbers:
            break;
    }

        if (phone != self.selectedPhone)
        {
            //   self.completion(phone);
        }

        [self.navigationController popViewControllerAnimated:YES];
     */
}


#pragma Helpers

- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSArray*)phones
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                     sortKeys:@[@"name"]
                                                    predicate:nil
                                         managedObjectContext:nil];
}


- (NSArray*)numbers
{
    return [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                     sortKeys:@[@"name"]
                                                    predicate:nil
                                         managedObjectContext:nil];
}


- (TableSections)tableSectionForSection:(NSInteger)section
{
    if ([self phones].count == 0)
    {
        return TableSectionNumbers;
    }
    else
    {
        return [Common nthBitSet:section inValue:sections];
    }
}


- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    E164Data* e164            = [fetchedE164Controller objectAtIndexPath:indexPath];
    cell.textLabel.text       = e164.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:e164.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.imageView.image      = [UIImage imageNamed:[phoneNumber isoCountryCode]];

    if (e164 == (E164Data*)self.selectedPhone || e164 == (E164Data*)self.selectedNumber)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
