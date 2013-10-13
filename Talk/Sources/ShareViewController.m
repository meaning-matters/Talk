//
//  ShareViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Social/Social.h>
#import "ShareViewController.h"
#import "Settings.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Common.h"


@interface ShareViewController ()

@end


@implementation ShareViewController

- (instancetype)init
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
    SLComposeViewController*    controller;

    controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
    [controller setInitialText:[self initialText]];
    [self presentViewController:controller animated:YES completion:nil];
}


- (IBAction)facebookAction:(id)sender
{
    SLComposeViewController*    controller;

    controller = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeFacebook];
    [controller setInitialText:[self initialText]];
    [controller addImage:[UIImage imageNamed:@"LogoFacebook.png"]]; // Must be 403 pixels wide to fill timeline.
    [self presentViewController:controller animated:YES completion:nil];
}


- (IBAction)appStoreAction:(id)sender
{
    NSString* urlString = @"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews"
                          @"?id=%@&onlyLatestVersion=true&pageNumber=0&sortOrdering=1&"
                          @"type=Purple+Software";
    urlString = [NSString stringWithFormat:urlString, [Settings sharedSettings].appId];

    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlString]];
}


- (IBAction)emailAction:(id)sender
{
    if ([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
        controller.mailComposeDelegate = self;
        [controller setSubject:[Common bundleName]];
        [controller setMessageBody:[self initialText] isHTML:NO];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"Share NoMailAccountTitle", nil,
                                                  [NSBundle mainBundle], @"No Email Accounts",
                                                  @"Alert title that no text message (SMS) can be send\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Share NoEmailAccountMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"There are no email accounts configured. You can add an email "
                                                    @"account in iOS Settings > Mail, ....",
                                                    @"Alert message that no email can be send\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (IBAction)messageAction:(id)sender
{
    if ([MFMessageComposeViewController canSendText])
    {
        MFMessageComposeViewController* controller = [[MFMessageComposeViewController alloc] init];
        controller.messageComposeDelegate = self;
        controller.body = [self initialText];
        [self presentViewController:controller animated:YES completion:nil];
    }
    else
    {
        NSString*   title;
        NSString*   message;
        
        title = NSLocalizedStringWithDefaultValue(@"Share NoTextMessageTitle", nil,
                                                  [NSBundle mainBundle], @"Can't Send Message",
                                                  @"Alert title that no text message (SMS) can be send\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Share NoTextMessageMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"You can't send a text message now. You can enable iMessage in "
                                                    @"iOS Settings > Messages.",
                                                    @"Alert message that no text message (SMS) can be send\n"
                                                    @"[iOS alert message size - Settings, iMessage and Message are "
                                                    @"iOS terms]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:nil
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


#pragma mark - MF Delegates

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error
{
    if (result == MFMailComposeResultFailed)
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"Share EmailFailedTitle", nil,
                                                  [NSBundle mainBundle], @"Failed To Send Email",
                                                  @"Alert title that sending an email failed\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Share EmailFailedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Sending the text message failed.",
                                                    @"Alert message that sending an email failed\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             [self dismissViewControllerAnimated:YES completion:nil];
         }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)messageComposeViewController:(MFMessageComposeViewController*)controller
                 didFinishWithResult:(MessageComposeResult)result
{
    if (result == MessageComposeResultFailed)
    {
        NSString*   title;
        NSString*   message;

        title = NSLocalizedStringWithDefaultValue(@"Share MessageFailedTitle", nil,
                                                  [NSBundle mainBundle], @"Failed To Send Message",
                                                  @"Alert title that sending a text message (SMS) failed\n"
                                                  @"[iOS alert title size].");

        message = NSLocalizedStringWithDefaultValue(@"Share MessageFailedMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"Sending the text message failed.",
                                                    @"Alert message that sending a text message (SMS) failed\n"
                                                    @"[iOS alert message size]");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


#pragma mark - Helpers

- (NSString*)initialText
{
    NSString*   text;

    text = NSLocalizedStringWithDefaultValue(@"Share BosyText", nil,
                                             [NSBundle mainBundle],
                                             @"Check this out: %@ Great internet telephony for businesses and "
                                             @"frequent travellers.",
                                             @"Default text put in Twitter/Facebook/... message to promote "
                                             @"this app\n"
                                             @"[iOS alert title size - parameter is URL to iOS app].");
    text = [NSString stringWithFormat:text, [Common appStoreUrlString]];

    return text;
}

@end
