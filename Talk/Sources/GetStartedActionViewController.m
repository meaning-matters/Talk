//
//  GetStartedActionViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "GetStartedActionViewController.h"
#import "Common.h"
#import "WebClient.h"
#import "Settings.h"
#import "DataManager.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "VerifyPhoneViewController.h"
#import "PhoneData.h"
#import "Strings.h"


@interface GetStartedActionViewController ()

@end


@implementation GetStartedActionViewController

- (id)init
{
    if (self = [super initWithNibName:@"GetStartedActionView" bundle:nil])
    {
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    CGFloat topInset    = 12.0f;
    CGFloat leftInset   = 10.0f;
    CGFloat bottomInset = 12.0f;
    CGFloat rightInset  = 10.0f;
    self.textView.textContainerInset = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);

    //### Setting this in XIB hit an Xcode bug: text was scaled to fit.
    self.textView.editable   = NO;
    self.textView.selectable = NO;

    [Common styleButton:self.button];
}


// Dummy to be overriden by subclass.
- (IBAction)buttonAction:(id)sender
{
}


- (void)setBusy:(BOOL)busy
{
    self.button.enabled = busy ? NO   : YES;
    self.button.alpha   = busy ? 0.5f : 1.0f;

    busy ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
}


- (void)restoreCreditAndData
{
    [self setBusy:YES];

    [[WebClient sharedClient] retrieveCreditForCurrencyCode:[Settings sharedSettings].currencyCode
                                                      reply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            [Settings sharedSettings].credit = credit;

            [[DataManager sharedManager] synchronizeAll:^(NSError *error)
            {
                if (error == nil)
                {
                    [self setBusy:NO];

                    NSArray* phonesArray = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                                                     sortKeys:@[@"name"]
                                                                                    predicate:nil
                                                                         managedObjectContext:nil];
                    if (phonesArray.count == 0)
                    {
                        VerifyPhoneViewController* viewController;
                        viewController = [[VerifyPhoneViewController alloc] initWithCompletion:^(PhoneNumber* verifiedPhoneNumber)
                        {
                            if (verifiedPhoneNumber != nil)
                            {
                                [Settings sharedSettings].callbackE164 = ((PhoneData*)phonesArray[0]).e164;
                                [Settings sharedSettings].callerIdE164 = ((PhoneData*)phonesArray[0]).e164;
                            }
                        }];

                        [self.navigationController pushViewController:viewController animated:YES];
                    }
                    else
                    {
                        [Settings sharedSettings].callbackE164 = ((PhoneData*)phonesArray[0]).e164;
                        [Settings sharedSettings].callerIdE164 = ((PhoneData*)phonesArray[0]).e164;
                    }

                    float     credit       = [Settings sharedSettings].credit;
                    NSString* creditString = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];
                    NSString* title;
                    NSString* message;

                    if ([PurchaseManager sharedManager].isNewAccount == YES)
                    {
                        title   = NSLocalizedStringWithDefaultValue(@"GetStarted WelcomeTitle", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Welcome!",
                                                                    @"Welcome title for a new user.");

                        message = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BuyText", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Thanks for becoming a NumberBay user. "
                                                                    @"Your initial credit is %@.\n\n"
                                                                    @"Please send us a message, from the Help tab, "
                                                                    @"when there's anything.",
                                                                    @"Welcome text for a new user.");
                        message = [NSString stringWithFormat:message, creditString];
                    }
                    else
                    {
                        title   = NSLocalizedStringWithDefaultValue(@"GetStarted WelcomeTitle", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Welcome back!",
                                                                    @"Welcome title for a new user.");

                        message = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BuyText", nil,
                                                                    [NSBundle mainBundle],
                                                                    @"Nice to see you again at NumberBay. "
                                                                    @"Your remaining credit is %@.\n\n"
                                                                    @"Please send us a message, from the Help tab, "
                                                                    @"when there's anything.",
                                                                    @"Welcome text for a new user.");
                        message = [NSString stringWithFormat:message, creditString];
                    }

                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        [[AppDelegate appDelegate] resetAll];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }

                                         cancelButtonTitle:[Strings closeString]
                                         otherButtonTitles:nil];
                }
                else
                {
                    NSString* title;
                    NSString* message;
                    title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedNumbersTitle", nil,
                                                                [NSBundle mainBundle], @"Loading Numbers Failed",
                                                                @"Alart title: Phone numbers could not be downloaded.\n"
                                                                @"[iOS alert title size].");
                    message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedNumbersMessage", nil,
                                                                [NSBundle mainBundle],
                                                                @"Your phone numbers could not be restored: %@\n\n"
                                                                @"Please try again later.",
                                                                @"Alert message: Phone numbers could not be downloaded.\n"
                                                                @"[iOS alert message size]");
                    message = [NSString stringWithFormat:message, error.localizedDescription];
                    [BlockAlertView showAlertViewWithTitle:title
                                                   message:message
                                                completion:^(BOOL cancelled, NSInteger buttonIndex)
                    {
                        [[AppDelegate appDelegate] resetAll];
                        [self dismissViewControllerAnimated:YES completion:nil];
                    }
                                         cancelButtonTitle:[Strings closeString]
                                         otherButtonTitles:nil];
                }
            }];
        }
        else
        {
            NSString* title;
            NSString* message;
            title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedCreditTitle", nil,
                                                        [NSBundle mainBundle], @"Loading Credit Failed",
                                                        @"Alert title: Calling credit could not be downloaded.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedCreditMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Your credit could not be loaded: %@\n\n"
                                                        @"Please try again later.",
                                                        @"Alert message: Calling credit could not be loaded.\n"
                                                        @"[iOS alert message size]");
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                [[AppDelegate appDelegate] resetAll];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
}

@end
