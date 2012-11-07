//
//  HelpViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "HelpViewController.h"

@interface HelpViewController ()

@end


@implementation HelpViewController

- (id)init
{
    if (self = [super initWithNibName:@"HelpView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Help", @"Help tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"HelpTab.png"];
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
