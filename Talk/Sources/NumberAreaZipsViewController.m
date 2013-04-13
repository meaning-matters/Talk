//
//  NumberAreaZipsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaZipsViewController.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


@interface NumberAreaZipsViewController ()
{
    NSArray*                nameIndexArray;         // Array with all first letters of zipCodes.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSArray*                citiesArray;
    BOOL                    isFiltered;

    NSMutableDictionary*    purchaseInfo;

    UITableViewCell*        checkmarkedCell;        // Previous cell with checkmark.
}

@end


@implementation NumberAreaZipsViewController

- (id)initWithCitiesArray:(NSArray*)array purchaseInfo:(NSMutableDictionary*)info
{
    if (self = [super initWithNibName:@"NumberAreaZipsView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"NumbersAreaZips ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"ZIP Codes",
                                                       @"Title of app screen with list of postal codes\n"
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


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    NSMutableArray* zipCodesArray = [NSMutableArray array];
    nameIndexDictionary           = [NSMutableDictionary dictionary];

    // Create one big ZIP codes array.
    for (NSMutableDictionary* city in citiesArray)
    {
        [zipCodesArray addObjectsFromArray:city[@"zipCodes"]];
    }

    // Find maximum ZIP code size.
    int maximumSize = 0;
    for (NSString* zipCode in zipCodesArray)
    {
        if (zipCode.length > maximumSize)
        {
            maximumSize = zipCode.length;
        }
    }

    // Determine a good size of section title, such that number of sections is
    // smaller than 40, and the number of sections is smaller than the total
    // number of items devided by a minumum section size of for example 5.
    int size;
    for (size = maximumSize; size > 0; size--)
    {
        for (NSString* zipCode in zipCodesArray)
        {
            NSString*       nameIndex = [zipCode substringToIndex:size];
            if (([nameIndexDictionary valueForKey:nameIndex]) == nil)
            {
                nameIndexDictionary[nameIndex] = nameIndex;
            }
        }

        if (nameIndexDictionary.count <= 40 && nameIndexDictionary.count < zipCodesArray.count / 5)
        {
            [nameIndexDictionary removeAllObjects];
            break;
        }

        [nameIndexDictionary removeAllObjects];
    }

    // Create indexes.
    for (NSString* zipCode in zipCodesArray)
    {
        NSString*       name = zipCode;
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

    // Lookup city that belongs to this ZIP code, and check if it matches with current city.
    NSDictionary*   mismatchCity = nil;
    for (NSDictionary* city in citiesArray)
    {
        NSString*   zipCode;

        for (zipCode in city[@"zipCodes"])
        {
            if ([name isEqualToString:zipCode])
            {
                if (purchaseInfo[@"city"] != nil &&
                    [city[@"city"] isEqualToString:purchaseInfo[@"city"]] == NO)
                {
                    mismatchCity = city;
                }
                else
                {
                    // Set city that belongs to selected ZIP code.
                    purchaseInfo[@"city"] = city[@"city"];
                }

                break;
            }
        }

        if ([name isEqualToString:zipCode])
        {
            break;
        }
    }

    if (mismatchCity == nil)
    {
        if (checkmarkedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            checkmarkedCell.accessoryType = UITableViewCellAccessoryNone;
        }

        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        purchaseInfo[@"zipCode"] = name;

        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertTitle", nil,
                                                  [NSBundle mainBundle], @"City Mismatch",
                                                  @"Alert title saying that city does not match.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreaZips CityMismatchAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The ZIP code you selected belongs to another "
                                                    @"city than the one you selected earlier: %@.\n"
                                                    @"Do you want to select another city?",
                                                    @"Alert message telling saying that city does not match.\n"
                                                    @"[iOS alert message size - use correct term for "
                                                    @"'ZIP code']");
        message = [NSString stringWithFormat:message, purchaseInfo[@"city"]];
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

                 purchaseInfo[@"zipCode"] = name;
                 purchaseInfo[@"city"]    = mismatchCity[@"city"];

                 [self.navigationController popViewControllerAnimated:YES];
             }
             else
             {
                 [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
             }
         }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:[CommonStrings okString], nil];
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
    if ([name isEqualToString:purchaseInfo[@"zipCode"]])
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
