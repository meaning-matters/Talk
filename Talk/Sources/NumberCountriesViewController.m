//
//  NumberCountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberCountriesViewController.h"
#import "NumberStatesViewController.h"
#import "CountryNames.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


@interface NumberCountriesViewController ()
{
    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSMutableArray*         countriesArray;
    BOOL                    isFiltered;
}

@end


@implementation NumberCountriesViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumberCountriesView" bundle:nil])
    {
        self.title = @"HelloWorld";

        countriesArray = [NSMutableArray array];
    }

    return self;
}


- (void)cancel
{
    [[WebClient sharedClient] cancelAllRetrieveNumberCountries];
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;

    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Loading ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Loading Countries...",
                                                                  @"Title of app screen with list of countries, "
                                                                  @"while loading.\n"
                                                                  @"[1 line larger font - abbreviated 'Loading...'].");

    [[WebClient sharedClient] retrieveNumberCountries:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberCountries:Done ScreenTitle", nil,
                                                                          [NSBundle mainBundle], @"Countries",
                                                                          @"Title of app screen with list of countries.\n"
                                                                          @"[1 line larger font - abbreviated 'Countries'].");

            // Combine number types per country.
            for (NSDictionary* newCountry in (NSArray*)content)
            {
                NSMutableDictionary*    matchedCountry = nil;
                for (NSMutableDictionary* country in countriesArray)
                {
                    if ([newCountry[@"isoCode"] isEqualToString:country[@"isoCode"]])
                    {
                        matchedCountry = country;
                        break;
                    }
                }

                if (matchedCountry == nil)
                {
                    NSMutableDictionary* country = [NSMutableDictionary dictionaryWithDictionary:newCountry];
                    country[[country[@"type"] lowercaseString]] = [NSNumber numberWithBool:YES];
                    [countriesArray addObject:country];
                }
                else
                {
                    matchedCountry[[newCountry[@"type"] lowercaseString]] = [NSNumber numberWithBool:YES];
                }
            }

            // Create indexes.
            nameIndexDictionary = [NSMutableDictionary dictionary];
            for (NSMutableDictionary* country in countriesArray)
            {
                NSString*       name = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCode"]];
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
        else if (status == WebClientStatusFailServiceUnavailable)
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Service Unavailable",
                                                      @"Alert title telling that loading countries over internet failed.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The service for buying numbers is temporarily offline."
                                                        @"\n\nPlease try again later.",
                                                        @"Alert message telling that loading countries over internet failed.\n"
                                                        @"[iOS alert message size - use correct iOS terms for: Settings "
                                                        @"and Notifications!]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:nil];
        }
        else
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Loading Failed",
                                                      @"Alert title telling that loading countries over internet failed.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of countries failed.\n\nPlease try again later.",
                                                        @"Alert message telling that loading countries over internet failed.\n"
                                                        @"[iOS alert message size - use correct iOS terms for: Settings "
                                                        @"and Notifications!]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[CommonStrings cancelString]
                                 otherButtonTitles:nil];
        }
    }];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    isFiltered = NO;
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];
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
        if ([country[@"isoCode"] isEqualToString:isoCountryCode])
        {
            break;
        }
    }

    if ([country[@"hasStates"] boolValue])
    {
        NumberStatesViewController* viewController;
        viewController = [[NumberStatesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                          countryId:[country[@"countryId"] intValue]];
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           name;
    NSString*           isoCountryCode;
    NSDictionary*       country;

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

    // Look up country.
    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    for (country in countriesArray)
    {
        if ([country[@"isoCode"] isEqualToString:isoCountryCode])
        {
            break;
        }
    }

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text = name;
    cell.accessoryType = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Search Bar & Controller Delegate

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    [self.navigationController setNavigationBarHidden:YES animated:YES];
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

    [self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    isFiltered = NO;
    [self.tableView reloadData];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

@end
