//
//  BuyNumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "BuyNumberViewController.h"
#import "NumberBuyCell.h"
#import "Strings.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "Settings.h"


@interface BuyNumberViewController () <NumberBuyCellDelegate>

@property (nonatomic, strong) NSString*      name;
@property (nonatomic, strong) NSString*      isoCountryCode;
@property (nonatomic, strong) NSDictionary*  area;
@property (nonatomic, assign) NumberTypeMask numberTypeMask;
@property (nonatomic, strong) NSDictionary*  info;
@property (nonatomic, assign) float          buyCellHeight;
@property (nonatomic, strong) NumberBuyCell* buyCell;
@property (nonatomic, assign) int            buyMonths;
@property (nonatomic, assign) float          monthPrice;

@end


@implementation BuyNumberViewController

- (instancetype)initWithName:(NSString*)name
              isoCountryCode:(NSString*)isoCountryCode
                        area:(NSDictionary*)area
              numberTypeMask:(NumberTypeMask)numberTypeMask
                        info:(NSDictionary*)info
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... ViewTitle", nil, [NSBundle mainBundle],
                                                       @"Buy Number",
                                                       @"[ ].");

        self.name           = name;
        self.isoCountryCode = isoCountryCode;
        self.area           = area;
        self.numberTypeMask = numberTypeMask;
        self.info           = info;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delaysContentTouches = NO;

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberBuyCell" bundle:nil]
         forCellReuseIdentifier:@"NumberBuyCell"];

    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"NumberBuyCell"];
    self.buyCellHeight    = cell.bounds.size.height;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberBuyCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NumberBuyCell" forIndexPath:indexPath];
    self.buyCell = cell;
    self.buyCell.delegate = self;
    [self updateBuyCell];

    // Needed to remove button touch delay: http://stackoverflow.com/a/19671114/1971013
    for (id object in cell.subviews)
    {
        if ([object respondsToSelector:@selector(setDelaysContentTouches:)])
        {
            [object setDelaysContentTouches:NO];
        }
    }

    return cell;
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;
    float     setupFee = [self.area[@"setupFee"] floatValue];

    if (setupFee == 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... NoSetupFeeTableHeader", nil, [NSBundle mainBundle],
                                                  @"Fixed Price Per Month",
                                                  @"[Multiple lines]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableHeader", nil, [NSBundle mainBundle],
                                                  @"Includes A Setup Fee",
                                                  @"[Multiple lines]");
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;
    float     setupFee = [self.area[@"setupFee"] floatValue];

    if (setupFee == 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... NoSetupFeeTableFooter", nil, [NSBundle mainBundle],
                                                  @"The shown price will be taken from your credit.\n\n"
                                                  @"You can extend your number at any time.",
                                                  @"[Multiple lines]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The prices include a one-time setup fee of %@. The shown "
                                                  @"price will be taken from your credit.\n\n"
                                                  @"You can extend your number at any time.",
                                                  @"[Multiple lines]");

        title = [NSString stringWithFormat:title, [[PurchaseManager sharedManager] localizedFormattedPrice:setupFee]];
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.buyCellHeight;
}


#pragma mark - Number Buy Delegate

