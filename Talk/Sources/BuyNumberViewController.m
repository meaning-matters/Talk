//
//  BuyNumberViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/07/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "BuyNumberViewController.h"
#import "BuyNumberCell.h"
#import "CommonStrings.h"
#import "PurchaseManager.h"


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
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 6;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
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
    text = NSLocalizedStringWithDefaultValue(@"BuyNumber:... BuyLabel", nil, [NSBundle mainBundle],
                                             @"Buy %d %@ for %@",
                                             @"Parameters are: number of months (1, 2, 3, ...), "
                                             @"the word 'month' in singular or plural, "
                                             @"the price (including currency sign).");
    text = [NSString stringWithFormat:text,
            months,
            (months == 1) ? [CommonStrings monthString] : [CommonStrings monthsString],
            priceString];
    
    cell.monthsLabel.text = text;
    cell.setupLabel.text  = [[PurchaseManager sharedManager] localizedFormattedPrice:setupFee];

    return cell;
}


#pragma mark - Table view delegate

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
