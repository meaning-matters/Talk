//
//  NumberStatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberStatesViewController.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"


@interface NumberStatesViewController ()
{
    NSDictionary*           country;

    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSMutableArray*         statesArray;
    BOOL                    isFiltered;
}

@end


@implementation NumberStatesViewController

- (id)initWithCountry:(NSDictionary*)theCountry
{
    if (self = [super initWithNibName:@"NumberStatesView" bundle:nil])
    {
        country = theCountry;
    }

    return self;
}


- (void)cancel
{
    [[WebClient sharedClient] cancelAllRetrieveNumberStatesForCountryId:country[@"countryId"]];
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

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberStates:Loading ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Loading States...",
                                                                  @"Title of app screen with list of countries, "
                                                                  @"while loading.\n"
                                                                  @"[1 line larger font - abbreviated 'Loading...'].");

    [[WebClient sharedClient] retrieveNumberStatesForCountryId:country[@"countryId"]
                                                         reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberStates:Done ScreenTitle", nil,
                                                                          [NSBundle mainBundle], @"Available States",
                                                                          @"Title of app screen with list of states.\n"
                                                                          @"[1 line larger font - abbreviated 'Countries'].");

            // Create indexes.
            statesArray = content;
            nameIndexDictionary = [NSMutableDictionary dictionary];
            for (NSMutableDictionary* state in statesArray)
            {
                NSString*       name = state[@"name"];
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
        }
        else if (status == WebClientStatusFailServiceUnavailable)
        {
            NSString*   title;
            NSString*   message;

            title = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Service Unavailable",
                                                      @"Alert title telling that loading states over internet failed.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberStates UnavailableAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"The service for buying numbers is temporarily offline."
                                                        @"\n\nPlease try again later.",
                                                        @"Alert message telling that loading states over internet failed.\n"
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

            title = NSLocalizedStringWithDefaultValue(@"NumberStates LoadFailAlertTitle", nil,
                                                      [NSBundle mainBundle], @"Loading Failed",
                                                      @"Alert title telling that loading states over internet failed.\n"
                                                      @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"NumberStates LoadFailAlertMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Loading the list of states failed.\n\nPlease try again later.",
                                                        @"Alert message telling that loading states over internet failed.\n"
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
    NSDictionary*       state;

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    // Look up state.
    for (state in statesArray)
    {
        if ([state[@"name"] isEqualToString:name])
        {
            break;
        }
    }

    //### push next level.
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;
    NSString*           name;
    NSDictionary*       state;

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
    for (state in statesArray)
    {
        if ([state[@"name"] isEqualToString:name])
        {
            break;
        }
    }

    cell.imageView.image = [UIImage imageNamed:country[@"isoCode"]];
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
