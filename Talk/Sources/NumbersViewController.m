//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
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
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.title            = [Strings numbersString]; // Not used, because we're having a segmented control.
        self.tabBarItem.image = [UIImage imageNamed:@"NumbersTab.png"];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    NSError* error;
    fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                         withSortKeys:[self sortKeys]
                                                                                error:&error];
    if (fetchedNumbersController != nil)
    {
        fetchedNumbersController.delegate = self;
    }
    else
    {
        NSLog(@"//### Error: %@", error.localizedDescription);
    }


    NSString*           byCountries = NSLocalizedStringWithDefaultValue(@"Numbers SortByCountries", nil,
                                                                        [NSBundle mainBundle], @"Countries",
                                                                        @"\n"
                                                                        @"[1/4 line larger font].");
    NSString*           byNames     = NSLocalizedStringWithDefaultValue(@"Numbers SortByNames", nil,
                                                                        [NSBundle mainBundle], @"Names",
                                                                        @"\n"
                                                                        @"[1/4 line larger font].");
    sortSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[byCountries, byNames]];
    sortSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    sortSegmentedControl.selectedSegmentIndex  = [Settings sharedSettings].numbersSortSegment;
    [sortSegmentedControl addTarget:self
                             action:@selector(sortOrderChangedAction)
                   forControlEvents:UIControlEventValueChanged];

    self.navigationItem.titleView = sortSegmentedControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
        {
            [sender endRefreshing];

            if (error == nil)
            {
                //### Need some fetch data here like in NumbersVC?
            }
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self updateCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath] atIndexPath:selectedIndexPath];

        NSError* error= nil;
        [[DataManager sharedManager].managedObjectContext save:&error];
        //### Handle error.
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Utility Methods

- (void)sortOrderChangedAction
{
    [Settings sharedSettings].numbersSortSegment = sortSegmentedControl.selectedSegmentIndex;

    NSError* error;
    if ([[DataManager sharedManager] setSortKeys:[self sortKeys]
                             ofResultsController:fetchedNumbersController
                                           error:&error] == NO)
    {
        //#### Handle error.
    }

    //#### setSortKeys fetches, so not needed: [self fetchData];
}


- (void)addAction
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        UINavigationController*         modalViewController;
        NumberCountriesViewController*  numberCountriesViewController;

        numberCountriesViewController = [[NumberCountriesViewController alloc] init];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:numberCountriesViewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showProvisioningViewController];
    }
}


- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number   = [fetchedNumbersController objectAtIndexPath:indexPath];
    cell.imageView.image = [UIImage imageNamed:number.numberCountry];
    cell.textLabel.text  = number.name;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
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
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self updateCell:cell atIndexPath:indexPath];
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
