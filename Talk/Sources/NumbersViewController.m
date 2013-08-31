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


@interface NumbersViewController ()
{
    NSMutableArray*         numbersArray;
    NSMutableArray*         filteredNumbersArray;
    BOOL                    isFiltered;

    NSManagedObjectContext* managedObjectContext;
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

        numbersArray          = [NSMutableArray array];
        managedObjectContext  = [DataManager sharedManager].managedObjectContext;
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
    [refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    [self fetchData];
}


- (void)handleRefresh:(id)sender
{
    [self downloadNumbers:^(BOOL success)
    {
        [sender endRefreshing];
        [self fetchData];
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

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
    if ([Settings sharedSettings].hasAccount == YES)
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


- (void)fetchData
{
    NSFetchRequest*         request = [[NSFetchRequest alloc] init];
    NSEntityDescription*    entity  = [NSEntityDescription entityForName:@"Number"
                                                  inManagedObjectContext:managedObjectContext];
    [request setEntity:entity];

    NSArray*    sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"numberCountry" ascending:YES],
                                     [[NSSortDescriptor alloc] initWithKey:@"name"          ascending:YES] ];
    [request setSortDescriptors:sortDescriptors];

    NSError*        error   = nil;
    NSMutableArray* results = [[managedObjectContext executeFetchRequest:request error:&error] mutableCopy];
    if (results != nil)
    {
        numbersArray = results;
        [self.tableView reloadData];
    }
    else
    {
        //### Handle the error.
    }
}


- (void)downloadNumbers:(void (^)(BOOL success))completion
{
    [[WebClient sharedClient] retrieveNumbers:^(WebClientStatus status, NSArray* array)
    {
        if (status == WebClientStatusOk)
        {
            __block int  count   = array.count;
            __block BOOL success = YES;
            for (NSString* e164 in array)
            {
                [[WebClient sharedClient] retrieveNumberForE164:e164
                                                   currencyCode:[Settings sharedSettings].currencyCode
                                                          reply:^(WebClientStatus status, NSDictionary* dictionary)
                {                    
                    if (status == WebClientStatusOk)
                    {
                        NSFetchRequest* request = [[NSFetchRequest alloc] init];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"e164 == %@", dictionary[@"e164"]]];
                        [request setEntity:[NSEntityDescription entityForName:@"Number"
                                                       inManagedObjectContext:managedObjectContext]];

                        NSError* error = nil;
                        NumberData* number = [[managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        if (number == nil)
                        {
                            number = (NumberData*)[NSEntityDescription insertNewObjectForEntityForName:@"Number"
                                                                                inManagedObjectContext:managedObjectContext];
                        }

                        number.name           = dictionary[@"name"];
                        number.e164           = dictionary[@"e164"];
                        number.areaCode       = dictionary[@"areaCode"];
                        number.areaName       = dictionary[@"areaName"];
                        number.numberCountry  = dictionary[@"isoCountryCode"];
                        [number setPurchaseDateWithString:dictionary[@"purchaseDateTime"]];
                        [number setRenewalDateWithString:dictionary[@"renewalDateTime"]];
                        number.salutation     = dictionary[@"info"][@"salutation"];
                        number.firstName      = dictionary[@"info"][@"firstName"];
                        number.lastName       = dictionary[@"info"][@"lastName"];
                        number.company        = dictionary[@"info"][@"company"];
                        number.street         = dictionary[@"info"][@"street"];
                        number.building       = dictionary[@"info"][@"building"];
                        number.city           = dictionary[@"info"][@"city"];
                        number.zipCode        = dictionary[@"info"][@"zipCode"];
                        number.stateName      = dictionary[@"info"][@"stateName"];
                        number.stateCode      = dictionary[@"info"][@"stateCode"];
                        number.addressCountry = dictionary[@"info"][@"isoCountryCode"];
                        number.proofImage     = [Base64 decode:dictionary[@"info"][@"proofImage"]];

                        [managedObjectContext save:&error];
                    }
                    else
                    {
                        success = NO;
                    }

                    if (--count == 0)
                    {
                        completion(success);
                    }
                }];
            }
        }
        else
        {
            completion(NO);
        }
    }];
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

    cell.imageView.image = [UIImage imageNamed:number.numberCountry];
    cell.textLabel.text  = number.name;
    cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
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
