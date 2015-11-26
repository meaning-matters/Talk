//
//  CreditViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "CreditViewController.h"
#import "RatesViewController.h"
#import "PurchaseManager.h"
#import "CreditAmountCell.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"
#import "Skinning.h"


// Update reloadSections calls when adding/removing sections.
typedef enum
{
    TableSectionAmount = 1UL << 0,
    TableSectionRates  = 1UL << 1,
    TableSectionBuy    = 1UL << 2,
} TableSection;


@interface CreditViewController ()

@property (nonatomic, assign) float          amountCellHeight;
@property (nonatomic, assign) float          buyCellHeight;
@property (nonatomic, assign) BOOL           isLoadingCredit;
@property (nonatomic, assign) BOOL           loadingcreditFailed;
@property (nonatomic, assign) BOOL           mustShowLoadingError;
@property (nonatomic, strong) NSIndexPath*   amountIndexPath;
@property (nonatomic, strong) CreditBuyCell* buyCell;
@property (nonatomic, assign) int            buyTier;
@property (nonatomic, assign) TableSection   sections;
@property (nonatomic, strong) PhoneNumber*   callbackPhoneNumber;

@end


@implementation CreditViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = NSLocalizedString(@"Credit", @"Credit tab title");
        // The tabBarItem image must be set in my own NavigationController.

        self.sections |= TableSectionAmount;
        self.sections |= TableSectionRates;
        self.sections |= TableSectionBuy;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delaysContentTouches = NO;

    if (self.presentingViewController != nil)
    {
        // Shown as modal.
        UIBarButtonItem* barButtonItem;
        barButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                      target:self
                                                                      action:@selector(cancelAction)];
        self.navigationItem.rightBarButtonItem = barButtonItem;
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"CreditAmountCell" bundle:nil]
         forCellReuseIdentifier:@"CreditAmountCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"CreditBuyCell" bundle:nil]
         forCellReuseIdentifier:@"CreditBuyCell"];

    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell"];
    self.amountCellHeight = cell.bounds.size.height;
    self.buyCell          = [self.tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell"];
    self.buyCellHeight    = self.buyCell.bounds.size.height;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([Settings sharedSettings].haveAccount == YES)
    {
        self.mustShowLoadingError = NO;
        [self loadCredit];
    }

    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
        [self updateBuyCell];
    }];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [Common bitsSetCount:self.sections];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionAmount:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell" forIndexPath:indexPath];
            [self updateAmountCell:(CreditAmountCell*)cell];
            self.amountIndexPath = indexPath;
            break;
        }
        case TableSectionRates:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"RatesCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RatesCell"];
            }
            
            cell.imageView.image = [Common maskedImageNamed:@"RatesTab" color:[UIColor colorWithWhite:0.58f alpha:1.00f]];
            cell.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text  = NSLocalizedString(@"Rates", @"Rates cell title");
            break;
        }
        case TableSectionBuy:
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell" forIndexPath:indexPath];
            self.buyCell = (CreditBuyCell*)cell;
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
            break;
        }
    }

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionAmount:
        {
            title = NSLocalizedStringWithDefaultValue(@"creditView:... AmountHeader", nil, [NSBundle mainBundle],
                                                      @"Current Credit",
                                                      @"[One line larger font]");
            break;
        }
        case TableSectionRates:
        {
            title = nil;
            break;
        }
        case TableSectionBuy:
        {
            title = NSLocalizedStringWithDefaultValue(@"creditView:... BuyCreditHeader", nil, [NSBundle mainBundle],
                                                      @"Buy More Credit",
                                                      @"[One line larger font]");
            break;
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionAmount:
        {
            title = NSLocalizedStringWithDefaultValue(@"CreditAmount:... TableFooterNumbers", nil, [NSBundle mainBundle],
                                                      @"Credit is used for outgoing calls, for forwarding "
                                                      @"calls received on your Numbers, and for incoming "
                                                      @"call charges on your toll-free and special Numbers.",
                                                      @"[Multiple lines]");
            break;
        }
        case TableSectionRates:
        {
            title = nil;
            break;
        }
        case TableSectionBuy:
        {
            title = NSLocalizedStringWithDefaultValue(@"BuyCredit:... TableFooter", nil, [NSBundle mainBundle],
                                                      @"Credit you buy won't expire, and will be available immediately.",
                                                      @"[Multiple lines]");
            break;
        }
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionAmount:
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            if ([Settings sharedSettings].haveAccount == YES)
            {
                self.mustShowLoadingError = YES;
                [self loadCredit];
            }
            else
            {
                [Common showGetStartedViewController];
            }
            break;
        }
        case TableSectionRates:
        {
            RatesViewController* viewController = [[RatesViewController alloc] init];
            [self.navigationController pushViewController:viewController animated:YES];
            break;
        }
        case TableSectionBuy:
        {
            break;
        }
    }
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    CGFloat height;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionAmount: height = self.amountCellHeight; break;
        case TableSectionRates:  height = 45.0f;                 break;
        case TableSectionBuy:    height = self.buyCellHeight;    break;
    }

    return height;
}


#pragma mark - Actions

- (void)cancelAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - Helpers

