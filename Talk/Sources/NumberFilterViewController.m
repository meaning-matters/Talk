//
//  NumberFilterViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 22/05/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NumberFilterViewController.h"
#import "CountriesViewController.h"
#import "NumberFilterAreasViewController.h"
#import "CountryNames.h"
#import "Settings.h"
#import "Strings.h"
#import "NumberType.h"
#import "WebClient.h"
#import "Common.h"
#import "BlockAlertView.h"


@interface NumberFilterViewController ()

@property (nonatomic, strong) NSArray*                             numberCountries;
@property (nonatomic, weak) id<NumberFilterViewControllerDelegate> delegate;
@property (nonatomic, copy) void                                 (^completion)();
@property (nonatomic, strong) NSArray*                             areas;
@property (nonatomic, strong) NSString*                            loadingIsoCountryCode;
@property (nonatomic, strong) NSDictionary*                        numberFilter;

@end


@implementation NumberFilterViewController

- (instancetype)initWithNumberCountries:(NSArray*)numberCountries
                               delegate:(id<NumberFilterViewControllerDelegate>)delegate
                             completion:(void (^)())completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedString(@"Filter Numbers", @"");

        self.numberCountries = numberCountries;
        self.delegate        = delegate;
        self.completion      = completion;
        self.numberFilter    = [Settings sharedSettings].numberFilter;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;

    if ([Settings sharedSettings].numberFilter == nil)
    {
        [Settings sharedSettings].numberFilter = @{ @"isoCountryCode" : [Settings sharedSettings].homeIsoCountryCode };
    }

    UIBarButtonItem* buttonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                target:self
                                                                                action:@selector(doneAction)];
    self.navigationItem.leftBarButtonItem = buttonItem;

    UIBarButtonItem* cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancelAction)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if ([Settings sharedSettings].numberFilter[@"isoCountryCode"] != nil)
    {
        [self loadAreasForIsoCountryCode:[Settings sharedSettings].numberFilter[@"isoCountryCode"]];
    }

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    self.completion ? self.completion() : 0;

    if (self.loadingIsoCountryCode != nil)
    {
        [[WebClient sharedClient] cancelAllRetrieveNumberAreasForIsoCountryCode:self.loadingIsoCountryCode];
    }
}


#pragma mark - Table Delegates

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.areas.count > 0) ? 2 : 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if (indexPath.row == 0)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"CountryCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"CountryCell"];
        }

        NSString* isoCountryCode  = [Settings sharedSettings].numberFilter[@"isoCountryCode"];
        cell.imageView.image      = [UIImage imageNamed:isoCountryCode];
        cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];
    }
    else
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"AreaCell"];
        if (cell == nil)
        {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AreaCell"];
            cell.textLabel.text = [Strings areaString];
        }

        NSString* name = [Common capitalizedString:[Settings sharedSettings].numberFilter[@"areaName"]];
        if (name.length == 0)
        {
            name = [Strings requiredString];
            cell.detailTextLabel.textColor = [Skinning placeholderColor];
        }
        else
        {
            cell.detailTextLabel.textColor = [Skinning valueColor];
        }

        cell.detailTextLabel.text = name;
    }

    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSMutableDictionary* numberFilter = [[Settings sharedSettings].numberFilter mutableCopy];

    if (indexPath.row == 0)
    {
        CountriesViewController* countriesViewController;
        countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:numberFilter[@"isoCountryCode"]
                                                                                    title:[Strings countryString]
                                                                               completion:^(BOOL      cancelled, // Always NO (see TODO).
                                                                                            NSString* isoCountryCode)
        {
            if ([isoCountryCode isEqualToString:numberFilter[@"isoCountryCode"]])
            {
                return;
            }

            [Settings sharedSettings].numberFilter = @{@"isoCountryCode" : isoCountryCode};

            // Set the cell to prevent quick update right after animations.
            UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];
            cell.imageView.image      = [UIImage imageNamed:isoCountryCode];
            cell.detailTextLabel.text = [[CountryNames sharedNames] nameForIsoCountryCode:isoCountryCode];

            if ([self tableView:tableView numberOfRowsInSection:0] == 2)
            {
                self.areas = nil;

                NSIndexPath* indexPath = [NSIndexPath indexPathForRow:1 inSection:0];

                [tableView beginUpdates];
                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                [tableView endUpdates];
            }

            [self loadAreasForIsoCountryCode:isoCountryCode];
        }];

        [self.navigationController pushViewController:countriesViewController animated:YES];
    }
    else
    {
        NumberFilterAreasViewController* areasViewController;
        areasViewController = [[NumberFilterAreasViewController alloc] initWithIsoCountryCode:numberFilter[@"isoCountryCode"]
                                                                                        areas:self.areas
                                                                                        completion:^(NSDictionary* area)
        {
            numberFilter[@"areaName"] = area[@"areaName"];
            numberFilter[@"areaCode"] = area[@"areaCode"];
            [Settings sharedSettings].numberFilter = numberFilter;

            self.navigationItem.leftBarButtonItem.enabled = YES;

            [self reloadTable];
        }];

        [self.navigationController pushViewController:areasViewController animated:YES];
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Where You Are Based", @"");
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.showFootnotes == NO)
    {
        return nil;
    }

    return NSLocalizedString(@"Each country has regulations that determine who is allowed to have a telephone number of "
                             @"a certain type.\nFor local numbers for example, many countries require you to have an "
                             @"address in that same area.\n\n"
                             @"By selecting where you're based, you'll only see the numbers you can have.", @"");
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 45;
}