- (void)buyNumberForMonths:(int)months
{
    self.buyMonths   = months;
    float totalPrice = [self updateBuyCell];
    void (^buyNumberBlock)(void) = ^
    {
        BOOL allCities   = [[self.area objectForKey:@"areaName"] caseInsensitiveCompare:@"All cities"] == NSOrderedSame;
        BOOL hasAreaCode = [self.area[@"areaCode"] length] > 0;
        BOOL hasAreaName = self.numberTypeMask == NumberTypeGeographicMask && !allCities;

        [[WebClient sharedClient] purchaseNumberForMonths:months
                                                     name:self.name
                                           isoCountryCode:self.isoCountryCode
                                                 areaCode:hasAreaCode ? self.area[@"areaCode"] : nil
                                                 areaName:hasAreaName ? self.area[@"areaName"] : nil
                                                stateCode:self.area[@"stateCode"]
                                                stateName:self.area[@"stateName"]
                                               numberType:[NumberType stringForNumberType:self.numberTypeMask]
                                                     info:self.info
                                                    reply:^(NSError* error, NSString *e164)
        {
            if (error == nil)
            {
                [[AppDelegate appDelegate].numbersViewController refresh:nil];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberTitle", nil,
                                                            [NSBundle mainBundle], @"Buying Number Failed",
                                                            @"Alert title: A phone number could not be bought.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while buying your number: %@.\n\n"
                                                            @"Please try again later.",
                                                            @"Message telling that buying a phone number failed\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, [error localizedDescription]];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    };

    // Check if there's enough credit.
    [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                      reply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            if (totalPrice < credit)
            {
                buyNumberBlock();
            }
            else
            {
                int extraCreditTier = [[PurchaseManager sharedManager] tierForCredit:totalPrice - credit];
                if (extraCreditTier > 0)
                {
                    NSString* productIdentifier;
                    NSString* extraString;
                    NSString* creditString;
                    NSString* title;
                    NSString* message;

                    productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditTier:extraCreditTier];
                    extraString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
                    creditString      = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditTitle", nil,
                                                                [NSBundle mainBundle], @"Extra Credit Needed",
                                                                @"Alert title: extra credit must be bought.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"The price is more than your current "
                                                                @"credit: %@.\nYou can buy %@ extra credit now.",
                                                                @"Alert message: buying extra credit id needed.\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, creditString, extraString];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (cancelled == NO)
                        {
                            [[PurchaseManager sharedManager] buyCreditForTier:extraCreditTier
                                                                   completion:^(BOOL success, id object)
                            {
                                if (success == YES)
                                {
                                    buyNumberBlock();
                                }
                                else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                                {
                                    [self dismissViewControllerAnimated:YES completion:nil];
                                }
                                else if (object != nil)
                                {
                                    NSString* title;
                                    NSString* message;

                                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyCreditTitle", nil,
                                                                                [NSBundle mainBundle], @"Buying Credit Failed",
                                                                                @"Alert title: Credit could not be bought.\n"
                                                                                @"[iOS alert title size].");
                                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyCreditMessage", nil,
                                                                                [NSBundle mainBundle],
                                                                                @"Something went wrong while buying credit: "
                                                                                @"%@.\n\nPlease try again later.",
                                                                                @"Message telling that buying credit failed\n"
                                                                                @"[iOS alert message size]");
                                    message = [NSString stringWithFormat:message, [object localizedDescription]];
                                    [BlockAlertView showAlertViewWithTitle:title
                                                                   message:message
                                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                                    {
                                        [self dismissViewControllerAnimated:YES completion:nil];
                                    }
                                                         cancelButtonTitle:[Strings closeString]
                                                         otherButtonTitles:nil];
                                }
                            }];
                        }
                        else
                        {
                            [self dismissViewControllerAnimated:YES completion:nil];
                        }
                    }
                                         cancelButtonTitle:[Strings cancelString]
                                         otherButtonTitles:[Strings buyString], nil];
                }
                else
                {
                    NBLog(@"//### Apparently there's no sufficiently high credit product.");
                }
            }
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Credit Unknown",
                                                        @"Alert title: Reading the user's credit failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Could not get your up-to-date credit, from our "
                                                        @"internet server. (Credit is needed for the "
                                                        @"setup fee.)\n\nPlease try again later.",
                                                        @"Message telling that buying a phone number failed\n"
                                                        @"[iOS alert message size]");
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


#pragma mark - Helpers

- (int)monthsForN:(int)n
{
    int months;
    switch (n)
    {
        case 0: months =  1; break;
        case 1: months =  2; break;
        case 2: months =  3; break;
        case 3: months =  6; break;
        case 4: months =  9; break;
        case 5: months = 12; break;
    }

    return months;
}


- (UIButton*)buttonForN:(int)n
{
    UIButton* button;
    switch (n)
    {
        case 0: button = self.buyCell.button1;  break;
        case 1: button = self.buyCell.button2;  break;
        case 2: button = self.buyCell.button3;  break;
        case 3: button = self.buyCell.button6;  break;
        case 4: button = self.buyCell.button9;  break;
        case 5: button = self.buyCell.button12; break;
    }

    return button;
}


- (UIActivityIndicatorView*)indicatorForN:(int)n
{
    UIActivityIndicatorView* indicator;
    switch (n)
    {
        case 0: indicator = self.buyCell.activityIndicator1;  break;
        case 1: indicator = self.buyCell.activityIndicator2;  break;
        case 2: indicator = self.buyCell.activityIndicator3;  break;
        case 3: indicator = self.buyCell.activityIndicator6;  break;
        case 4: indicator = self.buyCell.activityIndicator9;  break;
        case 5: indicator = self.buyCell.activityIndicator12; break;
    }

    return indicator;
}


- (float)updateBuyCell
{
    float setupFee   = [self.area[@"setupFee"]   floatValue];
    float monthPrice = [self.area[@"monthPrice"] floatValue];
    float totalPrice = 0.0f;

    for (int n = 0; n <= 5; n++)
    {
        int       months           = [self monthsForN:n];
        float     monthsPrice      = months * monthPrice;
        NSString* totalPriceString = [[PurchaseManager sharedManager] localizedFormattedPrice:setupFee + monthsPrice];
        NSString* monthsString     = (months == 1) ? [Strings monthString] : [Strings monthsString];
        NSString* title            = [NSString stringWithFormat:@"%d %@ %@", months, monthsString, totalPriceString];

        UIButton*                button    = [self buttonForN:n];
        UIActivityIndicatorView* indicator = [self indicatorForN:n];

        [button setTitle:title forState: UIControlStateNormal];
        [Common styleButton:button];

        button.alpha                  = (self.buyMonths != 0) ? 0.5 : 1.0;
        button.userInteractionEnabled = (self.buyMonths == 0);
        (months == self.buyMonths) ? [indicator startAnimating] : [indicator stopAnimating];

        if (months == self.buyMonths)
        {
            totalPrice = setupFee + monthsPrice;
        }
    }

    return totalPrice;
}

@end
