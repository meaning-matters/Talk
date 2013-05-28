//
//  AboutViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AboutViewController.h"
#import "LicensesViewController.h"
#import "CreditsViewController.h"
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

    NSString*   title;

    title = NSLocalizedStringWithDefaultValue(@"About CreditsButtonTitle", nil,
                                              [NSBundle mainBundle], @"Credits",
                                              @"Button title to open credits/thanks (not calling credit) screen.\n"
                                              @"[1 line normal font].");
    [self.creditsButton setTitle:title forState:UIControlStateNormal];

    title = NSLocalizedStringWithDefaultValue(@"About LicensesButtonTitle", nil,
                                              [NSBundle mainBundle], @"Licenses",
                                              @"Button title to show open-source software licenses screen.\n"
                                              @"[1 line normal font - must use correct iOS term].");
    [self.licensesButton setTitle:title forState:UIControlStateNormal];
}


#pragma mark - Actions

- (IBAction)creditsAction:(id)sender
{
    CreditsViewController*  creditsViewController;
    UINavigationController* modalViewController;

    creditsViewController = [[CreditsViewController alloc] init];

    modalViewController = [[UINavigationController alloc] initWithRootViewController:creditsViewController];
    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:modalViewController
                       animated:YES
                     completion:nil];
}


- (IBAction)licensesAction:(id)sender
{
    LicensesViewController* licensesViewController;
    UINavigationController* modalViewController;

    licensesViewController = [[LicensesViewController alloc] init];

    modalViewController = [[UINavigationController alloc] initWithRootViewController:licensesViewController];
    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:modalViewController
                       animated:YES
                     completion:nil];
}

@end
