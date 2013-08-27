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


@interface CreditViewController ()

@property (nonatomic, assign) float CreditAmountCellHeight;
@property (nonatomic, assign) float CreditBuyCellHeight;

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

    [self.tableView registerNib:[UINib nibWithNibName:@"CreditAmountCell" bundle:nil]
         forCellReuseIdentifier:@"CreditAmountCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"CreditBuyCell" bundle:nil]
         forCellReuseIdentifier:@"CreditBuyCell"];

    UITableViewCell* cell;
    cell                        = [self.tableView dequeueReusableCellWithIdentifier:@"CreditAmountCell"];
    self.CreditAmountCellHeight = cell.bounds.size.height;
    cell                        = [self.tableView dequeueReusableCellWithIdentifier:@"CreditBuyCell"];
    self.CreditBuyCellHeight    = cell.bounds.size.height;
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
                                                  @"Credit is used for your outgoing calls, for forwarding incoming "
                                                  @"calls on your NumberBay numbers to your phone, and for the setup "
                                                  @"fee when buying some of the NumberBay (mostly toll-free) numbers.",
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

    if (indexPath.row == 0)
    {
        
    }
    else
    {

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
        return self.CreditAmountCellHeight;
    }
    else
    {
        return self.CreditBuyCellHeight;
    }
}


#pragma mark - Helpers

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

    cell.amountLabel.text = amount;
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

    cell.descriptionLabel.text = [NSString stringWithFormat:description, priceString];
}

@end
