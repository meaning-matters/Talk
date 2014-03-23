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
    /*
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
                    NSArray* phonesArray = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                                                     sortKeys:@[@"name"]
                                                                                    predicate:nil
                                                                         managedObjectContext:nil];
                    if (phonesArray.count == 0)
                    {
                        VerifyPhoneViewController* viewController;
                        viewController = [[VerifyPhoneViewController alloc] initWithCompletion:^(PhoneNumber* verifiedPhoneNumber)
                        {

                        }];
                    }
                    else
                    {
                        if ([Settings sharedSettings].callbackE164.length == 0)
                        {

                        }
                    }

                    float     credit;
                    NSString* creditString;

                    credit       = [Settings sharedSettings].credit;
                    creditString = [[PurchaseManager sharedManager] localizedFormattedPrice:credit];


                    - (NSArray*)fetchEntitiesWithName:(NSString*)entityName
                sortKeys:(NSArray*)sortKeys
                predicate:(NSPredicate*)predicate
                managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

                    if ([PurchaseManager sharedManager].isNewAccount == YES && e164s.count == 0)
                    {
                        NSString* title;
                        NSString* message;
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
                        [BlockAlertView showAlertViewWithTitle:title
                                                       message:message
                                                    completion:nil
                                             cancelButtonTitle:[Strings closeString]
                                             otherButtonTitles:nil];
                    }
                    else if (e164s.count == 0)
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreNoNumbersText, creditString];
                    }
                    else if (e164s.count == 1)
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreHasNumberText, creditString];
                    }
                    else
                    {
                        self.readyTextView.text = [NSString stringWithFormat:readyRestoreHasNumbersText, creditString,
                                                   e164s.count];
                    }

                    NSLog(@"//####### For now always verify number.");
                    // if ([Settings sharedSettings].callbackE164.length == 0)
                    {
                        [self setVerifyStep:1];
                        [self showView:self.verifyView];
                    }
                    //else
                    {
                        //     [self showView:self.readyView];
                        // [[AppDelegate appDelegate] restore];
                    }
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
                        [[Settings sharedSettings] resetAll];
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
                [[Settings sharedSettings] resetAll];
                [self dismissViewControllerAnimated:YES completion:nil];
            }
                                 cancelButtonTitle:[Strings closeString]
                                 otherButtonTitles:nil];
        }
    }];
     */

}

@end
