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
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [Strings loadingString];
    [[WebClient sharedClient] retrieveCallRates:^(NSError *error, NSArray *rates)
    {
        if (error == nil)
        {
             self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"CallRates ScreenTitle", nil,
                                                                           [NSBundle mainBundle],
                                                                           @"Call Rate Countries",
                                                                           @"....\n"
                                                                           @"[iOS alert title size].");
            self.objectsArray = rates;
            [self createIndexOfWidth:1];
        }
        else if (error.code == WebClientStatusFailServiceUnavailable)
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
    NSString*     name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*     isoCountryCode;
    NSDictionary* callRate;

    // Look up country.
    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];
    for (callRate in self.objectsArray)
    {
        if ([callRate[@"isoCountryCode"] isEqualToString:isoCountryCode])
        {
            break;
        }
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;
    NSString*        name = [self nameOnTable:tableView atIndexPath:indexPath];
    NSString*        isoCountryCode;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }
    
    isoCountryCode = [[CountryNames sharedNames] isoCountryCodeForName:name];

    cell.imageView.image = [UIImage imageNamed:isoCountryCode];
    cell.textLabel.text  = name;

    NSString* format = NSLocalizedStringWithDefaultValue(@"CallRates Format", nil, [NSBundle mainBundle],
                                                         @"fix.: %@  mob.: %@",
                                                         @"....\n"
                                                         @"[iOS alert title size].");

    float         callbackPrice       = [self callbackPrice];
    NSDictionary* rate                = [self rateForIsoCountryCode:isoCountryCode];
    float         outgoingFixedPrice  = [rate[@"fixedPrice"]  floatValue];
    float         outgoingMobilePrice = [rate[@"mobilePrice"] floatValue];
    float         fixedPrice          = callbackPrice + outgoingFixedPrice;
    float         mobilePrice         = callbackPrice + outgoingMobilePrice;
    NSString*     fixedPriceString    = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:fixedPrice  / 100.0f];
    NSString*     mobilePriceString   = [[PurchaseManager sharedManager] localizedFormattedPrice2ExtraDigits:mobilePrice / 100.0f];

    cell.detailTextLabel.text = [NSString stringWithFormat:format, fixedPriceString, mobilePriceString];
    cell.accessoryType        = UITableViewCellAccessoryNone;
    
    return cell;
}


#pragma mark - Helpers

- (NSDictionary*)rateForIsoCountryCode:(NSString*)isoCountryCode
{
    NSPredicate*  predicate = [NSPredicate predicateWithFormat:@"isoCountryCode MATCHES %@", isoCountryCode];
    NSDictionary* rate      = [[self.objectsArray filteredArrayUsingPredicate:predicate] firstObject];

    return rate;
}


- (float)callbackPrice
{
    NSDictionary* rate = [self rateForIsoCountryCode:self.callbackPhoneNumber.isoCountryCode];

    float price;

    switch (self.callbackPhoneNumber.type)
    {
        case PhoneNumberTypeUnknown:           price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeEmergency:         price = [rate[@"fixedPrice"]  floatValue]; break;
        case PhoneNumberTypeFixedLine:         price = [rate[@"fixedPrice"]  floatValue]; break;
        case PhoneNumberTypeMobile:            price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeFixedLineOrMobile: price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypePager:             price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypePersonalNumber:    price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypePremiumRate:       price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeSharedCost:        price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeShortCode:         price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeTollFree:          price = [rate[@"fixedPrice"]  floatValue]; break;
        case PhoneNumberTypeUan:               price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeVoiceMail:         price = [rate[@"mobilePrice"] floatValue]; break;
        case PhoneNumberTypeVoip:              price = [rate[@"fixedPrice"]  floatValue]; break;
    }

    return price;
}

@end
