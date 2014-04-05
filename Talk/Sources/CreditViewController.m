//
//  CreditViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CreditViewController.h"
#import "PurchaseManager.h"
#import "CreditAmountCell.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"
#import "Skinning.h"


@interface CreditViewController ()

@property (nonatomic, assign) float          creditAmountCellHeight;
@property (nonatomic, assign) float          creditBuyCellHeight;
@property (nonatomic, assign) BOOL           isLoadingCredit;
@property (nonatomic, assign) BOOL           loadingcreditFailed;
@property (nonatomic, strong) NSIndexPath*   amountIndexPath;
@property (nonatomic, strong) CreditBuyCell* buyCell;
@property (nonatomic, assign) int            buyTier;

@end


@implementation CreditViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
        //if (self = [super initWithNibName:@"CreditView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Credit", @"Credit tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"CreditTab.png"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

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

    UITableViewCell* cell       = [self.tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell"];
    self.creditAmountCellHeight = cell.bounds.size.height;
    self.buyCell                = [self.tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell"];
    self.creditBuyCellHeight    = self.buyCell.bounds.size.height;

    self.tableView.delaysContentTouches = NO;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    //self.tableView.delaysContentTouches = NO;

    if ([Settings sharedSettings].haveAccount == YES)
    {
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
    return 2;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if (indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell" forIndexPath:indexPath];
        [self updateAmountCell:(CreditAmountCell*)cell];
        self.amountIndexPath = indexPath;
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell" forIndexPath:indexPath];
        self.buyCell = (CreditBuyCell*)cell;
        self.buyCell.delegate = self;
        [self updateBuyCell];
    }

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


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title;

    if (section == 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"creditView:... AmountHeader", nil, [NSBundle mainBundle],
                                                  @"Current Credit",
                                                  @"[One line larger font]");
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"creditView:... BuyCreditHeader", nil, [NSBundle mainBundle],
                                                  @"Buy More Credit",
                                                  @"[One line larger font]");
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title;

    if (section == 0)
    {
#if HAS_BUYING_NUMBERS
        title = NSLocalizedStringWithDefaultValue(@"CreditAmount:... TableFooterNumbers", nil, [NSBundle mainBundle],
                                                  @"Credit is used for outgoing calls, for forwarding incoming "
                                                  @"calls on NumberBay numbers to your phone(s), and for the setup "
                                                  @"fee when buying some of the numbers.",
                                                  @"[Multiple lines]");
#else
        title = NSLocalizedStringWithDefaultValue(@"CreditAmount:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"Credit is used for the two parts of each call: calling back "
                                                  @"your number, and calling the other person.",
                                                  @"[Multiple lines]");
#endif
    }
    else
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyCredit:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The credit you buy will be available immediately.",
                                                  @"[Multiple lines]");
    }

    return title;
}


#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == 0 && indexPath.row == 0)
    {
        if ([Settings sharedSettings].haveAccount == YES)
        {
            [self loadCredit];
        }
        else
        {
            [Common showGetStartedViewController];
        }
    }
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0)
    {
        [self updateAmountCell:(CreditAmountCell*)cell];
    }
    else
    {
        [self updateBuyCell];
    }
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (indexPath.section == 0)
    {
        return self.creditAmountCellHeight;
    }
    else
    {
        return self.creditBuyCellHeight;
    }
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

    self.isLoadingCredit = YES;
    [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
    
    [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                      reply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            [Settings sharedSettings].credit = credit;
            self.loadingcreditFailed = NO;
        }
        else
        {
            if (isShowingLoadingError == NO)
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

            title   = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedBuyCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Buying Credit Failed",
                                                        @"Alert title: Credit could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"BuyCredit FailedBuyCreditMessage", nil,
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
    }

    return tier;
}


- (UIButton*)buttonForN:(int)n
{
    UIButton* button;
    switch (n)
    {
        case 0: button = self.buyCell.button1;  break;
        case 1: button = self.buyCell.button2;  break;
        case 2: button = self.buyCell.button5;  break;
        case 3: button = self.buyCell.button10; break;
        case 4: button = self.buyCell.button20; break;
        case 5: button = self.buyCell.button50; break;
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
        case 2: indicator = self.buyCell.activityIndicator5;  break;
        case 3: indicator = self.buyCell.activityIndicator10; break;
        case 4: indicator = self.buyCell.activityIndicator20; break;
        case 5: indicator = self.buyCell.activityIndicator50; break;
    }

    return indicator;
}


- (void)updateAmountCell:(CreditAmountCell*)cell
{
    float     credit = [Settings sharedSettings].credit;
    NSString* amount = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];

    cell.amountLabel.text  = amount;
    cell.amountLabel.alpha = self.isLoadingCredit ? 0.5 : 1.0;

    cell.amountLabel.textColor = self.loadingcreditFailed ? [UIColor orangeColor] : [UIColor blackColor];
    
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
    //self.buyCell = (CreditBuyCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];

    for (int n = 0; n <= 5; n++)
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
