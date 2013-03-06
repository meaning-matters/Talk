//
//  NumberCountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberCountriesViewController.h"
#import "CountryNames.h"
#import "WebClient.h"

@interface NumberCountriesViewController ()
{
    NSArray*        countriesArray;
    NSMutableArray* filteredCountriesArray;
    BOOL            isFiltered;
}

@end


@implementation NumberCountriesViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumberCountriesView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Countries:CountriesList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Countries",
                                                       @"Title of app screen with list of countries\n"
                                                       @"[1 line larger font].");
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [[WebClient sharedClient] retrieveNumberCountries:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            countriesArray = (NSArray*)content;
            [self.tableView reloadData];
        }
        else
        {
            NSLog(@"####");
        }
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return isFiltered ? filteredCountriesArray.count : countriesArray.count;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell = [self.tableView cellForRowAtIndexPath:indexPath];
    NSDictionary*       country;

    if (isFiltered)
    {
        country = filteredCountriesArray[indexPath.row];
    }
    else
    {
        country = countriesArray[indexPath.row];
    }

    //### push next level.
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSDictionary*       country;
    NSString*           isoCountryCode;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (isFiltered)
    {
        country = filteredCountriesArray[indexPath.row];
    }
    else
    {
        country = countriesArray[indexPath.row];
    }

    isoCountryCode = country[@"isoCode"];

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


#pragma mark - Search Bar Delegate

- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
    if (searchText.length == 0)
    {
        isFiltered = NO;
    }
    else
    {
        isFiltered = YES;
        filteredCountriesArray = [NSMutableArray array];

        for (NSDictionary* country in countriesArray)
        {
            NSString*   countryName = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCode"]];
            NSRange     range = [countryName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                [filteredCountriesArray addObject:country];
            }
        }
    }

    [self.tableView reloadData];
}


- (void)searchBarSearchButtonClicked:(UISearchBar*)searchBar
{
    [self done];
}


- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    isFiltered = NO;
    self.searchBar.text = @"";
    [self.tableView reloadData];

    [self enableCancelButton:NO];

    [searchBar performSelector:@selector(resignFirstResponder)
                    withObject:nil
                    afterDelay:0.1];
}


#pragma mark - Scrollview Delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)activeScrollView
{
    [self done];
}


#pragma mark - Utility Methods

- (void)done
{
    if ([self.searchBar isFirstResponder])
    {
        [self.searchBar resignFirstResponder];

        [self enableCancelButton:[self.searchBar.text length] > 0];
    }
}


- (void)enableCancelButton:(BOOL)enabled
{
    // Enable search-bar cancel button.
    for (UIView* possibleButton in self.searchBar.subviews)
    {
        if ([possibleButton isKindOfClass:[UIButton class]])
        {
            ((UIButton*)possibleButton).enabled = enabled;
            break;
        }
    }
}


#pragma mark - Actions

- (IBAction)cancelAction:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
