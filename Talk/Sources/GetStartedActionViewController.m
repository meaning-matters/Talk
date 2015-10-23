//
//  GetStartedActionViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
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
#import "Skinning.h"
#import "HtmlViewController.h"


@interface GetStartedActionViewController ()

@property (nonatomic, strong) HtmlViewController* termsViewController;

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

    [self loadProducts];

    CGFloat topInset    = 12.0f;
    CGFloat leftInset   = 10.0f;
    CGFloat bottomInset = 12.0f;
    CGFloat rightInset  = 10.0f;
    self.textView.textContainerInset = UIEdgeInsetsMake(topInset, leftInset, bottomInset, rightInset);

    //### Setting this in XIB hit an Xcode bug: text was scaled to fit.
    self.textView.editable   = NO;
    self.textView.selectable = NO;
    self.textView.backgroundColor = [Skinning backgroundTintColor];

    [Common setBorderWidth:1.0f                ofView:self.textView];
    [Common setCornerRadius:5.0f               ofView:self.textView];
    [Common setBorderColor:[UIColor grayColor] ofView:self.textView];

    [Common styleButton:self.button];
}


- (IBAction)buttonAction:(id)sender
{
    if ([self checkCurrencyCode] == YES)
    {
        NSData*                 data                = [Common dataForResource:@"Terms" ofType:@"json"];
        NSDictionary*           dictionary          = [Common objectWithJsonData:data];
        UINavigationController* modalViewController;

        self.termsViewController = [[HtmlViewController alloc] initWithDictionary:dictionary modal:YES];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:self.termsViewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self presentViewController:modalViewController
                           animated:YES
                         completion:nil];

        UIBarButtonItem* buttonItem;
        buttonItem = [[UIBarButtonItem alloc] initWithTitle:[Strings agreeString]
                                                      style:UIBarButtonItemStylePlain
                                                     target:self
                                                     action:@selector(agree)];
        self.termsViewController.navigationItem.rightBarButtonItem = buttonItem;
    }
}


- (void)agree
{
    NSString* title;
    NSString* message;

    title   = NSLocalizedStringWithDefaultValue(@"GetStartedAction AgreeTitle", nil,
                                                [NSBundle mainBundle], @"Please Confirm",
                                                @"Alert title: Calling credit could not be bought.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"GetStartedAction AgreeMessage", nil,
                                                [NSBundle mainBundle],
                                                @"I agree to the NumberBay Terms and Conditions.",
                                                @"....\n"
                                                @"[iOS alert message size]");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self.termsViewController dismissViewControllerAnimated:YES
                                                     completion:^
        {
            if (buttonIndex == 1)
            {
                [self getStarted];
            }
        }];
    }
                         cancelButtonTitle:[Strings cancelString]
                         otherButtonTitles:[Strings agreeString], nil];
}


- (void)getStarted
{
    // Dummy to be overriden by subclass.
}


- (void)setBusy:(BOOL)busy
{
    self.button.enabled = busy ? NO   : YES;
    self.button.alpha   = busy ? 0.5f : 1.0f;

    busy ? [self.activityIndicator startAnimating] : [self.activityIndicator stopAnimating];
}


