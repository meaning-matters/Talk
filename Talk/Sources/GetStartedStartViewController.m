//
//  GetStartedStartViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "GetStartedStartViewController.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "Strings.h"


@implementation GetStartedStartViewController

- (id)init
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"GetStartedStart ScreenTitle", nil, [NSBundle mainBundle],
                                                       @"Start",
                                                       @"Title of app screen ...\n"
                                                       @"[1 line larger font].");
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.titleLabel.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart Welcome", nil, [NSBundle mainBundle],
                                                             @"Welcome!",
                                                             @"...\n"
                                                             @"[1 line large font].");

    self.textView.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart Text", nil, [NSBundle mainBundle],
                                                           @"After tapping the button below, the iTunes Store will "
                                                           @"ask you to log in. This is needed to retrieve your "
                                                           @"initial credit purchase.\n\n"
                                                           @"Restoring is only possible when using "
                                                           @"the same iTunes Store account.\n\n"
                                                           @"Call history & settings are saved locally on your device, "
                                                           @"and can't be restored.\n\n"
                                                           @"If you use the app on multiple devices, you'll simply "
                                                           @"be sharing the credit and phone number(s).",
                                                           @"....\n"
                                                           @"[iOS alert title size].");

    [self.button setTitle:NSLocalizedStringWithDefaultValue(@"GetStartedStart Button", nil, [NSBundle mainBundle],
                                                            @"Restore Credit & Phones",
                                                            @"...\n"
                                                            @"[1 line larger font].")
                 forState:UIControlStateNormal];
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}


- (void)getStarted
{
    [self setBusy:YES];

    [[PurchaseManager sharedManager] buyAccount:^(BOOL success, id object)
    {
        [self setBusy:NO];

        if (success == YES)
        {
            [self restoreCreditAndData];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        else if (object != nil)
        {
            NSString* title;
            NSString* message;

            title   = NSLocalizedStringWithDefaultValue(@"GetStarted FailedBuyTitle", nil,
                                                        [NSBundle mainBundle], @"Buying Credit Failed",
                                                        @"Alert title: Calling credit could not be bought.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"GetStarted FailedBuyMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Something went wrong while buying your initial credit: %@.\n\n"
                                                        @"Please try again later.",
                                                        @"Message telling that buying credit failed\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, [object localizedDescription]];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}


@end
