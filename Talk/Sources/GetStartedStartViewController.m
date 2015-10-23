//
//  GetStartedStartViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "GetStartedStartViewController.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "AppDelegate.h"


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
                                                           @"Get some credit, and add a phone number. "
                                                           @"That's all you need, to make calls. Easy!\n\n"
                                                           @"With every call, you'll be called back. "
                                                           @"When you answer, the other person will be called.\n\n"
                                                           @"You can install NumberBay on all your iOS devices, and "
                                                           @"share the credit and phone number(s).",
                                                           @"....\n"
                                                           @"[iOS alert title size].");

    [self.button setTitle:NSLocalizedStringWithDefaultValue(@"GetStartedStart Button", nil, [NSBundle mainBundle],
                                                            @"Buy Some Credit",
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
            [self restoreUserData];
        }
        else if (object != nil && ((NSError*)object).code == SKErrorPaymentCancelled)
        {
            [self.navigationController popViewControllerAnimated:YES];
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
                [[AppDelegate appDelegate] resetAll];
                [self.navigationController popViewControllerAnimated:YES];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}

@end
