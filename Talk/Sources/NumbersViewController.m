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


@interface NumbersViewController ()
{
    NSMutableArray*         numbersArray;
    NSMutableArray*         filteredNumbersArray;
    BOOL                    isFiltered;

    NSManagedObjectContext* managedObjectContext;
    NSDateFormatter*        dateFormatter;
}

@end


@implementation NumbersViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumbersView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Numbers:NumbersList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Numbers",
                                                       @"Title of app screen with list of phone numbers\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"NumbersTab.png"];

        numbersArray         = [NSMutableArray array];
        managedObjectContext = [DataManager sharedManager].managedObjectContext;
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];

#warning //### Remove this later.
        if ([Settings sharedSettings].runBefore == NO)
        {
            NumberData* numberData = (NumberData*)[NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                                                                inManagedObjectContext:managedObjectContext];
            numberData.name             = @"Business Mobile";
            numberData.e164             = @"+32499298238";
            numberData.areaCode         = @"499";
            numberData.isoCountryCode   = @"BE";
            numberData.purchaseDateTime = [NSDate date];
            numberData.renewalDateTime  = [NSDate date];
            numberData.salutation       = @"Mr.";
            numberData.firstName        = @"Cornelis";
            numberData.lastName         = @"van der Bent";
            numberData.company          = @"NumberBay";
            numberData.street           = @"Craenendonck";
            numberData.building         = @"12";
            numberData.city             = @"Leuven";
            numberData.zipCode          = @"3000";

            NSError*    error = nil;
            if ([managedObjectContext save:&error] == NO)
            {
                //### Handle error in better way.
                [BlockAlertView showAlertViewWithTitle:@"Saving Number Failed"
                                               message:nil
                                            completion:nil
                                     cancelButtonTitle:@"Close"
                                     otherButtonTitles:nil];
            }
        }
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    [self fetchData];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    isFiltered = NO;
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


#pragma mark - Utility Methods

- (void)addAction
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


- (void)fetchData
{
    NSFetchRequest*         request = [[NSFetchRequest alloc] init];
    NSEntityDescription*    entity = [NSEntityDescription entityForName:@"Number"
                                                 inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];

    NSArray*    sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"isoCountryCode" ascending:NO] ];
    [request setSortDescriptors:sortDescriptors];

    NSError*        error = nil;
    NSMutableArray* results = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (results == nil)
    {
        // Handle the error.
    }
    else
    {
        numbersArray = results;
    }
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
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NumberData*         number;

    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    NumberViewController*   viewController;
    viewController = [[NumberViewController alloc] initWithNumber:number];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NumberData*         number;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (isFiltered)
    {
        number = filteredNumbersArray[indexPath.row];
    }
    else
    {
        number = numbersArray[indexPath.row];
    }

    cell.imageView.image = [UIImage imageNamed:number.isoCountryCode];
    cell.textLabel.text  = number.name;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


#pragma mark - Search Bar Delegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}


- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
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
