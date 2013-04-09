//
//  RecentsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "RecentsViewController.h"

@interface RecentsViewController ()

@end


@implementation RecentsViewController

- (id)init
{
    if (self = [super initWithNibName:@"RecentsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Recents", @"Recents tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"RecentsTab.png"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
