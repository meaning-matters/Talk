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

@property (nonatomic, strong) NSMutableArray*     countriesArray;        // Contains all countries for all number types.
@property (nonatomic, strong) UISegmentedControl* numberTypeSegmentedControl;

@end


@implementation NumberCountriesViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;

        self.countriesArray = [NSMutableArray array];
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
                for (NSMutableDictionary* country in self.countriesArray)
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
                    [self.countriesArray addObject:matchedCountry];
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
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveNumberCountries];
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    // Select from all on numberType.
    [self.objectsArray removeAllObjects];
    NumberTypeMask numberTypeMask = 1UL << [self.numberTypeSegmentedControl selectedSegmentIndex];
    for (NSMutableDictionary* country in self.countriesArray)
    {
        if ([country[@"numberTypes"] intValue] & numberTypeMask)
        {
            [self.objectsArray addObject:country];
        }
    }

    [self createIndex];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*     name;
    NSString*     isoCountryCode;
    NSDictionary* country;
    BOOL          isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    if (isFiltered)
    {
        name = self.filteredNamesArray[indexPath.row];
    }
    else
    {
        name = self.nameIndexDictionary[self.nameIndexArray[indexPath.section]][indexPath.row];
    }

    // Look up country.
    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    for (country in self.objectsArray)
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
    UITableViewCell* cell;
    NSString*        name;
    NSString*        isoCountryCode;
    BOOL             isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (isFiltered)
    {
        name = self.filteredNamesArray[indexPath.row];
    }
    else
    {
        name = self.nameIndexDictionary[self.nameIndexArray[indexPath.section]][indexPath.row];
    }

    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
 
    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;
    cell.accessoryType   = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Content Filtering

- (NSString*)nameForObject:(id)object
{
    NSMutableDictionary* country = object;

    return [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
}


#pragma mark - UI Actions

- (void)numberTypeChangedAction:(id)sender
{
    [Settings sharedSettings].numberTypeMask = 1UL << self.numberTypeSegmentedControl.selectedSegmentIndex;
    [self sortOutArrays];
}

@end
