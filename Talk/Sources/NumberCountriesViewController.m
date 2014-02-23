//
//  NumberCountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberCountriesViewController.h"
#import "NumberStatesViewController.h"
#import "NumberAreasViewController.h"
#import "CountryNames.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "NumberType.h"
#import "Common.h"
#import "Settings.h"


@interface NumberCountriesViewController ()
{
    NSArray*             nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary* nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*      filteredNamesArray;

    NSMutableArray*      allCountriesArray;
    NSMutableArray*      countriesArray;
    BOOL                 isFiltered;
}

@property (nonatomic, strong) UISegmentedControl*        numberTypeSegmentedControl;
@property (nonatomic, strong) UISearchBar*               searchBar;
@property (nonatomic, strong) UISearchDisplayController* contactSearchDisplayController;

@end


@implementation NumberCountriesViewController


- (instancetype)init
{
    if (self = [super initWithNibName:@"NumberCountriesView" bundle:nil])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;

        allCountriesArray = [NSMutableArray array];
        countriesArray    = [NSMutableArray array];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.navigationItem.title = [Strings loadingString];
    [[WebClient sharedClient] retrieveNumberCountries:^(NSError* error, id content)
    {
        if (error == nil)
        {
            self.navigationItem.title = [Strings countriesString];

            // Added number type selector.
            NSArray* items = @[[NumberType localizedStringForNumberType:1UL << 0],
                               [NumberType localizedStringForNumberType:1UL << 1],
                               [NumberType localizedStringForNumberType:1UL << 2]];
            self.numberTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:items];
            [self.numberTypeSegmentedControl addTarget:self
                                                action:@selector(numberTypeChangedAction:)
                                      forControlEvents:UIControlEventValueChanged];
            self.navigationItem.titleView = self.numberTypeSegmentedControl;

            NSInteger   index = [NumberType numberTypeMaskToIndex:[Settings sharedSettings].numberTypeMask];
            [self.numberTypeSegmentedControl setSelectedSegmentIndex:index];

            // Combine numberTypes per country.
            for (NSDictionary* newCountry in (NSArray*)content)
            {
                NSMutableDictionary*    matchedCountry = nil;
                for (NSMutableDictionary* country in allCountriesArray)
                {
                    if ([newCountry[@"isoCountryCode"] isEqualToString:country[@"isoCountryCode"]])
                    {
                        matchedCountry = country;
                        break;
                    }
                }

                if (matchedCountry == nil)
                {
                    matchedCountry = [NSMutableDictionary dictionaryWithDictionary:newCountry];
                    matchedCountry[@"numberTypes"] = @(0);
                    [allCountriesArray addObject:matchedCountry];
                }

                NumberTypeMask mask = [NumberType numberTypeMaskForString:newCountry[@"numberType"]];
                matchedCountry[@"numberTypes"] = @([matchedCountry[@"numberTypes"] intValue] | mask);
            }

            [self sortOutArrays];
        }
        else if (error.code == WebClientStatusFailServiceUnavailable)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Service Unavailable",
                                                        @"Alert title telling that loading countries over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The service for buying numbers is temporarily offline."
                                                        @"\n\nPlease try again later.",
                                                        @"Alert message telling that loading countries over internet failed.\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Failed",
                                                        @"Alert title telling that loading countries over internet failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of countries failed: %@\n\nPlease try again later.",
                                                        @"Alert message telling that loading countries over internet failed.\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }
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

    //  [self.navigationController setNavigationBarHidden:NO animated:YES];
    //[self.searchDisplayController setActive:NO animated:YES];

    [[WebClient sharedClient] cancelAllRetrieveNumberCountries];
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    // Select from all on numberType.
    [countriesArray removeAllObjects];
    NumberTypeMask  numberTypeMask = 1UL << [self.numberTypeSegmentedControl selectedSegmentIndex];
    for (NSMutableDictionary* country in allCountriesArray)
    {
        if ([country[@"numberTypes"] intValue] & numberTypeMask)
        {
            [countriesArray addObject:country];
        }
    }

    // Create indexes.
    nameIndexDictionary = [NSMutableDictionary dictionary];
    for (NSMutableDictionary* country in countriesArray)
    {
        NSString*       name = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
        NSString*       nameIndex = [name substringToIndex:1];
        NSMutableArray* indexArray;
        if ((indexArray = [nameIndexDictionary valueForKey:nameIndex]) != nil)
        {
            [indexArray addObject:name];
        }
        else
        {
            indexArray = [NSMutableArray array];
            nameIndexDictionary[nameIndex] = indexArray;
            [indexArray addObject:name];
        }
    }

    // Sort indexes.
    nameIndexArray = [[nameIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
    for (NSString* nameIndex in nameIndexArray)
    {
        nameIndexDictionary[nameIndex] = [nameIndexDictionary[nameIndex] sortedArrayUsingSelector:@selector(localizedCompare:)];
    }

    [self.tableView reloadData];
    if (isFiltered)
    {
        [self searchBar:self.searchDisplayController.searchBar
          textDidChange:self.searchDisplayController.searchBar.text];

        [self.searchDisplayController.searchResultsTableView reloadData];
    }
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return isFiltered ? 1 : [nameIndexArray count];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return isFiltered ? nil : nameIndexArray[section];
}


- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
    return isFiltered ? nil : nameIndexArray;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return isFiltered ? filteredNamesArray.count : [nameIndexDictionary[nameIndexArray[section]] count];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*           name;
    NSString*           isoCountryCode;
    NSDictionary*       country;

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    // Look up country.
    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    for (country in countriesArray)
    {
        if ([country[@"isoCountryCode"] isEqualToString:isoCountryCode])
        {
            break;
        }
    }

    NumberTypeMask  numberTypeMask = 1UL << self.numberTypeSegmentedControl.selectedSegmentIndex;
    if ([country[@"hasStates"] boolValue] && numberTypeMask == NumberTypeGeographicMask)
    {
        NumberStatesViewController* viewController;
        viewController = [[NumberStatesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                     numberTypeMask:numberTypeMask];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        NumberAreasViewController*  viewController;
        viewController = [[NumberAreasViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                        state:nil
                                                                numberTypeMask:numberTypeMask];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           name;
    NSString*           isoCountryCode;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
 
    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;
    cell.accessoryType   = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Content Filtering

- (void)filterContentForSearchText:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        filteredNamesArray = [NSMutableArray array];

        for (NSString* nameIndex in nameIndexArray)
        {
            for (NSString* countryName in nameIndexDictionary[nameIndex])
            {
                NSRange range = [countryName rangeOfString:searchText options:NSCaseInsensitiveSearch];
                if (range.location != NSNotFound)
                {
                    [filteredNamesArray addObject:countryName];
                }
            }
        }
    }
}


#pragma mark - UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
    [self filterContentForSearchText:searchString];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


#pragma mark - UI Actions

- (void)numberTypeChangedAction:(id)sender
{
    [Settings sharedSettings].numberTypeMask = 1UL << self.numberTypeSegmentedControl.selectedSegmentIndex;
    [self sortOutArrays];
}

@end
