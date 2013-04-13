//
//  NumberAreasViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 09/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreasViewController.h"
#import "NumberType.h"
#import "WebClient.h"
#import "CountryNames.h"
#import "BlockAlertView.h"
#import "CommonStrings.h"
#import "Common.h"
#import "NumberAreaViewController.h"
#import "NumberAreasCell.h"


@interface NumberAreasViewController ()
{
    NSDictionary*           country;
    NSDictionary*           state;
    NumberTypeMask          numberTypeMask;

    NSArray*                nameIndexArray;         // Array with all first letters of country names.
    NSMutableDictionary*    nameIndexDictionary;    // Dictionary with entry (containing array of names) per letter.
    NSMutableArray*         filteredNamesArray;

    NSMutableArray*         allAreasArray;
    NSMutableArray*         areasArray;
    BOOL                    isFiltered;
}

@end


@implementation NumberAreasViewController

- (id)initWithCountry:(NSDictionary*)theCountry
                state:(NSDictionary*)theState
       numberTypeMask:(NumberTypeMask)theNumberTypeMask
{
    if (self = [super initWithNibName:@"NumberAreasView" bundle:nil])
    {
        country        = theCountry;
        state          = theState;      // Is nil for country without states.
        numberTypeMask = theNumberTypeMask;

        areasArray     = [NSMutableArray array];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [CommonStrings loadingString];

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberAreasCell" bundle:nil]
         forCellReuseIdentifier:@"NumberAreasCell"];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if (state != nil)
    {
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:country[@"isoCountryCode"]
                                                             stateCode:state[@"stateCode"]
                                                                 reply:^(WebClientStatus status, id content)
        {
            if (status == WebClientStatusOk)
            {
                [self processContent:content];
            }
            else
            {
                [self handleWebClientStatus:status];
            }
        }];
    }
    else
    {
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:country[@"isoCountryCode"]
                                                        numberTypeMask:numberTypeMask
                                                                 reply:^(WebClientStatus status, id content)
        {
            if (status == WebClientStatusOk)
            {
                [self processContent:content];
            }
            else
            {
                [self handleWebClientStatus:status];
            }
        }];
    }
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

    if (state != nil)
    {
        [[WebClient sharedClient] cancelAllRetrieveNumberAreasForIsoCountryCode:country[@"isoCountryCode"]
                                                                      stateCode:state[@"stateCode"]];
    }
    else
    {
        [[WebClient sharedClient] cancelAllRetrieveNumberAreasForIsoCountryCode:country[@"isoCountryCode"]];
    }
}


#pragma mark - Helper Methods

- (void)processContent:(id)content
{
    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberAreas:Done ScreenTitle", nil,
                                                                  [NSBundle mainBundle], @"Areas",
                                                                  @"Title of app screen with list of areas.\n"
                                                                  @"[1 line larger font].");

    if ([(NSArray*)content count] > 0)
    {
        for (NSDictionary* area in content)
        {
            NSMutableDictionary*    mutableArea;

            mutableArea = [NSMutableDictionary dictionaryWithDictionary:area];
            if ([mutableArea objectForKey:@"areaName"] != [NSNull null])
            {
                NSLocale*   locale = [NSLocale currentLocale];
                mutableArea[@"areaName"] = [mutableArea[@"areaName"] capitalizedStringWithLocale:locale];
            }
            else if ([mutableArea objectForKey:@"areaCode"] != [NSNull null])
            {
                // To support non-geographic numbers with little code change.
                mutableArea[@"areaName"] = mutableArea[@"areaCode"];
            }
            else
            {
                mutableArea[@"areaName"] = NSLocalizedStringWithDefaultValue(@"NumberAreas:Table NoAreaCode", nil,
                                                                             [NSBundle mainBundle], @"Unknown area code",
                                                                             @"Explains that area code is not available.\n"
                                                                             @"[1 line larger font].");
            }

            [areasArray addObject:mutableArea];
        }

        [self sortOutArrays];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreas NoNumbersAlertTitle", nil,
                                                  [NSBundle mainBundle], @"Numbers Unavailable",
                                                  @"Alert title telling that phone numbers are not available.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas NoNumbersAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"These numbers are not available for purchase at the moment."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that phone numbers are not available.\n"
                                                    @"[iOS alert message size!]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[CommonStrings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)handleWebClientStatus:(WebClientStatus)status
{
    if (status == WebClientStatusFailServiceUnavailable)
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertTitle", nil,
                                                  [NSBundle mainBundle], @"Service Unavailable",
                                                  @"Alert title telling that loading areas over internet failed.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The service for buying numbers is temporarily offline."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
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

        title = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertTitle", nil,
                                                  [NSBundle mainBundle], @"Loading Failed",
                                                  @"Alert title telling that loading countries over internet failed.\n"
                                                  @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Loading the list of areas failed.\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
                             cancelButtonTitle:[CommonStrings cancelString]
                             otherButtonTitles:nil];
    }
}


- (void)sortOutArrays
{
    // Create indexes.
    nameIndexDictionary = [NSMutableDictionary dictionary];
    for (NSMutableDictionary* area in areasArray)
    {
        NSString*       name = area[@"areaName"];
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
    NSDictionary*       area;

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    // Look up area.
    for (area in areasArray)
    {
        if ([area[@"areaName"] isEqualToString:name])
        {
            break;
        }
    }

    NumberAreaViewController*   viewController;
    viewController = [[NumberAreaViewController alloc] initWithCountry:country
                                                                 state:state
                                                                  area:area
                                                        numberTypeMask:numberTypeMask];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberAreasCell*    cell;
    NSString*           name;
    NSDictionary*       area;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberAreasCell"];
    if (cell == nil)
    {
        cell = [[NumberAreasCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NumberAreasCell"];
    }

    if (isFiltered)
    {
        name = filteredNamesArray[indexPath.row];
    }
    else
    {
        name = nameIndexDictionary[nameIndexArray[indexPath.section]][indexPath.row];
    }

    // Look up area.
    for (area in areasArray)
    {
        if ([area[@"areaName"] isEqualToString:name])
        {
            break;
        }
    }

    cell.accessoryType = UITableViewCellAccessoryNone;
    if (area[@"areaCode"] != [NSNull null])
    {
        if ([area[@"areaCode"] isEqualToString:name] == NO)
        {
            cell.areaCode.text = area[@"areaCode"];
            cell.areaName.text = name;
        }
        else
        {
            cell.areaCode.text = name;
            cell.areaName.text = @"";
        }
    }
    else
    {
        cell.areaCode.text = @"---";
        cell.areaName.text = name;
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
