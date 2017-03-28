//
//  GetStartedActionViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "GetStartedActionViewController.h"
#import "AnalyticsTransmitter.h"
#import "Common.h"
#import "WebClient.h"
#import "Settings.h"
#import "DataManager.h"
#import "PurchaseManager.h"
#import "BlockAlertView.h"
#import "CodeVerifyPhoneViewController.h"
#import "PhoneData.h"
#import "Strings.h"
#import "Skinning.h"
#import "HtmlViewController.h"
#import "DestinationData.h"


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
    AnalysticsTrace(@"buttonAction");

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


- (void)agree
{
    AnalysticsTrace(@"agree");

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
                AnalysticsTrace(@"agree_YES");

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
    AnalysticsTrace(([NSString stringWithFormat:@"setBusy_%@", busy ? @"YES" : @"NO"]));

    self.button.enabled = busy ? NO   : YES;
    self.button.alpha   = busy ? 0.5f : 1.0f;

    busy ? [self.busyIndicator startAnimating] : [self.busyIndicator stopAnimating];
}


- (void)restoreUserData
{
    AnalysticsTrace(@"restoreUserData");

    [self setBusy:YES];

    [[DataManager sharedManager] synchronizeAll:^(NSError *error)
    {
        [self setBusy:NO];

        if (error == nil)
        {
            AnalysticsTrace(@"restoreUserData_OK");

            NSArray* phones = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                                        sortKeys:@[@"name"]
                                                                       predicate:nil
                                                            managedObjectContext:nil];
            if (phones.count == 0)
            {
                AnalysticsTrace(@"restoreUserData_no_phones");

                CodeVerifyPhoneViewController* viewController;
                viewController = [[CodeVerifyPhoneViewController alloc] initWithCompletion:^(PhoneNumber* verifiedPhoneNumber,
                                                                                         NSString*    uuid)
                {
                    if (verifiedPhoneNumber != nil)
                    {
                        AnalysticsTrace(@"restoreUserData_verifiedPhoneNumber_OK");

                        [self setBusy:YES];
                        [self savePhoneNumber:verifiedPhoneNumber
                                     withUuid:uuid
                                         name:[UIDevice currentDevice].name
                                   completion:^(NSError* error)
                        {
                            [self setBusy:NO];

                            if (error == nil)
                            {
                                AnalysticsTrace(@"restoreUserData_save_OK");

                                [self readyWithE164:[verifiedPhoneNumber e164Format]];
                            }
                            else
                            {
                                AnalysticsTrace(@"restoreUserData_save_FAIL");

                                [self showSavingPhoneAlert:error];
                            }
                        }];
                    }
                    else
                    {
                        AnalysticsTrace(@"restoreUserData_resetAll");

                        [[AppDelegate appDelegate] resetAll];
                    }
                }];

                [self.navigationController pushViewController:viewController animated:YES];
            }
            else
            {
                AnalysticsTrace(@"restoreUserData_readyWithE164");

                [[AppDelegate appDelegate] updateNumbersBadgeValue];
                [[AppDelegate appDelegate] refreshLocalNotifications];

                [self readyWithE164:((PhoneData*)phones[0]).e164];
            }
        }
        else
        {
            AnalysticsTrace(@"restoreUserData_showLoadingPhonesAlert");

            [self setBusy:NO];
            [self showLoadingPhonesAlert:error];
        }
    }];
}


- (void)savePhoneNumber:(PhoneNumber*)phoneNumber
               withUuid:(NSString*)uuid
                   name:(NSString*)name
             completion:(void (^)(NSError* error))completion
{
    [[WebClient sharedClient] updatePhoneVerificationForUuid:uuid name:name reply:^(NSError* error)
    {
        if (error == nil)
        {
            [self createDefaultDestinationWithE164:[phoneNumber e164Format] completion:^(NSError *error)
            {
                if (error == nil)
                {
                    PhoneData*              phone;
                    NSManagedObjectContext* context;

                    context    = [DataManager sharedManager].managedObjectContext;
                    phone      = [NSEntityDescription insertNewObjectForEntityForName:@"Phone"
                                                               inManagedObjectContext:context];
                    phone.uuid = uuid;
                    phone.name = name;
                    phone.e164 = [phoneNumber e164Format];

                    [[DataManager sharedManager] saveManagedObjectContext:nil];
                    
                    completion(nil);
                }
                else
                {
                    AnalysticsTrace(@"saveDestination_ERROR");

                    completion(error);
                }
            }];
        }
        else
        {
            AnalysticsTrace(@"savePhoneNumber_ERROR");

            completion(error);
        }
    }];
}


- (DestinationData*)createDefaultDestinationWithE164:(NSString*)e164 completion:(void (^)(NSError* error))completion
{
    NSManagedObjectContext* context     = [DataManager sharedManager].managedObjectContext;
    DestinationData*        destination = [NSEntityDescription insertNewObjectForEntityForName:@"Destination"
                                                                        inManagedObjectContext:context];

    NSString* name = [NSString stringWithFormat:@"%@", e164];
    [destination createForE164:e164 name:name showCalledId:false completion:completion];

    return destination;
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
                                                    @"You're now a NumberBay insider!\n\n"
                                                    @"When there's anything you want to chat about, "
                                                    @"reach us from the Help tab.",
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
                                                    @"Always great to see you again!\n\n"
                                                    @"Remember, when there's anything you want to chat about, "
                                                    @"reach us from the Help tab.",
                                                    @"Welcome text for a new user.");
    }

    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:^(BOOL cancelled, NSInteger buttonIndex)
    {
        [[AppDelegate appDelegate] playWelcome];

        [self dismissViewControllerAnimated:YES completion:nil];
    }
                         cancelButtonTitle:[Strings okString]
                         otherButtonTitles:nil];
}

@end
