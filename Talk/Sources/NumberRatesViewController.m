//
//  NumberRatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 01/06/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "NumberRatesViewController.h"
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CountryNames.h"
#import "PurchaseManager.h"
#import "Settings.h"


@implementation NumberRatesViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberRates ScreenTitle", nil,
                                                                  [NSBundle mainBundle],
                                                                  @"Number Rates",
                                                                  @"....\n"
                                                                  @"[iOS alert title size].");

    if ([self checkCurrencyCode] == NO)
    {
        return;
    }

    [self retrieveNumberRates];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveNumberRates];
}


#pragma mark - Base Class Override

- (NSString*)nameForObject:(id)object
{
    return [[CountryNames sharedNames] nameForIsoCountryCode:object[@"isoCountryCode"]];
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*     name                = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*     isoCountryCode      = [[CountryNames sharedNames] isoCountryCodeForName:name];
    NSDictionary* rate                = [self rateForIsoCountryCode:isoCountryCode];

    float         fixedPrice          = [rate[@"fixedPrice"]  floatValue];
    float         mobilePrice         = [rate[@"mobilePrice"] floatValue];
    NSLog(@"####### Forgot to use strings below???");
    NSString*     fixedPriceString    = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:fixedPrice];
    NSString*     mobilePriceString   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:mobilePrice];

    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"NumberRates InfoAlertTitle", nil, [NSBundle mainBundle],
                                                @"Prices Per Minute To %@",
                                                @"....\n"
                                                @"[iOS alert message size]");
    message = NSLocalizedStringWithDefaultValue(@"NumberRates InfoAlertMessage", nil, [NSBundle mainBundle],
                                                @"Fixed: from %@\nMobile: from %@\n\n"
                                                @"Plus the nback to your %@ number in %@: %@",
                                                @"....\n"
                                                @"[iOS alert message size]");
    title   = [NSString stringWithFormat:title, isoCountryCode];
    message = [NSString stringWithFormat:@"message..."];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NSString*        name           = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    NSDictionary*    rate           = [self rateForIsoCountryCode:isoCountryCode];
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;

    NSString* format = NSLocalizedStringWithDefaultValue(@"NumberRates Format", nil, [NSBundle mainBundle],
                                                         @"fix.: %@  mob.: %@",
                                                         @"....\n"
                                                         @"[iOS alert title size].");

    float         outgoingFixedPrice  = [rate[@"fixedPrice"]  floatValue];
    float         outgoingMobilePrice = [rate[@"mobilePrice"] floatValue];
    float         fixedPrice          = 0 + outgoingFixedPrice;
    float         mobilePrice         = 0 + outgoingMobilePrice;
    NSString*     fixedPriceString    = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:fixedPrice];
    NSString*     mobilePriceString   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:mobilePrice];

    cell.detailTextLabel.text = [NSString stringWithFormat:format, fixedPriceString, mobilePriceString];
    cell.accessoryType        = UITableViewCellAccessoryNone;

    return cell;
}


#pragma mark - Helpers

- (void)retrieveNumberRates
{
    self.isLoading = YES;
    [[WebClient sharedClient] retrieveNumberRates:^(NSError *error, NSArray *rates)
    {
        if (error == nil)
        {
            self.objectsArray  = rates;
            [self createIndexOfWidth:1];

            self.isLoading = NO;    // Placed here, after processing results, to let reload of search results work.
        }
        else
        {
            [self handleError:error];
        }
    }];
}


- (NSDictionary*)rateForIsoCountryCode:(NSString*)isoCountryCode
{
    NSPredicate*  predicate = [NSPredicate predicateWithFormat:@"isoCountryCode MATCHES %@", isoCountryCode];
    NSDictionary* rate      = [[self.objectsArray filteredArrayUsingPredicate:predicate] firstObject];

    return rate;
}


- (BOOL)checkCurrencyCode
{
    if ([Settings sharedSettings].storeCurrencyCode.length == 0)
    {
        NSString* title;
        NSString* message;
        title   = NSLocalizedStringWithDefaultValue(@"NumberRates NoCurrencyCodeTitle", nil, [NSBundle mainBundle],
                                                    @"Currency Not Known",
                                                    @"...\n"
                                                    @"...");
        message = NSLocalizedStringWithDefaultValue(@"NumberRates NoCurrencyCodeMessage", nil, [NSBundle mainBundle],
                                                    @"The currency code has not been loaded from the iTunes Store (yet).\n\n"
                                                    @"Please make sure your iTunes Store account is active on this device, "
                                                    @"and you're connected to internet.",
                                                    @"...\n"
                                                    @"...");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else
    {
        return YES;
    }
}


- (void)handleError:(NSError*)error
{
    if (error.code == WebStatusFailServiceUnavailable)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberRates UnavailableAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Service Unavailable",
                                                    @"Alert title telling that loading number rates over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberRates UnavailableAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The service that supplies number rates is temporarily offline."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that loading number rates over internet failed.\n"
                                                    @"[iOS alert message size]");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }
    else
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"NumberRates LoadFailAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Loading Failed",
                                                    @"Alert title telling that loading countries over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"NumberRates LoadFailAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Loading the list of number rates failed: %@\n\nPlease try again later.",
                                                    @"Alert message telling that loading number rates over internet failed.\n"
                                                    @"[iOS alert message size]");
        message = [NSString stringWithFormat:message, error.localizedDescription];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }
}

@end
