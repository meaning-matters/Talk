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
#import "AppDelegate.h"
#import "DataManager.h"
#import "Settings.h"
#import "NumberData.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "WebClient.h"
#import "Base64.h"
#import "Strings.h"


@interface NumbersViewController ()
{
    NSFetchedResultsController* fetchedNumbersController;
    UISegmentedControl*         sortSegmentedControl;
}

@end


@implementation NumbersViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.title                = [Strings numbersString]; // Not used, because we're having a segmented control.
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                         withSortKeys:[self sortKeys]
                                                                 managedObjectContext:self.managedObjectContext];
    fetchedNumbersController.delegate = self;

    NSString* byCountries = NSLocalizedStringWithDefaultValue(@"Numbers SortByCountries", nil,
                                                              [NSBundle mainBundle], @"Countries",
                                                              @"\n"
                                                              @"[1/4 line larger font].");
    NSString* byNames     = NSLocalizedStringWithDefaultValue(@"Numbers SortByNames", nil,
                                                              [NSBundle mainBundle], @"Names",
                                                              @"\n"
                                                              @"[1/4 line larger font].");
    sortSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[byCountries, byNames]];
    sortSegmentedControl.selectedSegmentIndex = [Settings sharedSettings].numbersSortSegment;
    [sortSegmentedControl addTarget:self
                             action:@selector(sortOrderChangedAction)
                   forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = sortSegmentedControl;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self configureCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath]
        onResultsController:fetchedNumbersController
                atIndexPath:selectedIndexPath];

        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


#pragma mark - Utility Methods

- (void)sortOrderChangedAction
{
    [Settings sharedSettings].numbersSortSegment = sortSegmentedControl.selectedSegmentIndex;

    [[DataManager sharedManager] setSortKeys:[self sortKeys] ofResultsController:fetchedNumbersController];
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
    return fetchedNumbersController.sections.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [fetchedNumbersController.sections[section] numberOfObjects];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"Numbers Number List Title", nil, [NSBundle mainBundle],
                                             @"You can be reached at",
                                             @"\n"
                                             @"[1/4 line larger font].");
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberData*           number         = [fetchedNumbersController objectAtIndexPath:indexPath];
    NumberViewController* viewController = [[NumberViewController alloc] initWithNumber:number];

    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self configureCell:cell
    onResultsController:fetchedNumbersController
            atIndexPath:indexPath];
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
    NumberData* number        = [fetchedNumbersController objectAtIndexPath:indexPath];
    cell.imageView.image      = [UIImage imageNamed:number.numberCountry];
    cell.textLabel.text       = number.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:number.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark - Helpers

- (NSArray*)sortKeys
{
    if ([Settings sharedSettings].numbersSortSegment == 0)
    {
        return @[@"numberCountry", @"name"];
    }
    else
    {
        return @[@"name", @"numberCountry"];
    }
}

@end
