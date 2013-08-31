//
//  BuyNumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "BuyNumberViewController.h"
#import "BuyNumberCell.h"
#import "Strings.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "Settings.h"


@interface BuyNumberViewController ()

@property (nonatomic, strong) NSString*     name;
@property (nonatomic, strong) NSString*     isoCountryCode;
@property (nonatomic, strong) NSDictionary* area;
@property (nonatomic, strong) NSString*     numberType;
@property (nonatomic, strong) NSDictionary* info;
@property (nonatomic, strong) NSIndexPath*  buyIndexPath;

@end


@implementation BuyNumberViewController

- (id)initWithName:(NSString*)name
    isoCountryCode:(NSString*)isoCountryCode
              area:(NSDictionary*)area
    numberTypeMask:(NumberTypeMask)numberTypeMask
              info:(NSDictionary*)info
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... ViewTitle", nil,
                                                       [NSBundle mainBundle],
                                                       @"Buy Number",
                                                       @"[ ].");

        self.name           = name;
        self.isoCountryCode = isoCountryCode;
        self.area           = area;
        self.numberType     = [NumberType stringForNumberType:numberTypeMask];
        self.info           = info;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"BuyNumberCell" bundle:nil]
         forCellReuseIdentifier:@"BuyNumberCell"];

    self.clearsSelectionOnViewWillAppear = NO;

    UITableViewCell* cell    = [self.tableView dequeueReusableCellWithIdentifier:@"BuyNumberCell"];
    self.tableView.rowHeight = cell.bounds.size.height;
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self tierForMonths:12] > 0)
    {
        return 6;
    }
    else if ([self tierForMonths:9] > 0)
    {
        return 5;
    }
    else if ([self tierForMonths:6] > 0)
    {
        return 4;
    }
    else if ([self tierForMonths:3] > 0)
    {
        return 3;
    }
    else if ([self tierForMonths:2] > 0)
    {
        return 2;
    }
    else if ([self tierForMonths:1] > 0)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    BuyNumberCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BuyNumberCell" forIndexPath:indexPath];

    return cell;
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

    title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableHeader", nil, [NSBundle mainBundle],
                                              @"Select Initial Duration",
                                              @"[Multiple lines]");

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if ([self tableView:tableView numberOfRowsInSection:0] == 6)
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The setup fee will be taken from your credit.",
                                                  @"[Multiple lines]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The setup fee will be taken from your credit.\n"
                                                  @"Due to the high price, not all durations are currently available.",
                                                  @"[Multiple lines]");
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.buyIndexPath == nil)
    {        
        int   numberTier = [self tierForMonths:[self monthsForIndexPath:indexPath]];
        int   months     = [self monthsForIndexPath:indexPath];
        float setupFee   = [self.area[@"setupFee"] floatValue];

        self.buyIndexPath = indexPath;
        [self updateVisibleCells];

        void (^buyNumberBlock)(void) = ^
        {
            [[PurchaseManager sharedManager] buyNumberForTier:numberTier
                                                       months:months
                                                         name:self.name
                                               isoCountryCode:self.isoCountryCode
                                                     areaCode:self.area[@"areaCode"]
                                                   numberType:self.numberType
                                                         info:self.info
                                                   completion:^(BOOL success, id object)
            {
                self.buyIndexPath = nil;
                [self updateVisibleCells];

                if (success == YES)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else if (object != nil)
                {
                    NSString* title;
                    NSString* message;

                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberTitle", nil,
                                                                [NSBundle mainBundle], @"Buying Number Failed",
                                                                @"Alart title: A phone number could not be bought.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Something went wrong while buying your number: %@.\n\n"
                                                                @"Please try again later.",
                                                                @"Message telling that buying a phone number failed\n"
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
        };
        
        if (setupFee > 0)
        {
            [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                              reply:^(WebClientStatus status, id content)
            {
                if (status == WebClientStatusOk)
                {
                    float credit = [content[@"credit"] floatValue];

                    if (setupFee < credit)
                    {
                        buyNumberBlock();
                    }
                    else
                    {
                        int extraCreditTier = [[PurchaseManager sharedManager] tierForCredit:setupFee - credit];
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
                                                                        @"Alart title: extra credit must be bought.\n"
                                                                        @"[iOS alert title size].");
                            message = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditMessage", nil,
                                                                        [NSBundle mainBundle],
                                                                        @"The setup fee is more than your current "
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
                                                                                        @"Alart title: Credit could not be bought.\n"
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
                            NSLog(@"//### Apparently there's no sufficiently high credit product.");
                        }
                    }
                }
                else
                {
                    NSString* title;
                    NSString* message;

                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditTitle", nil,
                                                                [NSBundle mainBundle], @"Up-to-date Credit Unknown",
                                                                @"Alart title: Reading the user's credit failed.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedGetCreditMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Could not get your up-to-date credit, from our "
                                                                @"internet server.  (Credit is needed for the "
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
        else
        {
            buyNumberBlock();
        }
    }
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self updateCell:(BuyNumberCell*)cell atIndexPath:indexPath];
}


#pragma mark - Helpers

- (int)monthsForIndexPath:(NSIndexPath*)indexPath
{
    int months;
    switch (indexPath.row)
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


- (int)tierForMonths:(int)months
{
    int tier;
    switch (months)
    {
        case  1: tier = [[self.area objectForKey:@"oneMonthTier"]    intValue]; break;
        case  2: tier = [[self.area objectForKey:@"twoMonthTier"]    intValue]; break;
        case  3: tier = [[self.area objectForKey:@"threeMonthTier"]  intValue]; break;
        case  6: tier = [[self.area objectForKey:@"sixMonthTier"]    intValue]; break;
        case  9: tier = [[self.area objectForKey:@"nineMonthTier"]   intValue]; break;
        case 12: tier = [[self.area objectForKey:@"twelveMonthTier"] intValue]; break;
    }

    return (1 <= tier && tier <= 87) ? tier : 0;
}


- (void)updateCell:(BuyNumberCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    float setupFee = [[self.area objectForKey:@"setupFee"] floatValue];
    int   months   = [self monthsForIndexPath:indexPath];
    int   tier     = [self tierForMonths:months];

    NSString* productIdentifier = [[PurchaseManager sharedManager] productIdentifierForNumberTier:tier];
    NSString* priceString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
    NSString* text;
    text = NSLocalizedStringWithDefaultValue(@"BuyNumber:... PriceLabel", nil, [NSBundle mainBundle],
                                             @"%d %@ for %@",
                                             @"Parameters are: number of months (1, 2, 3, ...), "
                                             @"the word 'month' in singular or plural, "
                                             @"the price (including currency sign).");
    text = [NSString stringWithFormat:text,
            months,
            [Common capitalizedString:(months == 1) ? [Strings monthString] : [Strings monthsString]],
            priceString];

    cell.durationImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"NumberDuration%d.png", months]];
    cell.monthsLabel.text = text;

    if (setupFee == 0)
    {
        text = NSLocalizedStringWithDefaultValue(@"BuyNumber:... ZeroSetupFeeLabel", nil, [NSBundle mainBundle],
                                                 @"No setup fee!",
                                                 @"[One line]");
    }
    else
    {
        text = NSLocalizedStringWithDefaultValue(@"BuyNumber:... SetupFeeLabel", nil, [NSBundle mainBundle],
                                                 @"plus a setup fee of %@",
                                                 @"[One line]");
    }

    text = [NSString stringWithFormat:text, [[PurchaseManager sharedManager] localizedFormattedPrice:setupFee]];
    cell.setupLabel.text = text;

    cell.durationImageView.alpha = self.buyIndexPath ? 0.5 : 1.0;
    cell.monthsLabel.alpha       = self.buyIndexPath ? 0.5 : 1.0;
    cell.setupLabel.alpha        = self.buyIndexPath ? 0.5 : 1.0;
    if (self.buyIndexPath != nil && [self.buyIndexPath compare:indexPath] == NSOrderedSame)
    {
        [cell.activityIndicator startAnimating];
        cell.userInteractionEnabled = NO;
    }
    else
    {
        [cell.activityIndicator stopAnimating];
        cell.userInteractionEnabled = YES;
    }
}


- (void)updateVisibleCells
{
    for (NSIndexPath* indexPath in [self.tableView indexPathsForVisibleRows])
    {
        BuyNumberCell* cell = (BuyNumberCell*)[self.tableView cellForRowAtIndexPath:indexPath];

        [self updateCell:cell atIndexPath:indexPath];
    }
}

@end
