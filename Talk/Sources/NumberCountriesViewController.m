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

        self.navigationItem.title = [Strings countriesString];
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
            NSArray* items = @[[NumberType abbreviatedLocalizedStringForNumberType:NumberTypeGeographicMask],
                               [NumberType abbreviatedLocalizedStringForNumberType:NumberTypeNationalMask],
                               [NumberType abbreviatedLocalizedStringForNumberType:NumberTypeTollFreeMask],
                               [NumberType abbreviatedLocalizedStringForNumberType:NumberTypeMobileMask],
                               [NumberType abbreviatedLocalizedStringForNumberType:NumberTypeSharedCostMask],
                               [NumberType abbreviatedLocalizedStringForNumberType:NumberTypeSpecialMask]];
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
    NSMutableDictionary* country = object;

    return [[CountryNames sharedNames] nameForIsoCountryCode:country[@"isoCountryCode"]];
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
    NSString* numberType = [NumberType localizedStringForNumberType:[Settings sharedSettings].numberTypeMask];
    NSString* format     = NSLocalizedStringWithDefaultValue(@"NumberCountries Placeholder", nil, [NSBundle mainBundle],
                                                             @"Countries With %@ Numbers",
                                                             @"...");
    
    return [NSString stringWithFormat:format, numberType];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*     name           = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*     isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    NSDictionary* country;

    // Look up country.
    for (country in self.objectsArray)
    {
        if ([country[@"isoCountryCode"] isEqualToString:isoCountryCode])
        {
            break;
        }
    }

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
    NSString*        name           = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }
 
    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;
    cell.accessoryType   = UITableViewCellAccessoryNone;

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
