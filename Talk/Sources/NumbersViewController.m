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
    NSMutableArray*         numbersArray;
    NSMutableArray*         filteredNumbersArray;
    BOOL                    isFiltered;
}

@end


@implementation NumbersViewController

- (instancetype)init
{
    if (self = [super initWithNibName:@"NumbersView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Numbers:NumbersList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Numbers",
                                                       @"Title of app screen with list of phone numbers\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"NumbersTab.png"];

        numbersArray          = [NSMutableArray array];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    [self fetchData];
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        // Add delays to allow uninterrupted animations of UIRefreshControl
        [Common dispatchAfterInterval:0.5 onMain:^
        {
            [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
            {
                [Common dispatchAfterInterval:0.1 onMain:^
                {
                    [sender endRefreshing];
                }];

                if (error == nil)
                {
                    error = [self fetchData];
                }
            }];
        }];
    }
    else
    {
        [Common dispatchAfterInterval:1.0 onMain:^
        {
            [sender endRefreshing];
        }];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
        [self updateCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath] atIndexPath:selectedIndexPath];

        NSError* error= nil;
        [[DataManager sharedManager].managedObjectContext save:&error];
        //### Handle error.
    }

    if (isFiltered == YES)
    {
        isFiltered = NO;
        [self.tableView reloadData];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Utility Methods

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


- (NSError*)fetchData
{
    NSFetchRequest* request         = [NSFetchRequest fetchRequestWithEntityName:@"Number"];
    NSArray*        sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"numberCountry" ascending:YES],
                                        [[NSSortDescriptor alloc] initWithKey:@"name"          ascending:YES]];
    [request setSortDescriptors:sortDescriptors];

    NSError*        error   = nil;
    NSMutableArray* results = [[[DataManager sharedManager].managedObjectContext executeFetchRequest:request
                                                                                               error:&error] mutableCopy];
    if (results != nil)
    {
        numbersArray = results;
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    }

    return error;
}


- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number;

    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    cell.imageView.image = [UIImage imageNamed:number.numberCountry];
    cell.textLabel.text  = number.name;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return isFiltered ? filteredNumbersArray.count : numbersArray.count;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number;
    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    NumberViewController* viewController;
    viewController = [[NumberViewController alloc] initWithNumber:number];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

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


#pragma mark - Search Bar Delegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController*)controller
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController*)controller
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        filteredNumbersArray = [NSMutableArray array];

        for (NumberData* number in numbersArray)
        {
            NSRange range = [number.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                [filteredNumbersArray addObject:number];
            }
        }
    }

    [self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    isFiltered = NO;
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

@end
