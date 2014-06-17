//
//  SelectCallerIdViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

//http://stackoverflow.com/questions/8997387/tableview-with-two-instances-of-nsfetchedresultscontroller

#import "SelectCallerIdViewController.h"
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


@interface SelectCallerIdViewController () <NSFetchedResultsControllerDelegate>
{
    TableSections               sections;
    NSFetchedResultsController* fetchedE164Controller;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) PhoneData*              selectedPhone;
@property (nonatomic, strong) NumberData*             selectedNumber;
@property (nonatomic, copy) void (^completion)(PhoneData* selectedPhone, NumberData* selectedNumber);

@end


@implementation SelectCallerIdViewController

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
        self.title                = [Strings phonesString];
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

    fetchedE164Controller = [[DataManager sharedManager] fetchResultsForEntityName:@"E164"
                                                                      withSortKeys:@[@"name"]
                                                              managedObjectContext:self.managedObjectContext];
    fetchedE164Controller.delegate = self;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return fetchedE164Controller.sections.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray* array;

    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:
            array  = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                               sortKeys:@[@"name"]
                                                              predicate:nil
                                                   managedObjectContext:nil];
            break;

        case TableSectionNumbers:
            array  = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                               sortKeys:@[@"name"]
                                                              predicate:nil
                                                   managedObjectContext:nil];
            break;
    }

    return array.count;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([self tableSectionForSection:section])
    {
        case TableSectionPhones:
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Phones SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Phones",
                                                      @".....");
            break;

        case TableSectionNumbers:
            title = NSLocalizedStringWithDefaultValue(@"SelectCallerId:Numbers SectionHeader", nil,
                                                      [NSBundle mainBundle], @"Numbers",
                                                      @".....");
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

- (TableSections)tableSectionForSection:(NSInteger)section
{
    // When there are no Phones, the first section is Numbers.
    //return [Common nthBitSet:(section + (fetchedPhonesController.sections.count == 0)) inValue:sections];

    return 0;
}


- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    PhoneData* phone          = [fetchedE164Controller objectAtIndexPath:indexPath];
    cell.textLabel.text       = phone.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:phone.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.imageView.image      = [UIImage imageNamed:[phoneNumber isoCountryCode]];

    if (self.completion == nil)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (phone == self.selectedPhone)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
