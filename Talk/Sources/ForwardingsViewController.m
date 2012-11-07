//
//  ForwardingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingsViewController.h"

@interface ForwardingsViewController ()

@end


@implementation ForwardingsViewController

- (id)init
{
    if (self = [super initWithNibName:@"ForwardingsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Fowardings", @"Forwardings tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"ForwardingsTab.png"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
