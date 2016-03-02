//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "NumbersViewController.h"
#import "NumberCountriesViewController.h"
#import "NumberViewController.h"
#import "AddressesViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "Settings.h"
#import "NumberData.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "WebClient.h"
#import "Base64.h"
#import "Strings.h"
#import "Common.h"

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionNumbers   = 1UL << 0,
    TableSectionAddresses = 1UL << 1,
};


@interface NumbersViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedNumbersController;
@property (nonatomic, assign) TableSections               sections;

@end


@implementation NumbersViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.title                = [Strings numbersString]; // Not used, because we're having a segmented control.
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
        
        self.sections |= TableSectionNumbers;
        self.sections |= TableSectionAddresses;
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

    self.clearsSelectionOnViewWillAppear = YES;

    self.fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                              withSortKeys:[Common sortKeys]
                                                                      managedObjectContext:self.managedObjectContext];
    self.fetchedNumbersController.delegate = self;
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self configureCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath]
        onResultsController:self.fetchedNumbersController
                atIndexPath:selectedIndexPath];

        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    }
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [[DataManager sharedManager] setSortKeys:[Common sortKeys] ofResultsController:self.fetchedNumbersController];
    [self.tableView reloadData];
}


// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*        modalViewController;
        NumberCountriesViewController* numberCountriesViewController;

        numberCountriesViewController = [[NumberCountriesViewController alloc] init];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:numberCountriesViewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showGetStartedViewController];
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedNumbersController.sections.count + 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumbers:   numberOfRows = [self.fetchedNumbersController.sections[section] numberOfObjects]; break;
        case TableSectionAddresses: numberOfRows = 1;                                                                 break;
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            title = NSLocalizedStringWithDefaultValue(@"Numbers Number List Title", nil, [NSBundle mainBundle],
                                                      @"You Can Be Reached At",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
            break;
        }
        case TableSectionAddresses:
        {
            title = NSLocalizedStringWithDefaultValue(@"Numbers Addresses Title", nil, [NSBundle mainBundle],
                                                      @"Your Registered Addresses",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
            break;
        }
    }
    
    return title;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UIViewController* viewController;
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            NumberData* number = [self.fetchedNumbersController objectAtIndexPath:indexPath];
            viewController     = [[NumberViewController alloc] initWithNumber:number
                                                         managedObjectContext:self.managedObjectContext];
            break;
        }
        case TableSectionAddresses:
        {
            viewController = [[AddressesViewController alloc] init];
            break;
        }
    }

    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
            }

            break;
        }
        case TableSectionAddresses:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddressesCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AddressesCell"];
            }

            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [Strings addressesString];

            [Common setImageNamed:@"AddressesTab" ofCell:cell];
            break;
        }
     }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            [self configureCell:cell onResultsController:self.fetchedNumbersController atIndexPath:indexPath];
            break;
        }
        case TableSectionAddresses:
        {
            break;
        }
    }
}


#pragma mark - Override of ItemsViewController.

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    if ([Common nthBitSet:indexPath.section inValue:self.sections] == TableSectionNumbers)
    {
        NumberData* number        = [self.fetchedNumbersController objectAtIndexPath:indexPath];
        cell.imageView.image      = [UIImage imageNamed:number.isoCountryCode];
        cell.textLabel.text       = number.name;
        PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:number.e164];
        cell.detailTextLabel.text = [phoneNumber internationalFormat];
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    }
}

@end
