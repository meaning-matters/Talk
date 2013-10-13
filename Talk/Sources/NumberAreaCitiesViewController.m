//
//  NumberAreaCitiesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaCitiesViewController.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface NumberAreaCitiesViewController ()
{
    NSArray*                nameIndexArray;         // Array with all first letters of city names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSArray*                citiesArray;
    BOOL                    isFiltered;

    NSMutableDictionary*    purchaseInfo;

    UITableViewCell*        checkmarkedCell;        // Previous cell with checkmark.
}

@end


@implementation NumberAreaCitiesViewController

- (instancetype)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info;
{
    if (self = [super initWithNibName:@"NumberAreaCitiesView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaCities ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Cities",
                                                       @"Title of app screen with list of cities\n"
                                                       @"[1 line larger font].");

        citiesArray  = array;
        purchaseInfo = info;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    [self sortOutArrays];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    // Create indexes.
    int size = (citiesArray.count > 8); // Don't show index with 8 or less items.
    nameIndexDictionary = [NSMutableDictionary dictionary];
    for (NSMutableDictionary* city in citiesArray)
    {
        NSString*       name = city[@"city"];
        NSString*       nameIndex = [name substringToIndex:size];
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

    // If a ZIP code is already selected, check if it matches the city.
    NSString*   mismatchZipCode = purchaseInfo[@"zipCode"];
    if (purchaseInfo[@"zipCode"] != nil)
    {
        for (NSDictionary* city in citiesArray)
        {
            if ([name isEqualToString:city[@"city"]])
            {
                // Found selected city, now check if current ZIP code belongs.
                for (NSString* zipCode in city[@"zipCodes"])
                {
                    if ([purchaseInfo[@"zipCode"] isEqualToString:zipCode])
                    {
                        // Yes, the selected city matches the current ZIP code, so no problem.
                        mismatchZipCode = nil;
                        break;
                    }
                }
            }
        }
    }

    if (mismatchZipCode.length == 0)
    {
        if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        purchaseInfo[@"city"] = name;

        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreaCities ZipMismatchAlertTitle", nil,
                                                  [NSBundle mainBundle], @"ZIP Code Mismatch",
                                                  @"Alert title saying that ZIP code does not match.\n"
                                                  @"[iOS alert title size - use correct term for 'ZIP code'].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreaCities ZipMismatchAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The current ZIP code: %@, does not match the city "
                                                    @"you selected.\nYou will have to select a ZIP code again.",
                                                    @"Alert message telling saying that ZIP code does not match.\n"
                                                    @"[iOS alert message size - use correct term for 'ZIP code']");
        message = [NSString stringWithFormat:message, mismatchZipCode];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             if (buttonIndex == 1)
             {
                 if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
                 {
                     checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
                 }

                 cell.accessoryType = UITableViewCellAccessoryCheckmark;

                 [purchaseInfo removeObjectForKey:@"zipCode"];
                 purchaseInfo[@"city"] = name;

                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
             }
         }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings okString], nil];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           name;

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

    cell.textLabel.text = name;
    if ([name isEqualToString:purchaseInfo[@"city"]])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        checkmarkedCell = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


#pragma mark - Search Bar & Controller Delegate

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
