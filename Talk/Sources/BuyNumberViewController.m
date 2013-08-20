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


@interface BuyNumberViewController ()

@end


@implementation BuyNumberViewController

- (id)initWithArea:(NSDictionary*)area
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.area = area;
        self.title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... ViewTitle", nil,
                                                       [NSBundle mainBundle],
                                                       @"Buy Number",
                                                       @"[ ].");
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
    return 6;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    BuyNumberCell* cell = [tableView dequeueReusableCellWithIdentifier:@"BuyNumberCell" forIndexPath:indexPath];

    float setupFee = [[self.area objectForKey:@"setupFee"] floatValue];
    int   months   = [self monthsForIndexPath:indexPath];
    int   tier     = [self tierForMonths:months];

    NSString* productIdentifier = [[PurchaseManager sharedManager] productIdentifierForNumberTier:tier];
    NSString* priceString       = [[PurchaseManager sharedManager]localizedPriceForProductIdentifier:productIdentifier];
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
    cell.setupLabel.text  = text;

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString*   title = nil;

    if (section == 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"BuyNumber:... TableFooter", nil, [NSBundle mainBundle],
                                                  @"The setup fee will be taken from your credit.",
                                                  @"[Multiple lines]");
    }

    return title;
}



#pragma mark - Table View Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    int       tier              = [self tierForMonths:[self monthsForIndexPath:indexPath]];
    NSString* productIdentifier = [[PurchaseManager sharedManager] productIdentifierForNumberTier:tier];

    [[PurchaseManager sharedManager] buyProductIdentifier:productIdentifier];
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

    return tier;
}

@end
