//
//  GroupsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "GroupsViewController.h"

@interface GroupsViewController ()

@end


@implementation GroupsViewController

@synthesize textField = _textField;

- (id)init
{
    if (self = [super initWithNibName:@"GroupsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Groups", @"Groups tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"GroupsTab.png"];
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
