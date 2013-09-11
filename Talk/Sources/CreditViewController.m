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
#import "CreditBuyCell.h"
#import "Settings.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Common.h"


@interface CreditViewController ()

@property (nonatomic, assign) float         creditAmountCellHeight;
@property (nonatomic, assign) float         creditBuyCellHeight;
@property (nonatomic, assign) BOOL          isLoadingCredit;
@property (nonatomic, assign) BOOL          loadingcreditFailed;
@property (nonatomic, strong) NSIndexPath*  amountIndexPath;
@property (nonatomic, strong) NSIndexPath*  buyIndexPath;

@end


@implementation CreditViewController

- (id)init
{
    if (self = [super initWithNibName:@"CreditView" bundle:nil])
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
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                               target:self
                                                                                               action:@selector(cancelAction)];
    }

    [self.tableView registerNib:[UINib nibWithNibName:@"CreditAmountCell" bundle:nil]
         forCellReuseIdentifier:@"CreditAmountCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"CreditBuyCell" bundle:nil]
         forCellReuseIdentifier:@"CreditBuyCell"];

    UITableViewCell* cell;
    cell                        = [self.tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell"];
    self.creditAmountCellHeight = cell.bounds.size.height;
    cell                        = [self.tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell"];
    self.creditBuyCellHeight    = cell.bounds.size.height;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if ([Settings sharedSettings].hasAccount == YES)
    {
        [self loadCredit];
    }

    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
        [self updateVisibleBuyCells];
    }];
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 2;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return section == 0 ? 1 : 6;
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
        [self updateBuyCell:(CreditBuyCell*)cell atIndexPath:indexPath];
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
        title = NSLocalizedStringWithDefaultValue(@"CreditAmount:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"Credit is used for outgoing calls, for forwarding incoming "
                                                  @"calls on NumberBay numbers to your phone(s), and for the setup "
                                                  @"fee when buying some of the numbers.",
                                                  @"[Multiple lines]");
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
        if ([Settings sharedSettings].hasAccount == YES)
        {
            [self loadCredit];
        }
    }
    else
    {
        if ([Settings sharedSettings].hasAccount == YES)
        {
            [self buyCreditForIndexPath:indexPath];
        }
        else
        {
            [Common showProvisioningViewController];
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
        [self updateBuyCell:(CreditBuyCell*)cell atIndexPath:indexPath];
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
    self.isLoadingCredit = YES;
    [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
    
    [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                      reply:^(WebClientStatus status, id content)
    {
        if (status == WebClientStatusOk)
        {
            [Settings sharedSettings].credit = [content[@"credit"] floatValue];
            self.loadingcreditFailed = NO;
        }
        else
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
                                                        @"%@.\n\nPlease try again later.",
                                                        @"Message telling that buying credit failed\n"
                                                        @"[iOS alert message size]");
            string = [WebClient localizedStringForStatus:status];
            message = [NSString stringWithFormat:message, string];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
             {
                 [self dismissViewControllerAnimated:YES completion:nil];
             }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];

            self.loadingcreditFailed = YES;
        }

        self.isLoadingCredit = NO;
        [self updateAmountCell:(CreditAmountCell*)[self.tableView cellForRowAtIndexPath:self.amountIndexPath]];
    }];
}


- (void)buyCreditForIndexPath:(NSIndexPath*)indexPath
{
    self.buyIndexPath = indexPath;
    [self updateVisibleBuyCells];

    [[PurchaseManager sharedManager] buyCreditForTier:[self tierForIndexPath:self.buyIndexPath]
                                           completion:^(BOOL success, id object)
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

        self.buyIndexPath = nil;
        [self updateVisibleBuyCells];
    }];
}


- (int)tierForIndexPath:(NSIndexPath*)indexPath
{
    int tier;
    switch (indexPath.row)
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


- (void)updateBuyCell:(CreditBuyCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    int       tier              = [self tierForIndexPath:indexPath];
    NSString* productIdentifier = [[PurchaseManager sharedManager] productIdentifierForCreditTier:tier];
    NSString* priceString       = [[PurchaseManager sharedManager] localizedPriceForProductIdentifier:productIdentifier];

    NSString* description;
    description = NSLocalizedStringWithDefaultValue(@"CreditView DescriptionLabel", nil, [NSBundle mainBundle],
                                                    @"A Credit of %@",
                                                    @"Parameter: credit amount local currency.");

    cell.descriptionLabel.text  = [NSString stringWithFormat:description, priceString];
    cell.amountImageView.image  = [UIImage imageNamed:[NSString stringWithFormat:@"CreditAmount%d.png", tier]];

    cell.amountImageView.alpha  = self.buyIndexPath ? 0.5 : 1.0;
    cell.descriptionLabel.alpha = self.buyIndexPath ? 0.5 : 1.0;
    cell.userInteractionEnabled = self.buyIndexPath ? NO  : YES;
    if (self.buyIndexPath != nil && [self.buyIndexPath compare:indexPath] == NSOrderedSame)
    {
        [cell.activityIndicator startAnimating];
    }
    else
    {
        [cell.activityIndicator stopAnimating];
    }
}


- (void)updateVisibleBuyCells
{
    for (NSIndexPath* indexPath in [self.tableView indexPathsForVisibleRows])
    {
        if ([indexPath isEqual:self.amountIndexPath] == NO)
        {
            CreditBuyCell* cell = (CreditBuyCell*)[self.tableView cellForRowAtIndexPath:indexPath];
            [self updateBuyCell:cell atIndexPath:indexPath];
        }
    }
}

@end
