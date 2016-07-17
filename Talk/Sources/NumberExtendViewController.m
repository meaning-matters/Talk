//
//  NumberExtendViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 13/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberExtendViewController.h"
#import "NumberPayCell.h"
#import "UIViewController+Common.h"
#import "PurchaseManager.h"
#import "Common.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"
#import "DataManager.h"


@interface NumberExtendViewController () <NumberPayCellDelegate>

@property (nonatomic, strong) NumberData*    number;
@property (nonatomic, copy) void (^completion)(void);
@property (nonatomic, strong) NumberPayCell* payCell;
@property (nonatomic, assign) CGFloat        payCellHeight;
@property (nonatomic, assign) int            payMonths;

@end


@implementation NumberExtendViewController

- (instancetype)initWithNumber:(NumberData*)number completion:(void (^)(void))completion
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.number     = number;
        self.completion = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerNib:[UINib nibWithNibName:@"NumberPayCell" bundle:nil]
         forCellReuseIdentifier:@"NumberPayCell"];

    self.payCell       = [self.tableView dequeueReusableCellWithIdentifier:@"NumberPayCell"];
    self.payCellHeight = self.payCell.bounds.size.height;

    [self setupFootnotesHandlingOnTableView:self.tableView];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NumberPayCell" forIndexPath:indexPath];

    self.payCell = (NumberPayCell*)cell;
    self.payCell.delegate = self;
    [self updatePayCell];

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if (self.number.renewFee == 0.0f)
    {
        title = NSLocalizedStringWithDefaultValue(@"NumberPay:... NooneTimeFeeTableFooter", nil, [NSBundle mainBundle],
                                                  @"The fee will be taken from your Credit. If your Credit "
                                                  @"is too low, you'll be asked to buy more.",
                                                  @"[Multiple lines]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"NumberPay:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The fee(s) will be taken from your Credit. If your Credit "
                                                  @"is too low, you'll be asked to buy more.",
                                                  @"[Multiple lines]");

        title = [NSString stringWithFormat:title, [self stringForFee:self.number.renewFee]];
    }

    return title;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.payCellHeight;
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
        case 3: months =  4; break;
        case 4: months =  6; break;
        case 5: months =  9; break;
        case 6: months = 12; break;
    }

    return months;
}


- (UIButton*)buttonForN:(int)n
{
    UIButton* button;
    switch (n)
    {
        case 0: button = self.payCell.button1;  break;
        case 1: button = self.payCell.button2;  break;
        case 2: button = self.payCell.button3;  break;
        case 3: button = self.payCell.button4;  break;
        case 4: button = self.payCell.button6;  break;
        case 5: button = self.payCell.button9;  break;
        case 6: button = self.payCell.button12; break;
    }

    return button;
}


- (UIActivityIndicatorView*)indicatorForN:(int)n
{
    UIActivityIndicatorView* indicator;
    switch (n)
    {
        case 0: indicator = self.payCell.activityIndicator1;  break;
        case 1: indicator = self.payCell.activityIndicator2;  break;
        case 2: indicator = self.payCell.activityIndicator3;  break;
        case 3: indicator = self.payCell.activityIndicator4;  break;
        case 4: indicator = self.payCell.activityIndicator6;  break;
        case 5: indicator = self.payCell.activityIndicator9;  break;
        case 6: indicator = self.payCell.activityIndicator12; break;
    }

    return indicator;
}


- (void)updatePayCell
{
    for (int n = 0; n <= 6; n++)
    {
        int                      months    = [self monthsForN:n];
        UIButton*                button    = [self buttonForN:n];
        UIActivityIndicatorView* indicator = [self indicatorForN:n];
        NSString*                monthsTitle;
        NSString*                oneTimeTitle;

        if (months == 1)
        {
            monthsTitle = NSLocalizedStringWithDefaultValue(@"NumberPay OneMonthFee", nil, [NSBundle mainBundle],
                                                            @"%@ for 1 month",
                                                            @"£2.34 for 1 month");
        }
        else
        {
            monthsTitle = NSLocalizedStringWithDefaultValue(@"NumberPay MultipleMonthsFee", nil, [NSBundle mainBundle],
                                                            @"%@ for %d months",
                                                            @"£2.34 for 4 months");
        }

        monthsTitle = [NSString stringWithFormat:monthsTitle, [self stringForFee:(months * self.number.monthFee)], months];
        oneTimeTitle = NSLocalizedStringWithDefaultValue(@"NumberPay ...", nil, [NSBundle mainBundle],
                                                         @"%@ extend fee",
                                                         @"£2.34 extend fee");
        oneTimeTitle = [NSString stringWithFormat:oneTimeTitle, [self stringForFee:self.number.renewFee]];

        NSString* title = [NSString stringWithFormat:@"%@\n%@", monthsTitle, oneTimeTitle];

        [Common styleButton:button];
        [button setTitle:title forState:UIControlStateNormal];

        button.alpha                  = (self.payMonths != 0) ? 0.5 : 1.0;
        button.userInteractionEnabled = (self.payMonths == 0);
        (months == self.payMonths) ? [indicator startAnimating] : [indicator stopAnimating];
    }
}


