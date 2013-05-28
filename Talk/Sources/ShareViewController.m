//
//  ShareViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ShareViewController.h"
#import "Settings.h"


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

    self.twitterButton.color  = [UIColor colorWithRed:0.00f green:0.67f blue:0.96f alpha:1.0f];
    self.facebookButton.color = [UIColor colorWithRed:0.17f green:0.26f blue:0.53f alpha:1.0f];
    self.appStoreButton.color = [UIColor colorWithRed:0.21f green:0.59f blue:0.81f alpha:1.0f];
    self.emailButton.color    = [UIColor colorWithRed:0.19f green:0.44f blue:0.78f alpha:1.0f];
    self.messageButton.color  = [UIColor colorWithRed:0.11f green:0.85f blue:0.02f alpha:1.0f];
}



- (IBAction)twitterAction:(id)sender
{

}


- (IBAction)facebookAction:(id)sender
{

}


- (IBAction)appStoreAction:(id)sender
{
    NSString* url = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews"
    @"?id=%@&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&"
    @"type=Purple+Software";
    url = [NSString stringWithFormat:url, [Settings sharedSettings].appId];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}


- (IBAction)emailAction:(id)sender
{

}


- (IBAction)messageAction:(id)sender
{

}

@end