- (void)loadProducts
{
    self.button.enabled = NO;
    self.button.alpha   = 0.5f;
    [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
    {
        self.button.enabled = YES;
        self.button.alpha   = 1.0f;
        if (success == NO)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}


- (BOOL)checkCurrencyCode
{
    if ([Settings sharedSettings].storeCurrencyCode.length == 0)
    {
        NSString* title;
        NSString* message;
        title   = NSLocalizedStringWithDefaultValue(@"GetStartedAction NoCurrencyCodeTitle", nil, [NSBundle mainBundle],
                                                    @"No Connection",
                                                    @"...\n"
                                                    @"...");
        message = NSLocalizedStringWithDefaultValue(@"GetStartedAction NoCurrencyCodeMessage", nil, [NSBundle mainBundle],
                                                    @"Information from the iTunes Store has not been loaded (yet).\n\n"
                                                    @"Please make sure your iTunes Store account is active on this device, "
                                                    @"and you're connected to internet.",
                                                    @"...\n"
                                                    @"...");
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            [[AppDelegate appDelegate] resetAll];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];

        return NO;
    }
    else
    {
        return YES;
    }
}


- (void)restoreUserData
{
    [self setBusy:YES];

    [[DataManager sharedManager] synchronizeAll:^(NSError *error)
    {
        [self setBusy:NO];

        if (error == nil)
        {
            NSArray* phones = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                                        sortKeys:@[@"name"]
                                                                       predicate:nil
                                                            managedObjectContext:nil];
            if (phones.count == 0)
            {
                VerifyPhoneViewController* viewController;
                viewController = [[VerifyPhoneViewController alloc] initWithCompletion:^(PhoneNumber* verifiedPhoneNumber)
                {
                    if (verifiedPhoneNumber != nil)
                    {
                        [self setBusy:YES];
                        [self savePhoneNumber:verifiedPhoneNumber
                                     withName:[UIDevice currentDevice].name
                                   completion:^(NSError* error)
                        {
                            [self setBusy:NO];

                            if (error == nil)
                            {
                                [self readyWithE164:[verifiedPhoneNumber e164Format]];
                            }
                            else
                            {
                                [self showSavingPhoneAlert:error];
                            }
                        }];
                    }
                    else
                    {
                        [[AppDelegate appDelegate] resetAll];
                    }
                }];

                [self.navigationController pushViewController:viewController animated:YES];
            }
            else
            {
                [self readyWithE164:((PhoneData*)phones[0]).e164];
            }
        }
        else
        {
            [self setBusy:NO];
            [self showLoadingPhonesAlert:error];
        }
    }];
}


- (void)savePhoneNumber:(PhoneNumber*)phoneNumber withName:(NSString*)name completion:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] updateVerifiedE164:[phoneNumber e164Format]
                                        withName:name
                                           reply:^(NSError* error)
    {
        if (error == nil)
        {
            PhoneData*              phone;
            NSManagedObjectContext* context;

            context    = [DataManager sharedManager].managedObjectContext;
            phone      = [NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                       inManagedObjectContext:context];
            phone.name = name;
            phone.e164 = [phoneNumber e164Format];

            [[DataManager sharedManager] saveManagedObjectContext:nil];

            completion(nil);
        }
        else
        {
            completion(error);
        }
    }];
}


- (void)readyWithE164:(NSString*)e164
{
    [Settings sharedSettings].callbackE164 = e164;
    [Settings sharedSettings].callerIdE164 = e164;

    [self showWelcomeAlert];
}


- (void)showSavingPhoneAlert:(NSError*)error
{
    NSString* title;
    NSString* message;
    title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedSavePhoneTitle", nil,
                                                [NSBundle mainBundle], @"Storing Phone Failed",
                                                @"Alert title: Calling credit could not be downloaded.\n"
                                                @"[iOS alert title size].");
    message = NSLocalizedStringWithDefaultValue(@"Provisioning FailedSavePhoneMessage", nil,
                                                [NSBundle mainBundle],
                                                @"You phone number could not be stored on the server: %@\n\n"
                                                @"Please try again later.",
                                                @"Alert message: Phone number could not be saved over internet.\n"
                                                @"[iOS alert message size]");
    message = [NSString stringWithFormat:message, error.localizedDescription];
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [[AppDelegate appDelegate] resetAll];
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)showLoadingPhonesAlert:(NSError*)error
{
    NSString* title;
    NSString* message;
    title   = NSLocalizedStringWithDefaultValue(@"Provisioning FailedNumbersTitle", nil,
                                                [NSBundle mainBundle], @"Loading Phones Failed",
                                                @"Alert title: Phone numbers could not be downloaded.\n"
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


- (void)showWelcomeAlert
{
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
                                                    @"Thanks for becoming a NumberBay user!\n\n"
                                                    @"Please send us a message from the Help tab, "
                                                    @"when there's anything you want to ask or talk about.",
                                                    @"Welcome text for a new user.");
    }
    else
    {
        title   = NSLocalizedStringWithDefaultValue(@"GetStarted WelcomeTitle", nil,
                                                    [NSBundle mainBundle],
                                                    @"Welcome back!",
                                                    @"Welcome title for a new user.");

        message = NSLocalizedStringWithDefaultValue(@"Provisioning:Ready BuyText", nil,
                                                    [NSBundle mainBundle],
                                                    @"Nice to see you again at NumberBay!\n\n"
                                                    @"Remember to send us a message from the Help tab, "
                                                    @"when there's anything you want to ask or talk about.",
                                                    @"Welcome text for a new user.");
    }

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];

    [[AppDelegate appDelegate] playWelcome];
}

@end