- (NSString*)stringForFee:(float)fee
{
    return [[PurchaseManager sharedManager] localizedFormattedPrice:fee];
}


#pragma mark - Number Pay Cell Delegate

- (void)payNumberForMonths:(int)months
{
    self.payMonths = months;
    self.navigationItem.rightBarButtonItem.enabled = NO;
    [self updatePayCell];
    void (^payNumberBlock)(void) = ^
    {
        [[WebClient sharedClient] extendNumberE164:self.number.e164
                                         forMonths:months
                                             reply:^(NSError* error,
                                                     float    monthFee,
                                                     float    renewFee,
                                                     NSDate*  expiryDate)
        {
            if (error == nil)
            {
                self.number.monthFee   = monthFee;
                self.number.renewFee   = renewFee;
                self.number.expiryDate = expiryDate;

                [[DataManager sharedManager] saveManagedObjectContext:nil];

                self.completion ? self.completion() : 0;

                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberTitle", nil,
                                                            [NSBundle mainBundle], @"Extending Number Failed",
                                                            @"Alert title: A phone number could not be bought.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyNumber FailedBuyNumberMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while extending your number: %@\n\n"
                                                            @"Please try again later.",
                                                            @"Message telling that extending a phone number failed\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, [error localizedDescription]];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    };

    // Check if there's enough credit.
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
    {
        float totalFee = self.number.renewFee + (self.number.monthFee * self.payMonths);
        if (error == nil)
        {
            if (totalFee < credit)
            {
                payNumberBlock();
            }
            else
            {
                int extraCreditAmount = [[PurchaseManager sharedManager] amountForCredit:totalFee - credit];
                if (extraCreditAmount > 0)
                {
                    NSString* productIdentifier;
                    NSString* extraString;
                    NSString* creditString;
                    NSString* title;
                    NSString* message;

                    productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditAmount:extraCreditAmount];
                    extraString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];
                    creditString      = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

                    title   = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditTitle", nil,
                                                                [NSBundle mainBundle], @"Extra Credit Needed",
                                                                @"Alert title: extra credit must be bought.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"BuyNumber NeedExtraCreditMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"The price is more than your current "
                                                                @"credit: %@.\n\nYou can buy %@ extra credit now.",
                                                                @"Alert message: buying extra credit id needed.\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, creditString, extraString];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        if (cancelled == NO)
                        {
                            [[PurchaseManager sharedManager] buyCreditAmount:extraCreditAmount
                                                                  completion:^(BOOL success, id object)
                            {
                                if (success == YES)
                                {
                                    payNumberBlock();
                                }
                                else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                                {
                                    [self.navigationController popViewControllerAnimated:YES];
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
                                                                                @"%@\n\nPlease try again later.",
                                                                                @"Message telling that buying credit failed\n"
                                                                                @"[iOS alert message size]");
                                    message = [NSString stringWithFormat:message, [object localizedDescription]];
                                    [BlockAlertView showAlertViewWithTitle:title
                                                                   message:message
                                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                                    {
                                        [self.navigationController popViewControllerAnimated:YES];
                                    }
                                                         cancelButtonTitle:[Strings closeString]
                                                         otherButtonTitles:nil];
                                }
                            }];
                        }
                        else
                        {
                            self.payMonths = 0;
                            self.navigationItem.rightBarButtonItem.enabled = YES;
                            [self updatePayCell];
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
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}

@end
