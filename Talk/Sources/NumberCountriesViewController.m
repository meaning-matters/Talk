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
#import "NumberFilterViewController.h"
#import "CountryNames.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "NumberType.h"
#import "Common.h"
#import "Settings.h"
#import "AddressType.h"
#import "BlockAlertView.h"


@interface NumberCountriesViewController () <NumberFilterViewControllerDelegate>

@property (nonatomic, strong) NSArray*            numberCountries;       // As received from the server.
@property (nonatomic, strong) NSMutableArray*     countriesArray;        // Contains all countries for all number types.
@property (nonatomic, strong) UISegmentedControl* numberTypeSegmentedControl;
@property (nonatomic, strong) UIBarButtonItem*    textItem;
@property (nonatomic, strong) UIBarButtonItem*    iconItem;
@property (nonatomic, assign) AddressTypeMask     addressTypeMask;       // Address type of home country for selected number type.
@property (nonatomic, readonly) BOOL              isFilterComplete;

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

    [self.navigationController setToolbarHidden:NO];
    
    self.searchBar.placeholder  = [self searchBarPlaceHolder];
    UIBarButtonItem* spaceItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:self
                                                                                action:nil];
    self.textItem               = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Select where you're based", @"")
                                                                   style:UIBarButtonItemStylePlain
                                                                  target:self
                                                                  action:@selector(filterAction)];
    self.textItem.tintColor = [Skinning placeholderColor];
    UIImage* image = [[UIImage imageNamed:@"Filter"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.iconItem  = [[UIBarButtonItem alloc] initWithImage:image
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(filterAction)];
    self.iconItem.tintColor = [Skinning placeholderColor];
    self.toolbarItems = @[ spaceItem, self.textItem, self.iconItem ];

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberCountries:^(NSError* error, id content)
    {
        if (error == nil)
        {
            self.numberCountries = content;

            // Combine numberTypes per country.
            for (NSDictionary* newCountry in self.numberCountries)
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
                    matchedCountry[@"numberType"]  = nil;
                    matchedCountry[@"regulations"] = [NSMutableDictionary dictionary];
                    [self.countriesArray addObject:matchedCountry];
                }

                NumberTypeMask mask = [NumberType numberTypeMaskForString:newCountry[@"numberType"]];
                matchedCountry[@"numberTypes"] = @([matchedCountry[@"numberTypes"] intValue] | mask);

                matchedCountry[@"regulations"][newCountry[@"numberType"]] = newCountry[@"regulation"];
                matchedCountry[@"regulation"] = nil;
            }

            if (!self.isFilterComplete)
            {
                [self filterAction];
            }

            // Added number type selector.
            NSArray* items = @[[NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeGeographicMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeNationalMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeMobileMask],
                               [NumberType abbreviatedLocalizedStringForNumberTypeMask:NumberTypeTollFreeMask]];
            self.numberTypeSegmentedControl = [[UISegmentedControl alloc] initWithItems:items];
            [self.numberTypeSegmentedControl addTarget:self
                                                action:@selector(numberTypeChangedAction)
                                      forControlEvents:UIControlEventValueChanged];
            self.navigationItem.titleView = self.numberTypeSegmentedControl;

            NSInteger index = [NumberType numberTypeMaskToIndex:[Settings sharedSettings].numberTypeMask];
            [self.numberTypeSegmentedControl setSelectedSegmentIndex:index];

            [self updateToolbar];
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


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.navigationController.toolbarHidden = NO;
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.navigationController.toolbarHidden = YES;

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


- (BOOL)isAllowedCountry:(NSDictionary*)country
{
    NSString*      isoCountryCode = [Settings sharedSettings].numberFilter[@"isoCountryCode"];
    NumberTypeMask numberTypeMask = (NumberTypeMask)(1UL << [self.numberTypeSegmentedControl selectedSegmentIndex]);
    NSString*      numberType     = [NumberType stringForNumberTypeMask:numberTypeMask];
    BOOL           isAllowed      = NO;

    AddressTypeMask addressTypeMask;
    NSString* addressTypeString = country[@"regulations"][numberType][@"addressType"];
    addressTypeMask = [AddressType addressTypeMaskForString:addressTypeString];

    switch (addressTypeMask)
    {
        case AddressTypeWorldwideMask:
        {
            isAllowed = YES;
            break;
        }
        case AddressTypeNationalMask:
        {
            isAllowed = [country[@"isoCountryCode"] isEqualToString:isoCountryCode];
            break;
        }
        case AddressTypeLocalMask:
        {
            isAllowed = [country[@"isoCountryCode"] isEqualToString:isoCountryCode];
            break;
        }
        case AddressTypeExtranational:
        {
            isAllowed = ![country[@"isoCountryCode"] isEqualToString:isoCountryCode];
            break;
        }
    }

    return isAllowed;
}


- (void)cancelAction
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

    void (^nextLevelBlock)(void) = ^
    {
        NumberTypeMask  numberTypeMask  = (NumberTypeMask)(1UL << self.numberTypeSegmentedControl.selectedSegmentIndex);
        AddressTypeMask addressTypeMask = [self addressTypeMaskForCountry:isoCountryCode numberTypeMask:numberTypeMask];
        if ([country[@"hasStates"] boolValue] && numberTypeMask == NumberTypeGeographicMask)
        {
            NumberStatesViewController* viewController;
            viewController = [[NumberStatesViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                         numberTypeMask:numberTypeMask
                                                                        addressTypeMask:addressTypeMask
                                                                     isFilteringEnabled:self.isFilterComplete];
            [self.navigationController pushViewController:viewController animated:YES];
        }
        else
        {
            NumberAreasViewController* viewController;
            viewController = [[NumberAreasViewController alloc] initWithIsoCountryCode:isoCountryCode
                                                                                 state:nil
                                                                        numberTypeMask:numberTypeMask
                                                                       addressTypeMask:addressTypeMask
                                                                    isFilteringEnabled:self.isFilterComplete
                                                                      isAllowedCountry:[self isAllowedCountry:country]];
            [self.navigationController pushViewController:viewController animated:YES];
        }
    };

    if ([self isAllowedCountry:country] || !self.isFilterComplete)
    {
        nextLevelBlock();
    }
    else
    {
        NSString* title   = NSLocalizedString(@"Can't Buy Number", @"");
        NSString* message = NSLocalizedString(@"If you're based in %@ (which you selected), you can't "
                                              @"buy this Number because of regulations in %@.\n\n"
                                              @"If you continue, you'll be asked for an Address in %@.", @"");
        NSString* filterIsoCountryCode = [Settings sharedSettings].numberFilter[@"isoCountryCode"];
        message = [NSString stringWithFormat:message, [[CountryNames sharedNames] nameForIsoCountryCode:filterIsoCountryCode],
                                                      [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode],
                                                      [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode]];
        [BlockAlertView showAlertViewWithTitle:title message:message completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            if (buttonIndex == 1)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                [self filterAction];
            }

            if (buttonIndex == 2)
            {
                nextLevelBlock();
            }

            if (cancelled)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:@"Update Filter", @"Continue", nil];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    id               country = [self objectOnTableView:tableView atIndexPath:indexPath];
    NSString*        name    = [self nameForObject:country];

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    // Strip away country code that was only added to the names to allow searching for it.
    NSMutableArray* components = [[name componentsSeparatedByString:@" "] mutableCopy];
    [components removeObjectAtIndex:(components.count - 1)];
    name = [components componentsJoinedByString:@" "];

    cell.imageView.image      = [UIImage imageNamed:country[@"isoCountryCode"]];
    cell.textLabel.text       = name;
    cell.detailTextLabel.text = [@"+" stringByAppendingString:[Common callingCodeForCountry:country[@"isoCountryCode"]]];
    cell.accessoryType        = UITableViewCellAccessoryNone;

    cell.contentView.alpha = ([self isAllowedCountry:country] || !self.isFilterComplete) ? 1.0 : 0.5;

    return cell;
}


#pragma mark - UI Actions

- (void)numberTypeChangedAction
{
    [Settings sharedSettings].numberTypeMask = (NumberTypeMask)(1UL << self.numberTypeSegmentedControl.selectedSegmentIndex);

    self.searchBar.placeholder = [self searchBarPlaceHolder];

    [self updateToolbar];
    [self sortOutArrays];
}


- (void)filterAction
{
    UINavigationController*      modalViewController;
    NumberFilterViewController* filterViewController;
    filterViewController = [[NumberFilterViewController alloc] initWithNumberCountries:self.numberCountries
                                                                              delegate:self
                                                                            completion:^
    {
        [self updateToolbar];
        [self sortOutArrays];
    }];

    modalViewController = [[UINavigationController alloc] initWithRootViewController:filterViewController];
    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [self presentViewController:modalViewController animated:YES completion:nil];
}


#pragma mark - NumberFilterViewControllerDelegate

- (BOOL)isFilterComplete
{
    NSString*       isoCountryCode  = [Settings sharedSettings].numberFilter[@"isoCountryCode"];
    AddressTypeMask addressTypeMask = [self addressTypeMaskForCountry:isoCountryCode numberTypeMask:NumberTypeGeographicMask];

    return isoCountryCode != nil &&
           ([Settings sharedSettings].numberFilter[@"areaName"] != nil || addressTypeMask != AddressTypeLocalMask);
}


#pragma mark - Helpers

- (void)updateToolbar
{
    self.addressTypeMask = [self addressTypeMaskForCountry:[Settings sharedSettings].numberFilter[@"isoCountryCode"]
                                            numberTypeMask:[Settings sharedSettings].numberTypeMask];

    if ([self isFilterComplete] == NO)
    {
        self.textItem.tintColor = [Skinning deleteTintColor];
        self.iconItem.tintColor = [Skinning deleteTintColor];
    }
    else
    {
        self.textItem.tintColor = [Skinning tintColor];
        self.iconItem.tintColor = [Skinning tintColor];
    }
}


- (AddressTypeMask)addressTypeMaskForCountry:(NSString*)isoCountryCode numberTypeMask:(NumberTypeMask)numberTypeMask
{
    AddressTypeMask addressTypeMask = AddressTypeWorldwideMask;    // Default to start with.

    if (isoCountryCode != nil)
    {
        NSPredicate*  predicate         = [NSPredicate predicateWithFormat:@"isoCountryCode == %@", isoCountryCode];
        NSDictionary* country           = [[self.countriesArray filteredArrayUsingPredicate:predicate] firstObject];
        NSString*     numberType        = [NumberType stringForNumberTypeMask:numberTypeMask];
        NSString*     addressTypeString = country[@"regulations"][numberType][@"addressType"];

        addressTypeMask = [AddressType addressTypeMaskForString:addressTypeString];
    }

    return addressTypeMask;
}

@end
