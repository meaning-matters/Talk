//
//  ShareViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ShareViewController.h"

@interface ShareViewController ()

@end


@implementation ShareViewController

- (id)init
{
    if (self = [super initWithNibName:@"ShareView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Share", @"Share tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"ShareTab.png"];
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
