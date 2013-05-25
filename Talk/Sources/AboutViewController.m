//
//  AboutViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AboutViewController.h"
#import "Settings.h"


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

    self.companyLabel.text = [Settings sharedSettings].companyNameAddress;

    NSString*   versionText = NSLocalizedStringWithDefaultValue(@"About:AppInfo Version", nil,
                                                                [NSBundle mainBundle], @"Version %@",
                                                                @"To form software version (e.g. 'Version 1.2.5')\n"
                                                                @"[1 line normal font].");
    self.versionLabel.text = [NSString stringWithFormat:versionText, [Settings sharedSettings].appVersion];
}


#pragma mark - Actions

- (IBAction)rateAction:(id)sender
{
    NSString* url = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews"
                    @"?id=%@&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&"
                    @"type=Purple+Software";
    url = [NSString stringWithFormat:url, [Settings sharedSettings].appId];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}


- (IBAction)licensesAction:(id)sender
{

}

@end