#pragma mark - Helpers

- (void)loadAreasForIsoCountryCode:(NSString*)isoCountryCode
{
    NSDictionary* numberFilter = [Settings sharedSettings].numberFilter;
    if (numberFilter[@"isoCountryCode"] != nil && numberFilter[@"areaName"] == nil && [self.delegate isFilterComplete])
    {
        return;
    }

    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"isoCountryCode == %@", isoCountryCode];
    NSArray*     matches   = [self.numberCountries filteredArrayUsingPredicate:predicate];

    predicate = [NSPredicate predicateWithFormat:@"numberType == %@", [NumberType stringForNumberTypeMask:NumberTypeGeographicMask]];
    matches   = [matches filteredArrayUsingPredicate:predicate];

    // GEOGRAPHIC US and CA (with states), still have addressType WORLDWIDE luckily, so no filtering required.
    //### TODO: Add filtering support for countries with states when the above changes.
    if (matches.count == 1 && [matches[0][@"hasStates"] boolValue] == NO)
    {
        self.loadingIsoCountryCode = isoCountryCode;
        self.isLoading = YES;
        [[WebClient sharedClient] retrieveNumberAreasForIsoCountryCode:isoCountryCode
                                                        numberTypeMask:NumberTypeGeographicMask
                                                          currencyCode:[Settings sharedSettings].storeCurrencyCode
                                                                 reply:^(NSError* error, id content)
        {
            self.loadingIsoCountryCode = nil;

            if (error == nil)
            {
                self.isLoading = NO;

                self.areas = content;
                self.navigationItem.leftBarButtonItem.enabled = (self.areas.count == 0) ||
                                                                [[Settings sharedSettings].numberFilter[@"areaCode"] length] > 0;

                [self reloadTable];
            }
            else
            {
                [self handleError:error];
            }
        }];
    }
    else
    {
        self.navigationItem.leftBarButtonItem.enabled = YES;
    }
}


- (void)reloadTable
{
    NSIndexSet* sections = [NSIndexSet indexSetWithIndex:0];
    [self.tableView beginUpdates];
    [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}


#pragma mark - Actions

- (void)doneAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)cancelAction
{
    // Put back the original.
    [Settings sharedSettings].numberFilter = self.numberFilter;

    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma - Helpers

- (void)handleError:(NSError*)error
{
    if (error.code == WebStatusFailServiceUnavailable)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Service Unavailable",
                                                    @"Alert title telling that loading areas over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas UnavailableAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The service that supplies filter information is temporarily offline."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
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

        title   = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Loading Failed",
                                                    @"Alert title telling that loading filter info over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberAreas LoadFailAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Loading filter information failed: %@\n\nPlease try again later.",
                                                    @"Alert message telling that loading areas over internet failed.\n"
                                                    @"[iOS alert message size!]");
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
}

@end
