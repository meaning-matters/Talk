//
//  NumberPayViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/07/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "NumberPayViewController.h"
#import "UIViewController+Common.h"
#import "PurchaseManager.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "Strings.h"


@interface NumberPayViewController () <NumberPayCellDelegate>

@property (nonatomic, assign) float          monthFee;
@property (nonatomic, assign) float          oneTimeFee;
@property (nonatomic, strong) NumberPayCell* payCell;
@property (nonatomic, assign) CGFloat        payCellHeight;

@end


@implementation NumberPayViewController

- (instancetype)initWithMonthFee:(float)monthFee oneTimeFee:(float)oneTimeFee
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        _monthFee   = monthFee;
        _oneTimeFee = oneTimeFee;
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


- (NSString*)oneTimeTitle
{
    // Dummy, must be overriden by superclass.
    return @"%@";
}


- (void)payNumber
{
    // Dummy, must be overriden by superclass.
}


- (void)leaveViewController
{
    // Dummy, must be overriden by superclass; either pop or dismiss.
}


#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:@"NumberPayCell" forIndexPath:indexPath];

    self.payCell = (NumberPayCell*)cell;
    self.payCell.delegate = self;
    [self updatePayCell];

    return cell;
}


- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Buy With Your Credit", @"");
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    title = NSLocalizedStringWithDefaultValue(@"NumberPay:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The fees will be taken from your Credit. If your Credit "
                                                  @"is too low, you'll be asked to buy more.",
                                                  @"[Multiple lines]");

    title = [NSString stringWithFormat:title, [self stringForFee:self.oneTimeFee]];

    return title;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.payCellHeight;
}


#pragma mark - Helpers

- (NSString*)stringForFee:(float)fee
{
    return [[PurchaseManager sharedManager] localizedFormattedPrice:fee];
}


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
                                                            @"%@ for %d month",
                                                            @"£2.34 for %d month");
        }
        else
        {
            monthsTitle = NSLocalizedStringWithDefaultValue(@"NumberPay MultipleMonthsFee", nil, [NSBundle mainBundle],
                                                            @"%@ for %d months",
                                                            @"£2.34 for 4 months");
        }

        monthsTitle  = [NSString stringWithFormat:monthsTitle, [self stringForFee:(months * self.monthFee)], months];
        oneTimeTitle = [NSString stringWithFormat:[self oneTimeTitle], [self stringForFee:self.oneTimeFee]];

        NSString* title = [NSString stringWithFormat:@"%@\n+ %@", monthsTitle, oneTimeTitle];

        [Common styleButton:button];
        [button setTitle:title forState:UIControlStateNormal];

        button.alpha                  = (self.payMonths != 0) ? 0.5 : 1.0;
        button.userInteractionEnabled = (self.payMonths == 0);
        (months == self.payMonths) ? [indicator startAnimating] : [indicator stopAnimating];
    }
}


#pragma mark - Number Pay Cell Delegate

- (void)payNumberForMonths:(int)months
{
    self.payMonths = months;
    [self updatePayCell];

    self.navigationItem.rightBarButtonItem.enabled = NO;

    // Check if there's enough credit.
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
    {
        float totalFee         = self.oneTimeFee + (self.monthFee * self.payMonths);
        NSString* creditString = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];
        NSString* totalString  = [[PurchaseManager sharedManager] localizedFormattedPrice:totalFee];

        if (error == nil)
        {
            if (totalFee < credit)
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedString(@"Buy With Your Credit", @"");
                message = NSLocalizedString(@"You have enough Credit to make this purchase.", @"");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    if (cancelled == NO)
                    {
                        [self payNumber];
                        [[AppDelegate appDelegate] checkCreditWithCompletion:nil];
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
                int extraCreditAmount = [[PurchaseManager sharedManager] amountForCredit:totalFee - credit];
                if (extraCreditAmount > 0)
                {
                    NSString* productIdentifier;
                    NSString* extraString;
                    NSString* title;
                    NSString* message;

                    productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditAmount:extraCreditAmount];
                    extraString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];

                    title   = NSLocalizedStringWithDefaultValue(@"PayNumber NeedExtraCreditTitle", nil,
                                                                [NSBundle mainBundle], @"Extra Credit Needed",
                                                                @"Alert title: extra credit must be bought.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"PayNumber NeedExtraCreditMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"The total price of %@ is more than your current "
                                                                @"Credit: %@.\n\nYou can buy the sufficient standard "
                                                                @"amount of %@ extra Credit now, or cancel to first "
                                                                @"increase your Credit from the Credit tab.",
                                                                @"Alert message: buying extra credit is needed.\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, totalString, creditString, extraString];
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
                                    [self payNumber];
                                    [[AppDelegate appDelegate] checkCreditWithCompletion:nil];
                                }
                                else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
                                {
                                    [self leaveViewController];
                                }
                                else if (object != nil)
                                {
                                    NSString* title;
                                    NSString* message;

                                    title   = NSLocalizedStringWithDefaultValue(@"PayNumber FailedBuyCreditTitle", nil,
                                                                                [NSBundle mainBundle], @"Buying Credit Failed",
                                                                                @"Alert title: Credit could not be bought.\n"
                                                                                @"[iOS alert title size].");
                                    message = NSLocalizedStringWithDefaultValue(@"PayNumber FailedBuyCreditMessage", nil,
                                                                                [NSBundle mainBundle],
                                                                                @"Something went wrong while buying Credit: "
                                                                                @"%@\n\nPlease try again later.",
                                                                                @"Message telling that buying credit failed\n"
                                                                                @"[iOS alert message size]");
                                    message = [NSString stringWithFormat:message, [object localizedDescription]];
                                    [BlockAlertView showAlertViewWithTitle:title
                                                                   message:message
                                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                                    {
                                        [self leaveViewController];
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
                    // There's no sufficiently high credit product.
                    NSString* title;
                    NSString* message;

                    title   = NSLocalizedStringWithDefaultValue(@"PayNumber ...Title", nil,
                                                                [NSBundle mainBundle], @"Not Enough Credit",
                                                                @"....\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"PayNumber ...Message", nil,
                                                                [NSBundle mainBundle],
                                                                @"Your Credit of %@ is not sufficient to cover the "
                                                                @"total price: %@.\n\n"
                                                                @"Please buy sufficient Credit and try again.",
                                                                @"...\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, creditString, totalString];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                     {
                         [self leaveViewController];
                     }
                                         cancelButtonTitle:[Strings closeString]
                                         otherButtonTitles:nil];
                }
            }
        }
        else
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"PayNumber FailedGetCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Credit Unknown",
                                                        @"Alert title: Reading the user's credit failed.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"PayNumber FailedGetCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Could not get your up-to-date Credit: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that paying a phone number failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self leaveViewController];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}

@end
