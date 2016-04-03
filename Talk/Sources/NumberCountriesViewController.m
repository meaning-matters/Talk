//
//  NumberCountriesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 05/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
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

        self.navigationItem.title = [Strings newNumberString];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.searchBar.placeholder = [self searchBarPlaceHolder];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberCountries:^(NSError* error, id content)
    {
        if (error == nil)
        {
            // Added number type selector.
            NSArray* items = @[[NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeGeographicMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeNationalMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeMobileMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeTollFreeMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeSharedCostMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeSpecialMask]];
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
                NSMutableDictionary* matchedCountry = nil;
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
            self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
        }
        else if (error.code == WebStatusFailServiceUnavailable)
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


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveNumberCountries];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    NSDictionary* country = object;
    NSString*     name    = [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];

    // To allow searching for country code, add it behind the name. Before display it will be stripped away again below.
    name = [NSString stringWithFormat:@"%@ +%@", name, [Common callingCodeForCountry:country[@"isoCountryCode"]]];

    return name;
}


#pragma mark - Helper Methods

- (void)sortOutArrays
{
    // Select from all on numberType.
    NSMutableArray* currentObjectsArray = [NSMutableArray array];
    NumberTypeMask  numberTypeMask      = (NumberTypeMask)(1UL << [self.numberTypeSegmentedControl selectedSegmentIndex]);

    for (NSMutableDictionary* country in self.countriesArray)
    {
        if ([country[@"numberTypes"] intValue] & numberTypeMask)
        {
            [currentObjectsArray addObject:country];
        }
    }

    self.objectsArray = currentObjectsArray;
    [self createIndexOfWidth:1];
}


- (void)cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (NSString*)searchBarPlaceHolder
{
    NSString* numberType = [NumberType localizedStringForNumberTypeMask:[Settings sharedSettings].numberTypeMask];
    NSString* format     = NSLocalizedStringWithDefaultValue(@"NumberCountries Placeholder", nil, [NSBundle mainBundle],
                                                             @"Countries With %@ Numbers",
                                                             @"...");
    
    return [NSString stringWithFormat:format, numberType];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSDictionary* country        = [self objectOnTableView:tableView atIndexPath:indexPath];
    NSString*     isoCountryCode = country[@"isoCountryCode"];

    NumberTypeMask  numberTypeMask = (NumberTypeMask)(1UL << self.numberTypeSegmentedControl.selectedSegmentIndex);
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
    id               object = [self objectOnTableView:tableView atIndexPath:indexPath];
    NSString*        name   = [self nameForObject:object];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    // Strip away country code that was only added to the names to allow searching for it.
    NSMutableArray* components = [[name componentsSeparatedByString:@" "] mutableCopy];
    [components removeObjectAtIndex:(components.count - 1)];
    name = [components componentsJoinedByString:@" "];

    cell.imageView.image      = [UIImage imageNamed:object[@"isoCountryCode"]];
    cell.textLabel.text       = name;
    cell.detailTextLabel.text = [@"+" stringByAppendingString:[Common callingCodeForCountry:object[@"isoCountryCode"]]];
    cell.accessoryType        = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - UI Actions

- (void)numberTypeChangedAction:(id)sender
{
    [Settings sharedSettings].numberTypeMask = (NumberTypeMask)(1UL << self.numberTypeSegmentedControl.selectedSegmentIndex);
    [self sortOutArrays];
    
    self.searchBar.placeholder = [self searchBarPlaceHolder];
}

@end