- (void)loadCredit
{
    static BOOL isShowingLoadingError;

    [[PurchaseManager sharedManager] retryPendingTransactions];

    self.isLoadingCredit = YES;
    [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
    
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            [Settings sharedSettings].credit = credit;
            self.loadingcreditFailed = NO;
        }
        else
        {
            if (isShowingLoadingError == NO && self.mustShowLoadingError == YES)
            {
                NSString* title;
                NSString* message;
                NSString* string;

                title   = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedLoadCreditTitle", nil,
                                                            [NSBundle mainBundle], @"Loading Credit Failed",
                                                            @"Alert title: Credit could not be loaded.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedBuyCreditMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while loading your credit: "
                                                            @"%@\n\nPlease try again later.",
                                                            @"Message telling that buying credit failed\n"
                                                            @"[iOS alert message size]");
                string  = error.localizedDescription;
                message = [NSString stringWithFormat:message, string];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                    isShowingLoadingError = NO;
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];

                isShowingLoadingError = YES;
            }

            self.loadingcreditFailed = YES;
        }

        self.isLoadingCredit = NO;
        [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
    }];
}


#pragma mark - Credit Buy Cell Delegate

- (void)buyCreditForTier:(int)tier
{
    if ([Settings sharedSettings].haveAccount == NO)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"BuyCredit GetStartedTitle", nil, [NSBundle mainBundle],
                                                    @"Get Started First",
                                                    @"Alert title:\n"
                                                    @"[iOS alert title size]");

        message = NSLocalizedStringWithDefaultValue(@"BuyCredit GetStartedMessage", nil, [NSBundle mainBundle],
                                                    @"First buy a little initial credit, or restore "
                                                    @"if you're already a user.",
                                                    @"Alert message: ...\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             if (cancelled == NO)
             {
                 [Common showGetStartedViewController];
             }
         }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings okString], nil];

        return;
    }

    self.buyTier = tier;
    [self updateBuyCell];

    [[PurchaseManager sharedManager] buyCreditForTier:tier completion:^(BOOL success, id object)
    {
        if (success == YES)
        {
            [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            // Do nothing; give user another chance.
        }
        else if (object != nil)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedBuyCreditTitle", nil, [NSBundle mainBundle],
                                                        @"Buying Credit Failed",
                                                        @"Alert title: Credit could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedBuyCreditMessage", nil, [NSBundle mainBundle],
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

        self.buyTier = 0;
        [self updateBuyCell];
    }];
}


- (int)tierForN:(int)n
{
    int tier;
    switch (n)
    {
        case 0: tier =  1; break;
        case 1: tier =  2; break;
        case 2: tier =  5; break;
        case 3: tier = 10; break;
        case 4: tier = 20; break;
        case 5: tier = 50; break;
        case 6: tier = 60; break;
        case 7: tier = 72; break;
    }

    return tier;
}


- (UIButton*)buttonForN:(int)n
{
    UIButton* button;
    switch (n)
    {
        case 0: button = self.buyCell.button1;   break;
        case 1: button = self.buyCell.button2;   break;
        case 2: button = self.buyCell.button5;   break;
        case 3: button = self.buyCell.button10;  break;
        case 4: button = self.buyCell.button20;  break;
        case 5: button = self.buyCell.button50;  break;
        case 6: button = self.buyCell.button100; break;
        case 7: button = self.buyCell.button200; break;
    }

    return button;
}


- (UIActivityIndicatorView*)indicatorForN:(int)n
{
    UIActivityIndicatorView* indicator;
    switch (n)
    {
        case 0: indicator = self.buyCell.activityIndicator1;   break;
        case 1: indicator = self.buyCell.activityIndicator2;   break;
        case 2: indicator = self.buyCell.activityIndicator5;   break;
        case 3: indicator = self.buyCell.activityIndicator10;  break;
        case 4: indicator = self.buyCell.activityIndicator20;  break;
        case 5: indicator = self.buyCell.activityIndicator50;  break;
        case 6: indicator = self.buyCell.activityIndicator100; break;
        case 7: indicator = self.buyCell.activityIndicator200; break;
    }

    return indicator;
}


- (void)updateAmountCell:(CreditAmountCell*)cell
{
    float     credit = [Settings sharedSettings].credit;
    NSString* amount = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

    cell.amountLabel.text      = amount;
    cell.amountLabel.alpha     = self.isLoadingCredit ? 0.5 : 1.0;
    cell.amountLabel.textColor = self.loadingcreditFailed ? [Skinning deleteTintColor] : [Skinning tintColor];
    cell.amountLabel.highlightedTextColor = cell.amountLabel.textColor;

    cell.noteLabel.text        = NSLocalizedStringWithDefaultValue(@"BuyCredit ...", nil, [NSBundle mainBundle],
                                                                   @"not up-to-date",
                                                                   @"Alert title: Credit could not be bought.\n"
                                                                   @"[iOS alert title size].");
    cell.noteLabel.alpha       = self.loadingcreditFailed ? 1.0f : 0.0f;
    cell.noteLabel.textColor   = [Skinning deleteTintColor];

    if (self.isLoadingCredit == YES)
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


- (void)updateBuyCell
{
    for (int n = 0; n <= 7; n++)
    {
        int       tier              = [self tierForN:n];
        NSString* productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditTier:tier];
        NSString* priceString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];

        UIButton*                button    = [self buttonForN:n];
        UIActivityIndicatorView* indicator = [self indicatorForN:n];

        [Common styleButton:button];
        [button setTitle:priceString forState:UIControlStateNormal];

        button.alpha                  = (self.buyTier != 0) ? 0.5 : 1.0;
        button.userInteractionEnabled = (self.buyTier == 0);
        (tier == self.buyTier) ? [indicator startAnimating] : [indicator stopAnimating];
    }
}

@end
