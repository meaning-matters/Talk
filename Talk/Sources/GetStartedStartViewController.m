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


@interface GetStartedStartViewController ()

@end

@implementation GetStartedStartViewController

- (id)init
{
    if (self = [super init])
    {
        self.title = NSLocalizedStringWithDefaultValue(@"GetStartedStart ScreenTitle", nil,
                                                       [NSBundle mainBundle], @"Start",
                                                       @"Title of app screen ...\n"
                                                       @"[1 line larger font].");
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.textView.text = NSLocalizedStringWithDefaultValue(@"GetStartedStart ScreenTitle", nil, [NSBundle mainBundle],
                                                            @"To get started, buy a little credit, and verify one of "
                                                            @"your phone numbers. No need to create a\n\nWhen you make a call, you'll be "
                                                            @"called back by our server; that's why your number needs "
                                                            @"to be verified. When you answer, the person you're trying to "
                                                            @"reach will be called.\n\n",
                                                            @"[N lines larger font].");
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.button.enabled = NO;
    self.button.alpha   = 0.5f;
    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
        if (success == YES)
        {
            self.button.enabled = YES;
            self.button.alpha   = 0.5f;
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
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
