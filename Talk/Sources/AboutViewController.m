//
//  AboutViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AboutViewController.h"

@interface AboutViewController ()

@end


@implementation AboutViewController

- (id)init
{
    if (self = [super initWithNibName:@"AboutView" bundle:nil])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"About:AppInfo ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"About",
                                                       @"Title of app screen with general info\n"
                                                       @"[1 line larger font].");
        self.tabBarItem.image = [UIImage imageNamed:@"AboutTab.png"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

@end
