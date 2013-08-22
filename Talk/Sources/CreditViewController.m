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
    [[PurchaseManager sharedManager] buyCreditForTier:1
                                           completion:^(BOOL success, id object)
    {
        
    }];
}

@end
