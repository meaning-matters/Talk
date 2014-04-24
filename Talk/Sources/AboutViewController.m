//
//  AboutViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AboutViewController.h"
#import "LicensesViewController.h"
#import "ThanksViewController.h"
#import "Settings.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "Skinning.h"
#import "HtmlViewController.h"


@interface AboutViewController ()

@end


@implementation AboutViewController

- (instancetype)init
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
                                                                [NSBundle mainBundle], @"%@",
                                                                @"To form software version (e.g. '1.2.5')\n"
                                                                @"[1 line normal font].");
    self.versionLabel.text = [NSString stringWithFormat:versionText, [Settings sharedSettings].appVersion];

    [self.emailButton setTitle:[Settings sharedSettings].supportEmail forState:UIControlStateNormal];

    NSString*   title;
    title = NSLocalizedStringWithDefaultValue(@"About TermsButtonTitle", nil,
                                              [NSBundle mainBundle], @"Terms & Conditions",
                                              @"Button title to open terms & conditions screen.\n"
                                              @"[1 line normal font].");
    [self.termsButton setTitle:title forState:UIControlStateNormal];
    [Common styleButton:self.termsButton];

    title = NSLocalizedStringWithDefaultValue(@"About ThanksButtonTitle", nil,
                                              [NSBundle mainBundle], @"Thanks",
                                              @"Button title to open thanks screen.\n"
                                              @"[1 line normal font].");
    [self.thanksButton setTitle:title forState:UIControlStateNormal];
    [Common styleButton:self.thanksButton];

    title = NSLocalizedStringWithDefaultValue(@"About LicensesButtonTitle", nil,
                                              [NSBundle mainBundle], @"Licenses",
                                              @"Button title to show open-source software licenses screen.\n"
                                              @"[1 line normal font - must use correct iOS term].");
    [self.licensesButton setTitle:title forState:UIControlStateNormal];
    [Common styleButton:self.licensesButton];
}


#pragma mark - Actions

- (IBAction)emailAction:(id)sender
{
    [Common sendEmailTo:[Settings sharedSettings].supportEmail
                subject:[Settings sharedSettings].callbackE164
                   body:nil
             completion:nil];
}


- (IBAction)termsAction:(id)sender
{
    NSData*                 data                = [Common dataForResource:@"Terms" ofType:@"json"];
    NSDictionary*           dictionary          = [Common objectWithJsonData:data];
    HtmlViewController*     termsViewController = [[HtmlViewController alloc] initWithDictionary:dictionary];
    UINavigationController* modalViewController;

    modalViewController = [[UINavigationController alloc] initWithRootViewController:termsViewController];
    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:modalViewController
                       animated:YES
                     completion:nil];
}


- (IBAction)versionAction:(id)sender
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"About VersionTitle", nil, [NSBundle mainBundle],
                                                @"Version %@",
                                                @"\n"
                                                @"[iOS alert title size].");

    message = NSLocalizedStringWithDefaultValue(@"About VersionMessage", nil, [NSBundle mainBundle],
                                                @"Created on %@.",
                                                @"\n"
                                                @"[iOS alert message size]");

    title   = [NSString stringWithFormat:title, [Settings sharedSettings].appVersion];
    message = [NSString stringWithFormat:message, [NSString stringWithUTF8String:__DATE__]];

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (IBAction)thanksAction:(id)sender
{
    ThanksViewController*  thanksViewController;
    UINavigationController* modalViewController;

    thanksViewController = [[ThanksViewController alloc] init];

    modalViewController = [[UINavigationController alloc] initWithRootViewController:thanksViewController];
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


#pragma mark - Mail Compose Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultSent)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"About EmailSentTitle", nil, [NSBundle mainBundle],
                                                    @"Email Underway",
                                                    @"Alert title that sending an email is in progress\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"About EmailSentMessage", nil, [NSBundle mainBundle],
                                                    @"Thanks for contacting us. Your email has been placed "
                                                    @"in your outbox, or has already been sent.\n\n"
                                                    @"We do our best to respond within 48 hours.",
                                                    @"Alert message that sending an email is in progress\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else if (result == MFMailComposeResultFailed)
    {
        NSString* title;
        NSString* message;

        title   = NSLocalizedStringWithDefaultValue(@"About EmailFailedTitle", nil,
                                                    [NSBundle mainBundle], @"Failed To Send Email",
                                                    @"Alert title that sending an email failed\n"
                                                    @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"About EmailFailedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Sending the email message failed: %@.",
                                                    @"Alert message that sending an email failed\n"
                                                    @"[iOS alert message size]");

        message = [NSString stringWithFormat:message, [error localizedDescription]];

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}

@end
