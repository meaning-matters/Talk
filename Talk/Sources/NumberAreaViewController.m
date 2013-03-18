//
//  NumberAreaViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 11/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "NumberAreaViewController.h"
#import "CommonStrings.h"
#import "WebClient.h"
#import "BlockAlertView.h"


@interface NumberAreaViewController ()
{
    NSDictionary*           country;
    NSDictionary*           state;
    NSDictionary*           area;
    NSMutableDictionary*    info;
}

@end


@implementation NumberAreaViewController

- (id)initWithCountry:(NSDictionary*)theCountry state:(NSDictionary*)theState area:(NSDictionary*)theArea
{    
    if (self = [super initWithNibName:@"NumberAreaView" bundle:nil])
    {
        country = theCountry;
        state   = theState;
        area    = theArea;
        
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.title = [CommonStrings loadingString];

    UIBarButtonItem*    cancelButton;
    cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                 target:self
                                                                 action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;

    if ([area[@"requireInfo"] boolValue] == YES)
    {
        [[WebClient sharedClient] retrieveNumberAreaInfoForIsoCountryCode:country[@"isoCode"]
                                                                 areaCode:area[@"areaCode"]
                                                                    reply:^(WebClientStatus status, id content)
        {
            if (status == WebClientStatusOk)
            {
                self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                              [NSBundle mainBundle], @"Area",
                                                                              @"Title of app screen with one area.\n"
                                                                              @"[1 line larger font].");

                info = [NSMutableDictionary dictionaryWithDictionary:content];
            }
            else if (status == WebClientStatusFailServiceUnavailable)
            {
                NSString*   title;
                NSString*   message;

                title = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertTitle", nil,
                                                          [NSBundle mainBundle], @"Service Unavailable",
                                                          @"Alert title telling that loading countries over internet failed.\n"
                                                          @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"NumberCountries UnavailableAlertMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"The service for buying numbers is temporarily offline."
                                                            @"\n\nPlease try again later.",
                                                            @"Alert message telling that loading countries over internet failed.\n"
                                                            @"[iOS alert message size - use correct iOS terms for: Settings "
                                                            @"and Notifications!]");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                 {
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
                                     cancelButtonTitle:[CommonStrings cancelString]
                                     otherButtonTitles:nil];
            }
            else
            {
                NSString*   title;
                NSString*   message;

                title = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertTitle", nil,
                                                          [NSBundle mainBundle], @"Loading Failed",
                                                          @"Alert title telling that loading countries over internet failed.\n"
                                                          @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"NumberCountries LoadFailAlertMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Loading the list of countries failed.\n\nPlease try again later.",
                                                            @"Alert message telling that loading countries over internet failed.\n"
                                                            @"[iOS alert message size - use correct iOS terms for: Settings "
                                                            @"and Notifications!]");
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                 {
                     [self dismissViewControllerAnimated:YES completion:nil];
                 }
                                     cancelButtonTitle:[CommonStrings cancelString]
                                     otherButtonTitles:nil];
            }
        }];
    }
    else
    {
        self.navigationItem.title = NSLocalizedStringWithDefaultValue(@"NumberArea ScreenTitle", nil,
                                                                      [NSBundle mainBundle], @"Area",
                                                                      @"Title of app screen with one area.\n"
                                                                      @"[1 line larger font].");
    }
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}


@end
