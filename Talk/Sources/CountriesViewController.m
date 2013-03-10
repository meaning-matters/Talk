//
//  CountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 12/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CountriesViewController.h"
#import "SettingsViewController.h"
#import "CountryNames.h"
#import "Settings.h"
#import "NSObject+Blocks.h"


@interface CountriesViewController ()
{
    NSArray*                namesArray;
    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    BOOL                    isFiltered;
    UITableViewCell*        selectedCell;
}

@end


@implementation CountriesViewController

- (id)init
{
    if (self = [super initWithNibName:@"CountriesView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"Countries:CountriesList ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Countries",
                                                       @"Title of app screen with list of countries\n"
                                                       @"[1 line larger font].");

        namesArray = [[CountryNames sharedNames].namesDictionary allValues];
        nameIndexDictionary = [NSMutableDictionary dictionary];
        for (NSString* name in namesArray)
        {
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

        nameIndexArray = [[nameIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
        for (NSString* nameIndex in nameIndexArray)
        {
            nameIndexDictionary[nameIndex] = [nameIndexDictionary[nameIndex] sortedArrayUsingSelector:@selector(localizedCompare:)];
        }
    }

    return self;
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.isModal)
    {
        UIBarButtonItem*    cancelButton;

        cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                     target:self
                                                                     action:@selector(cancel)];
        self.navigationItem.rightBarButtonItem = cancelButton;
    }
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

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    [Settings sharedSettings].homeCountry = [[CountryNames sharedNames] isoCountryCodeForName:name];

    selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    selectedCell = cell;

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.isModal == YES)
    {
        // Shown as modal.
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        // Shown from Settings.
        // Set the parent cell to prevent quick update right after animations.
        NSArray*                viewControllers = self.navigationController.viewControllers;
        SettingsViewController* parent = (SettingsViewController*)viewControllers[[viewControllers count] - 2];
        NSIndexPath*            parentIndexPath = parent.tableView.indexPathForSelectedRow;
        UITableViewCell*        parentCell = [parent.tableView cellForRowAtIndexPath:parentIndexPath];
        parentCell.imageView.image = [UIImage imageNamed:[Settings sharedSettings].homeCountry];
        parentCell.textLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:[Settings sharedSettings].homeCountry];

        [self.navigationController popViewControllerAnimated:YES];
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
    cell.textLabel.text = name;

    if ([isoCountryCode isEqualToString:[Settings sharedSettings].homeCountry])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark - Search Bar & Controller Delegate

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
