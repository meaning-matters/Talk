//
//  CreditViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "CreditViewController.h"
#import "PurchaseManager.h"

@interface CreditViewController ()

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
}


- (IBAction)buyAction:(id)sender
{
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit1"];
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit2"];
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit5"];
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit10"];
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit20"];
    [[PurchaseManager sharedManager] buyProductIdentifier:@"com.numberbay.Credit50"];
}

@end
