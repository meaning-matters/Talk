//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "NumbersViewController.h"

@interface NumbersViewController ()

@end


@implementation NumbersViewController

- (id)init
{
    if (self = [super initWithNibName:@"NumbersView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Numbers", @"Numbers tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"NumbersTab.png"];
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
