//
//  CallRatesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 05/04/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "CallRatesViewController.h"
#import "Strings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "CountryNames.h"
#import "PurchaseManager.h"
#import "Settings.h"


@interface CallRatesViewController ()

@property (nonatomic, strong) PhoneNumber* callbackPhoneNumber;
@property (nonatomic, assign) float        callbackPrice;

@end


@implementation CallRatesViewController

- (instancetype)initWithCallbackPhoneNumber:(PhoneNumber*)callbackPhoneNumber
{
    if (self = [super init])
    {
        self.tableView.dataSource = self;
        self.tableView.delegate   = self;

        if (callbackPhoneNumber == nil)
        {
            self.callbackPhoneNumber = [[PhoneNumber alloc] initWithNumber:[Settings sharedSettings].callbackE164];
        }
        else
        {
            self.callbackPhoneNumber = callbackPhoneNumber;
        }
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [Strings loadingString];

    if ([self checkCurrencyCode] == NO)
    {
        return;
    }

    [self retrieveCallRates];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[WebClient sharedClient] cancelAllRetrieveCallRates];
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
    NSString*     callbackPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:self.callbackPrice];
    NSString*     fixedPriceString    = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:fixedPrice];
    NSString*     mobilePriceString   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:mobilePrice];

    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"CallRates InfoAlertTitle", nil, [NSBundle mainBundle],
                                                @"Prices Per Minute To %@",
                                                @"....\n"
                                                @"[iOS alert message size]");
    message = NSLocalizedStringWithDefaultValue(@"CallRates InfoAlertMessage", nil, [NSBundle mainBundle],
                                                @"Fixed: from %@\nMobile: from %@\n\n"
                                                @"Plus the callback to your %@ number in %@: %@",
                                                @"....\n"
                                                @"[iOS alert message size]");
    title   = [NSString stringWithFormat:title, isoCountryCode];
    message = [NSString stringWithFormat:message, fixedPriceString, mobilePriceString,
                                         self.callbackPhoneNumber.typeString, self.callbackPhoneNumber.isoCountryCode,
                                         callbackPriceString];
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

    NSString* format = NSLocalizedStringWithDefaultValue(@"CallRates Format", nil, [NSBundle mainBundle],
                                                         @"fix.: %@  mob.: %@",
                                                         @"....\n"
                                                         @"[iOS alert title size].");

    float         outgoingFixedPrice  = [rate[@"fixedPrice"]  floatValue];
    float         outgoingMobilePrice = [rate[@"mobilePrice"] floatValue];
    float         fixedPrice          = self.callbackPrice + outgoingFixedPrice;
    float         mobilePrice         = self.callbackPrice + outgoingMobilePrice;
    NSString*     fixedPriceString    = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:fixedPrice];
    NSString*     mobilePriceString   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:mobilePrice];

    cell.detailTextLabel.text = [NSString stringWithFormat:format, fixedPriceString, mobilePriceString];
    cell.accessoryType        = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Helpers

- (void)retrieveCallRates
{
    [[WebClient sharedClient] retrieveCallRateForE164:self.callbackPhoneNumber.e164Format
                                         currencyCode:[Settings sharedSettings].currencyCode
                                                reply:^(NSError *error, float ratePerMinute)
    {
        if (error == nil)
        {
            [[WebClient sharedClient] retrieveCallRates:^(NSError *error, NSArray *rates)
            {
                if (error == nil)
                {
                    self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"CallRates ScreenTitle", nil,
                                                                                  [NSBundle mainBundle],
                                                                                   @"Call Rates",
                                                                                   @"....\n"
                                                                                   @"[iOS alert title size].");
                    self.callbackPrice = ratePerMinute;
                    self.objectsArray  = rates;
                    [self createIndexOfWidth:1];
                }
                else
                {
                    [self handleError:error];
                }
            }];
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
    if ([Settings sharedSettings].currencyCode.length == 0)
    {
        NSString* title;
        NSString* message;
        title   = NSLocalizedStringWithDefaultValue(@"CallRates NoCurrencyCodeTitle", nil, [NSBundle mainBundle],
                                                    @"Currency Not Known",
                                                    @"...\n"
                                                    @"...");
        message = NSLocalizedStringWithDefaultValue(@"CallRates NoCurrencyCodeMessage", nil, [NSBundle mainBundle],
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
    if (error.code == WebClientStatusFailServiceUnavailable)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"CallRates UnavailableAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Service Unavailable",
                                                    @"Alert title telling that loading call rates over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"CallRates UnavailableAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"The service that supplies call rates is temporarily offline."
                                                    @"\n\nPlease try again later.",
                                                    @"Alert message telling that loading call rates over internet failed.\n"
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

        title   = NSLocalizedStringWithDefaultValue(@"CallRates LoadFailAlertTitle", nil,
                                                    [NSBundle mainBundle], @"Loading Failed",
                                                    @"Alert title telling that loading countries over internet failed.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"CallRates LoadFailAlertMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Loading the list of call rates failed: %@\n\nPlease try again later.",
                                                    @"Alert message telling that loading call rates over internet failed.\n"
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
