
//
//  AppDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//
//### Want to remove CoreData? http://www.gravitywell.co.uk/blog/post/how-to-quickly-add-core-data-to-an-app-in-xcode-4

#import <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import "HockeySDK.h"
#import "AppDelegate.h"
#import "Settings.h"
#import "PhoneNumber.h"
#import "Skinning.h"
#import "NetworkStatus.h"
#import "LibPhoneNumber.h"
#import "CallManager.h"
#import "PurchaseManager.h"
#import "DataManager.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "WebClient.h"
#import "WebInterface.h"
#import "NavigationController.h"
#import "CountriesViewController.h"
#import "CallerIdData.h"
#import "CallableData.h"
#import "PhoneData.h"
#import "CallerIdViewController.h"
#import "BadgeHandler.h"
#import "AddressUpdatesHandler.h"
#import "WebViewController.h"
#import "NumberData.h"
#import "DtmfPlayer.h"

NSString* const AppDelegateRemoteNotification = @"AppDelegateRemoteNotification";


@interface AppDelegate ()
{
    UIImageView*     defaultFadeImage;
    BOOL             hasFadedDefaultImage;
    AVAudioPlayer*   welcomePlayer;
    UIBarButtonItem* tabBarCustomizeDoneItem;
}

@end


@implementation AppDelegate

NSString* swizzled_preferredContentSizeCategory(id self, SEL _cmd)
{
    return UIContentSizeCategoryExtraLarge;  // UIContentSizeCategoryLarge is iOS' default.
}


- (void)setUp
{
   // [self denmark];

    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^
    {
        self.deviceToken = nil;

        // The app can look horrible after changing iOS Settings > General > Accessibility > Large Text.
        // We override this accessibility setting here to show slightly larger text always.
        Method originalMethod = class_getInstanceMethod([UIApplication class], @selector(preferredContentSizeCategory));
        method_setImplementation(originalMethod, (IMP)swizzled_preferredContentSizeCategory);

        // Trigger singletons.
        [NetworkStatus   sharedStatus];   // Called early: because it needs UIApplicationDidBecomeActiveNotification.
        [CallManager     sharedManager];
        [DataManager     sharedManager];
        [PurchaseManager sharedManager];  // Makes sure the currency locale & code are available early.

        // Initialize phone number stuff.
        [LibPhoneNumber sharedInstance];  // This loads the JavaScript library.

        // Basic UI.
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.tabBarController = [[UITabBarController alloc] init];
        self.tabBarController.delegate = self;

        // Set address book delegate.
        [NBAddressBookManager sharedManager].delegate = self;

        // Placed here, after processing results, just before tabs are added.  Otherwise navigation bar
        // will overlap with status bar.
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

        [self addViewControllersToTabBar];
        self.window.rootViewController = self.tabBarController;
        self.window.backgroundColor    = [UIColor whiteColor];
        [self.window makeKeyAndVisible];

        // Apply skinning.
        [Skinning sharedSkinning];

        // Restore the badges.
        [BadgeHandler          sharedHandler];
        [AddressUpdatesHandler sharedHandler];

        // Reset status bar style. Without this the status bar becomes white sometimes.
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

        // Allow mixing audio from other apps.  By default this is not the case.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

        // Make sure DTMF sounds are loaded.
        [DtmfPlayer sharedPlayer];

        // Add special dial codes, for things like DNS-SRV URL setting, and other features.
        [self addSpecialDialCodes];

        // Welcome stuff.
        [self showDefaultImage];

        // Trigger loading contacts.
        self.nBPeopleListViewController.view.hidden = NO;
    });
}


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
#ifdef REDIRECT_LOGS_TO_FILE
    // To do this, change 'Application supports iTunes file sharing' in .plist to YES.
    #warning Don't forget to remove, and to switch to NO 'Application supports iTunes file sharing' in .plist.
    [Common redirectStderrToFile];
#endif
    
    UIUserNotificationType types         = UIUserNotificationTypeBadge |
                                           UIUserNotificationTypeSound |
                                           UIUserNotificationTypeAlert;
    UIUserNotificationSettings* settings = [UIUserNotificationSettings settingsForTypes:types categories:nil];
    [application registerUserNotificationSettings:settings];

    // Currently the app does not have overall data protection enabled,
    // so `protectedDataAvailable` should always be true.  We're leaving
    // it as a reminder. Check the `NumberBay.entitlements` for the current
    // data protection.
    if ([UIApplication sharedApplication].protectedDataAvailable)
    {
        [self setUp];
    }
    else
    {
        [Answers logCustomEventWithName:@"Abort"
                       customAttributes:@{}];

        abort();
    }

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"6abff73fa5eb64771ac8a5124ebc33f5" delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    [[Fabric sharedSDK] setDebug: YES];
    [Fabric with:@[[Answers class]]];

    [self refreshLocalNotifications];

    [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                 object:nil
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification* notification)
    {
        NetworkStatusReachable reachable = [notification.userInfo[@"status"] intValue];

        if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular)
        {
            [self checkCreditWithCompletion:nil];
            [self.nBRecentsListViewController retrieveCallRecordsWithSender:nil completion:nil];
        }
    }];

    return YES;
}


- (void)refreshLocalNotifications
{
    // This removes already fired notifications from notification center, which may result in the user not
    // seeing them. To make sure they get seen, we show an alert if the Number's `notifiedExpiryDays` is higher
    // than the current `expiryDays` level; this is done by `showMissedNotifications`.
    [[UIApplication sharedApplication] cancelAllLocalNotifications];

    [self scheduleNumberNotifications];
}


- (void)showMissedNotifications
{
    NSAssert([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive,
             @"showMissedNotifications may only be called when app is active and can show alerts");

    NSArray* numbers = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"];
    for (NumberData* number in numbers)
    {
        // Skip pending Numbers.
        if (number.isPending)
        {
            continue;
        }

        if (number.notifiedExpiryDays > [number expiryDays])
        {
            number.notifiedExpiryDays = [number expiryDays];

            if ([number hasExpired])
            {
                [self.numbersViewController hideNumber:number];
            }

            [number showExpiryAlertWithCompletion:^
            {
                if ([number hasExpired])
                {
                    [[DataManager sharedManager].managedObjectContext deleteObject:number];
                }
            }];
        }
    }
}


- (void)updateNumbersBadgeValue
{
    NSPredicate* unconnectedPredicate    = [NSPredicate predicateWithFormat:@"destination == nil"];
    NSArray*     unconnectedNumbers      = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                                                     sortKeys:nil
                                                                                    predicate:unconnectedPredicate
                                                                         managedObjectContext:nil];

    // Because `isPending` is a calculated property, it can't be used in a CoreData fetch and would lead to a crash.
    // That's why we fetch all Numbers below and then filter that regular array.
    NSCalendar*       calendar           = [NSCalendar currentCalendar];
    NSDateComponents* components         = [NSDateComponents new];  // Below adding to `day` also works around New Year.
    components.day                       = 7;
    NSDate*           sevenDaysDate      = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    NSPredicate*      sevenDaysPredicate = [NSPredicate predicateWithFormat:@"(isPending == NO) AND (expiryDate < %@)",
                                            sevenDaysDate];
    NSArray*          sevenDaysNumbers   = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"];
    sevenDaysNumbers                     = [sevenDaysNumbers filteredArrayUsingPredicate:sevenDaysPredicate];

    NSUInteger unverifiedCount = 0;
    NSArray*   numbers         = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"];
    for (NumberData* number in numbers)
    {
        unverifiedCount += [AddressStatus isVerifiedAddressStatusMask:number.address.addressStatus] ? 0 : 1;
    }

    NSUInteger count = [[AddressUpdatesHandler sharedHandler] badgeCount] +
                       unconnectedNumbers.count + sevenDaysNumbers.count + unverifiedCount;
    [[BadgeHandler sharedHandler] setBadgeCount:count forViewController:self.numbersViewController];
}


- (void)scheduleNumberNotifications
{
    NSArray* numbers = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"];

    // If past the 7, 3, and 1 day(s), the corresponding notification has fired and the user has seen it or was
    // in the app during that seeing the red badge.
    //
    // The is a microscopic chance the notification's date falls right in between the fraction of a second between
    // `cancelAllLocalNotifications` and adding them again here. We just ignore that to keep things simple.
    for (NumberData* number in numbers)
    {
        // Skip pending Numbers.
        if (number.isPending)
        {
            continue;
        }

        switch ([number expiryDays])
        {
            case INT16_MAX:
                // It's more than 7 days until expiry, so add all notifications.
                [self addNumberNotification:number expiryDays:7];
                [self addNumberNotification:number expiryDays:3];
                [self addNumberNotification:number expiryDays:1];
                break;

            case 7:
                // We're between 7 and 3 days until expiry, so we don't add the 7 days notification again.
                [self addNumberNotification:number expiryDays:3];
                [self addNumberNotification:number expiryDays:1];
                break;

            case 3:
                // We're between 3 and 1 days until expiry, so we don't add the 3 days notification again.
                [self addNumberNotification:number expiryDays:1];
                break;

            case 1:
                // We're past 1 day until expiry, so we don't add the 1 day notification again.
                break;
        }
    }
}


- (void)addNumberNotification:(NumberData*)number
                   expiryDays:(NSInteger)expiryDays
{
    NSCalendar*       calendar   = [NSCalendar currentCalendar];
    NSDateComponents* components = [NSDateComponents new];  // Below adding to `day` also works around New Year.
    NSDate*           beforeExpiryDate;

    components.day   = -expiryDays;
    beforeExpiryDate = [calendar dateByAddingComponents:components toDate:number.expiryDate options:0];

    UILocalNotification* notification = [[UILocalNotification alloc] init];
    notification.alertBody   = [number alertTextForExpiryHours:expiryDays * 24];
    notification.alertAction = [Strings extendString];
    notification.hasAction   = YES;
    notification.soundName   = UILocalNotificationDefaultSoundName;
    notification.userInfo    = @{ @"source" : @"numberExpiry", @"e164" : number.e164, @"expiryDays" : @(expiryDays) };
    notification.fireDate    = beforeExpiryDate;

    [[UIApplication sharedApplication] scheduleLocalNotification:notification];
}


- (void)application:(UIApplication*)application didRegisterUserNotificationSettings:(UIUserNotificationSettings*)notificationSettings
{
    [application registerForRemoteNotifications];
}


- (void)application:(UIApplication*)application handleActionWithIdentifier:(NSString*)identifier
    forRemoteNotification:(NSDictionary*)userInfo completionHandler:(void(^)())completionHandler
{
    if ([identifier isEqualToString:@"declineAction"])
    {
    }
    else if ([identifier isEqualToString:@"answerAction"])
    {
    }
}


- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for
    // certain types of temporary interruptions (such as an incoming phone call or SMS message) or
    // when the user quits the application and it begins the transition to the background state.
    //
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
    // Games should use this method to pause the game.

    if ([Settings sharedSettings].haveAccount == YES)
    {
        // Tell iOS we would like to get a background fetch.
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    }
    else
    {
        // Tell iOS we don't need a background fetch.
        [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalNever];
    }
}


- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Generate viewWillDisappear and viewDidDisappear to top view controller.
    [self.window.rootViewController beginAppearanceTransition:NO animated:NO];
    [self.window.rootViewController endAppearanceTransition];

    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // Generate viewWillAppear and viewDidAppear to top view controller.
    [self.window.rootViewController beginAppearanceTransition:YES animated:NO];
    [self.window.rootViewController endAppearanceTransition];

    [[AVAudioSession sharedInstance] setActive:YES error:nil];

    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


// Called after `didReceiveLocalNotification` or `didFinishLaunchingWithOptions`. It's important that
// `showMissedNotifications` is called after local notifications are handled because they both (may) result in an Number
// expiry alert. (Well, actually it does not matter much because both update Number's `notifiedExpiryDays` so double
// alerts can't occur. But it's good to be aware what's happening where/when.)
- (void)applicationDidBecomeActive:(UIApplication*)application
{
    [self showMissedNotifications];
    [self checkCreditWithCompletion:nil];
    if (self.nBPeopleListViewController.contactsAreLoaded)
    {
        [self.nBRecentsListViewController retrieveCallRecordsWithSender:nil completion:nil];
    }
    else
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
        {
            [self.nBRecentsListViewController retrieveCallRecordsWithSender:nil completion:nil];
        });
    }
}


- (void)applicationWillTerminate:(UIApplication*)application
{
    // Generate viewWillDisappear and viewDidDisappear to top view controller.
    [self.window.rootViewController beginAppearanceTransition:NO animated:NO];
    [self.window.rootViewController endAppearanceTransition];

    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


#pragma mark - Remote Notifications
// Some old methods are used below.  We don't support Remote Notification's Background Mode
// yet; this new feature allows the app to be brought from suspended to background, see:
// http://samwize.com/2015/08/07/how-to-handle-remote-notification-with-background-mode-enabled/
// This option can be set Talk.xcodeproj > target Talk > Capabilities > Background Modes.

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)token
{
    NSString* string = [[token description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.deviceToken = [string substringWithRange:NSMakeRange(1, [string length] - 2)];   // Strip off '<' and '>'.
        
    if ([Settings sharedSettings].haveAccount)
    {
        [self updateAccount];
    }
    
    // When account purchase transaction has not been finished, the PurchaseManager receives
    // it again at app startup.  This is however slightly earlier than that device token is
    // received.  Therefore the PurchaseManager is started up here.
    [PurchaseManager sharedManager];
}


- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    self.deviceToken = nil;

    // When account purchase transaction has not been finished, the PurchaseManager receives
    // it again at app startup.  This is however slightly earlier than that device token is
    // received.  Therefore the PurchaseManager is started up here.
    [PurchaseManager sharedManager];
}


- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    if (notification.userInfo != nil)
    {
        NSString* source = notification.userInfo[@"source"];
        if (source == nil)
        {
            return;
        }

        if ([source isEqualToString:@"databaseError"])
        {
            [self restore];
        }

        if ([source isEqualToString:@"numberExpiry"])
        {
            NSString* e164 = notification.userInfo[@"e164"];
            if (e164 != nil)
            {
                NSPredicate* predicate = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
                NumberData*  number    = [[[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                                                    sortKeys:nil
                                                                                   predicate:predicate
                                                                        managedObjectContext:nil] lastObject];
                if (number != nil)
                {
                    number.notifiedExpiryDays = [notification.userInfo[@"expiryDays"] intValue];
                    if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive)
                    {
                        // We get here when the local notification fired while the app was in foreground.
                        NSTimeInterval expiryInterval = [number.expiryDate timeIntervalSinceDate:[NSDate date]];
                        NSInteger      expiryHours    = floor(expiryInterval / (60 * 60));
                        [BlockAlertView showAlertViewWithTitle:[Strings extendNumberAlertTitleString]
                                                       message:[number alertTextForExpiryHours:expiryHours]
                                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
                        {
                            if (buttonIndex == 1)
                            {
                                [self showNumber:number];
                            }
                        }
                                             cancelButtonTitle:[Strings cancelString]
                                             otherButtonTitles:notification.alertAction, nil];
                    }
                    else
                    {
                        // We get here when the local notification was tapped outside the app.
                        [self showNumber:number];
                    }
                }
            }
        }
    }
}


- (void)showNumber:(NumberData*)number
{
    // Cancel editing of More tab.
    [self doneCustomizingTabBarViewController];

    // Jump to Number screen.
    self.tabBarController.selectedViewController = self.numbersViewController.navigationController;
    [self.numbersViewController presentNumber:number];
}


- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:AppDelegateRemoteNotification
                                                        object:nil
                                                      userInfo:userInfo];

    //### For Martin'd testing OAuth only.
    [self openWebSiteFromNotification:userInfo];
}


#pragma mark - Background Fetch

- (void)application:(UIApplication*)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    // The account credentials are saved with kSecAttrAccessibleAfterFirstUnlock, which means
    // that before the device is unlocked once after a reboot, `haveAccount` will return `NO`.
    // We need the account to access the server, so in this very sporadic case, we don't start
    // the fetch.
    //
    // Of course `haveAccount` will also return `NO` when there's no account at all.
    if ([Settings sharedSettings].haveAccount)
    {
        [self.nBRecentsListViewController retrieveCallRecordsWithSender:nil completion:^(NSError* error)
        {
            if (error == nil)
            {
                [self checkCreditWithCompletion:^(BOOL success, NSError* error)
                {
                    if (success)
                    {
                        [[DataManager sharedManager] synchronizeAll:^(NSError* error)
                        {
                            if (error == nil)
                            {
                                [self updateNumbersBadgeValue];
                                [self refreshLocalNotifications];
                            }

                            completionHandler((error == nil) ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultFailed);
                        }];
                    }
                    else
                    {
                        completionHandler(UIBackgroundFetchResultFailed);
                    }
                }];
            }
            else
            {
                completionHandler(UIBackgroundFetchResultFailed);
            }
        }];
    }
    else
    {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}


#pragma mark - Helpers

- (void)checkCreditWithCompletion:(void (^)(BOOL success, NSError* error))completion
{
    [[WebClient sharedClient] retrieveCreditWithReply:^(NSError* error, float credit)
    {
        if (error == nil)
        {
            [Settings sharedSettings].credit = credit;

            [[PurchaseManager sharedManager] loadProducts:^(BOOL success)
            {
                if (success)
                {
                    NSUInteger count = (credit < [[PurchaseManager sharedManager] priceForCreditAmount:1] / 2.0f) ? 1 : 0;
                    [[BadgeHandler sharedHandler] setBadgeCount:count forViewController:self.creditViewController];
                }

                completion ? completion(success, error) : 0;
            }];
        }
        else
        {
            completion ? completion(NO, error) : 0;
        }
    }];
}


//### For Martin'd testing OAuth only.
- (void)openWebSiteFromNotification:(NSDictionary*)userInfo
{
    NSString* urlString = userInfo[@"url"];

    if (urlString != nil)
    {
        if ([userInfo[@"deleteCookies"] boolValue] == YES)
        {
            [self deleteWebCookies];
        }

        [Common dispatchAfterInterval:4 onMain:^
        {
            WebViewController*      webViewController = [[WebViewController alloc] initWithUrlString:urlString];
            UINavigationController* modalViewController;

            modalViewController = [[UINavigationController alloc] initWithRootViewController:webViewController];
            modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [[Common topViewController] presentViewController:modalViewController
                                                     animated:YES
                                                   completion:nil];
        }];
    }
}


- (void)deleteWebCookies
{
    for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
    {
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}


#pragma mark - General & TabBar Delegate & More Navigation Delegate

- (void)addViewControllersToTabBar
{
    // The order in this array defines the default tabs order.
    NSArray* tabBarClassNames =
    @[
        NSStringFromClass([CreditViewController        class]),
        NSStringFromClass([NBRecentsListViewController class]),
        NSStringFromClass([NBPeopleListViewController  class]),
        NSStringFromClass([KeypadViewController        class]),
        NSStringFromClass([PhonesViewController        class]),
        NSStringFromClass([NumbersViewController       class]),
        //NSStringFromClass([DestinationsViewController  class]),
        NSStringFromClass([SettingsViewController      class]),
        NSStringFromClass([HelpsViewController         class]),
        NSStringFromClass([AboutViewController         class]),
    ];

    NSSet* preferredSet = [NSSet setWithArray:[Settings sharedSettings].tabBarClassNames];
    NSSet* defaultSet   = [NSSet setWithArray:tabBarClassNames];

    if ([preferredSet isEqualToSet:defaultSet])
    {
        // No view controllers were added/deleted/renamed.  Safe to use preferred set.
        tabBarClassNames = [Settings sharedSettings].tabBarClassNames;
    }
    else
    {
        // First time, or view controllers were added/deleted/renamed.  Reset preferred set.
        [Settings sharedSettings].tabBarClassNames = tabBarClassNames;
    }

    // In the loop below, the automatic creation of the view controllers takes
    // place, including the creation of the navigation controllers in which each
    // view controller is embedded.
    NSMutableArray* viewControllers       = [NSMutableArray array];
    NSMutableArray* navigationControllers = [NSMutableArray array];
    for (NSString* className in tabBarClassNames)
    {
        UIViewController*       viewController = [[NSClassFromString(className) alloc] init];
        UINavigationController* navigationController;

        // NavigationController is workaround a nasty iOS bug: http://stackoverflow.com/a/23666520/1971013
        navigationController = [[NavigationController alloc] initWithRootViewController:viewController];
        [navigationControllers addObject:navigationController];
        [viewControllers       addObject:viewController];

        // Set appropriate AppDelegate property.
        SEL selector = NSSelectorFromString([@"set" stringByAppendingFormat:@"%@:", className]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:[[navigationControllers lastObject] topViewController]];
#pragma clang diagnostic pop
    }

    self.viewControllers = [viewControllers copy];
    self.tabBarController.viewControllers = navigationControllers;
    if ([Settings sharedSettings].tabBarSelectedIndex == NSNotFound)
    {
        self.tabBarController.selectedViewController = self.tabBarController.moreNavigationController;
    }
    else
    {
        if ([Settings sharedSettings].tabBarSelectedIndex >= navigationControllers.count)
        {
            // We may get here if the number of tabs has becomes less.
            [Settings sharedSettings].tabBarSelectedIndex = 2;
        }
        
        self.tabBarController.selectedViewController = navigationControllers[[Settings sharedSettings].tabBarSelectedIndex];
    }

    self.tabBarController.moreNavigationController.delegate = self;
}


- (void)tabBarController:(UITabBarController*)tabBarController willBeginCustomizingViewControllers:(NSArray*)viewControllers
{
    [Answers logContentViewWithName:@"Customize"
                        contentType:@"Main"
                          contentId:@"Customize"
                   customAttributes:@{}];

    [[BadgeHandler sharedHandler] hideBadges];

    id customizeView = [[tabBarController view] subviews][1];
    if ([customizeView isKindOfClass:NSClassFromString(@"UITabBarCustomizeView")] == YES)
    {
        UINavigationBar* navigationBar = (UINavigationBar*)[customizeView subviews][1];
        if ([navigationBar isKindOfClass:[UINavigationBar class]])
        {
            navigationBar.topItem.rightBarButtonItem.tintColor = [Skinning tintColor];
            tabBarCustomizeDoneItem = navigationBar.topItem.rightBarButtonItem;
        }
    }
}


- (void)tabBarController:(UITabBarController*)tabBarController willEndCustomizingViewControllers:(NSArray*)viewControllers
                 changed:(BOOL)changed
{
    tabBarCustomizeDoneItem = nil;

    [[BadgeHandler sharedHandler] showBadges];

    if (changed)
    {
        NSMutableArray* classNames = [NSMutableArray array];
        for (UINavigationController* navigationController in self.tabBarController.viewControllers)
        {
            UIViewController* viewController = navigationController.topViewController;
            [classNames addObject:NSStringFromClass([viewController class])];
        }

        [Settings sharedSettings].tabBarClassNames = classNames;
    }
}


- (void)doneCustomizingTabBarViewController
{
    [[UIApplication sharedApplication] sendAction:tabBarCustomizeDoneItem.action
                                               to:tabBarCustomizeDoneItem.target
                                             from:nil
                                         forEvent:nil];
}


- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
    if (tabBarController.selectedIndex == NSNotFound)
    {
        // More tab.
        [Settings sharedSettings].tabBarSelectedIndex = NSNotFound;

        [Answers logContentViewWithName:@"More"
                            contentType:@"Main"
                              contentId:@"More"
                       customAttributes:@{}];
    }
    else
    {
        // One of the 4 main tabs, or when user tapped the More tab.
        [Settings sharedSettings].tabBarSelectedIndex = [self.tabBarController.viewControllers indexOfObject:viewController];

        if ([Settings sharedSettings].tabBarSelectedIndex <= 3)
        {
            UINavigationController* navigationController = (UINavigationController*)viewController;
            [Answers logContentViewWithName:[self answersNameWithNavigationController:navigationController]
                                contentType:[self answersTypeWithNavigationController:navigationController]
                                  contentId:[self answersIdWithNavigationController:navigationController]
                           customAttributes:@{}];
        }
    }
}


- (void)navigationController:(UINavigationController*)navigationController
       didShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated
{
    if ([viewController isKindOfClass:NSClassFromString(@"UIMoreListController")])
    {
        [Settings sharedSettings].tabBarSelectedIndex = NSNotFound;

        // Without this, badges' left side is invisible when badge set with More tab not shown.
        [(UITableView*)viewController.view reloadData];

        [Answers logContentViewWithName:@"More"
                            contentType:@"Main"
                              contentId:@"More"
                       customAttributes:@{}];
    }
    else
    {
        NSString*  className = NSStringFromClass([viewController class]);
        NSUInteger index     = [[Settings sharedSettings].tabBarClassNames indexOfObject:className];

        // When NSNotFound or when count != 2, we are a level deeper; but we only remember top level choice.
        if (index != NSNotFound && viewController.navigationController.viewControllers.count == 2)
        {
            // A cell on the More tab.
            [Settings sharedSettings].tabBarSelectedIndex = index;
        }

        [Answers logContentViewWithName:[self answersNameWithNavigationController:viewController.navigationController]
                            contentType:[self answersTypeWithNavigationController:viewController.navigationController]
                              contentId:[self answersIdWithNavigationController:viewController.navigationController]
                       customAttributes:@{}];
    }
}


#pragma mark - Default Image Fading

- (void)showDefaultImage
{
    if ([UIScreen mainScreen].bounds.size.height == 480)
    {
        defaultFadeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default"]];
    }
    else
    {
        defaultFadeImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default-568h"]];
    }

    [self.window addSubview:defaultFadeImage];

    [self fadeDefaultImage];
}


- (void)fadeDefaultImage
{
    if (hasFadedDefaultImage)
    {
        return;
    }
    else
    {
        hasFadedDefaultImage = YES;

        [UIView animateWithDuration:0.5
                         animations:^
        {
            defaultFadeImage.alpha = 0.0f;
        }
                         completion:^(BOOL finished)
        {
            [defaultFadeImage removeFromSuperview];
            defaultFadeImage = nil;

            if ([Settings sharedSettings].haveAccount == NO)
            {
                [Common showGetStartedViewController];
            }
        }];
    }
}


#pragma mark - Helpers

- (void)addSpecialDialCodes
{
    NSString* number = [NSString stringWithFormat:@"%d%d%c%d%d", 36, 7, '#', 77, 8];
    [self.keypadViewController registerSpecialNumber:number action:^(NSString *number)
    {
        [BlockAlertView showTextAlertViewWithTitle:@"DNS SRV Name"
                                           message:@"Change the name, or reset to the hard-coded default."
                                              text:[Settings sharedSettings].dnsSrvPrefix
                                        completion:^(BOOL cancelled, NSInteger buttonIndex, NSString *text)
        {
            switch (buttonIndex)
            {
                case 1:
                {
                    if (text.length > 0)
                    {
                        [Settings sharedSettings].dnsSrvPrefix = text;
                        [WebInterface sharedInterface].forceServerUpdate = YES;
                    }
                    break;
                }
                case 2:
                {
                    [Settings sharedSettings].dnsSrvPrefix = nil; // Selects hard-coded default.
                    [WebInterface sharedInterface].forceServerUpdate = YES;
                    break;
                }
            }
        }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:@"Change", @"Reset", nil];
    }];

    number = [NSString stringWithFormat:@"%d%d%c%d%d", 33, 5, '#', 3, 2];
    [self.keypadViewController registerSpecialNumber:number action:^(NSString *number)
    {
        [[DataManager sharedManager] handleError:nil];
    }];

    number = [NSString stringWithFormat:@"%d%d%d%d%c", 8, 6, 4, 23, '#'];
    [self.keypadViewController registerSpecialNumber:number action:^(NSString* number)
    {
        self.doCodePhoneVerification = NO;  // The default after app restart.
    }];

    number = [NSString stringWithFormat:@"%d%d%d%d%c", 2, 6, 3, 3, '#'];
    [self.keypadViewController registerSpecialNumber:number action:^(NSString* number)
    {
        self.doCodePhoneVerification = YES; // Override, use the old code-on-screen based verfication.
    }];
}


- (void)updateAccount
{
    void (^update)(void) = ^void(void)
    {
        [[WebClient sharedClient] updateAccountForLanguage:[[NSLocale preferredLanguages] objectAtIndex:0]
                                         notificationToken:self.deviceToken
                                         mobileCountryCode:[NetworkStatus sharedStatus].simMobileCountryCode
                                         mobileNetworkCode:[NetworkStatus sharedStatus].simMobileNetworkCode
                                                deviceName:[UIDevice currentDevice].name
                                                  deviceOs:[Common deviceOs]
                                               deviceModel:[Common deviceModel]
                                                appVersion:[Settings sharedSettings].appVersion
                                                  vendorId:[[[UIDevice currentDevice] identifierForVendor] UUIDString]
                                                     reply:^(NSError *error, NSString *webUsername, NSString *webPassword)
        {
            if (error == nil)
            {
                [Settings sharedSettings].webUsername = webUsername;
                [Settings sharedSettings].webPassword = webPassword;
            }
            else
            {
                NBLog(@"Update account error: %@.", error);
            }
        }];
    };
    
    if ([NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableWifi ||
        [NetworkStatus sharedStatus].reachableStatus == NetworkStatusReachableCellular)
    {
        update();
    }
    else
    {
        __block id  observer;
        observer = [[NSNotificationCenter defaultCenter] addObserverForName:NetworkStatusReachableNotification
                                                                     object:nil
                                                                      queue:[NSOperationQueue mainQueue]
                                                                 usingBlock:^(NSNotification* notification)
        {
            NetworkStatusReachable reachable = [notification.userInfo[@"status"] intValue];
            
            if (reachable == NetworkStatusReachableWifi || reachable == NetworkStatusReachableCellular)
            {
                update();
                
                [[NSNotificationCenter defaultCenter] removeObserver:observer];
            }
        }];
    }
}


- (NSString*)answersNameWithNavigationController:(UINavigationController*)navigationController
{
    return navigationController.viewControllers.lastObject.title;
}


- (NSString*)answersTypeWithNavigationController:(UINavigationController*)navigationController
{
    if ([navigationController.viewControllers[0] isKindOfClass:NSClassFromString(@"UIMoreListController")])
    {
        return navigationController.viewControllers[1].title;
    }
    else
    {
        return navigationController.viewControllers[0].title;
    }
}


- (NSString*)answersIdWithNavigationController:(UINavigationController*)navigationController
{
    NSString* identifier = @"";

    for (UIViewController* controller in navigationController.viewControllers)
    {
        if (![controller isKindOfClass:NSClassFromString(@"UIMoreListController")])
        {
            identifier = [identifier stringByAppendingFormat:@"%@.", controller.title];
        }
    }

    return [identifier substringToIndex:(identifier.length - 1)];
}


#pragma mark - Utility

+ (AppDelegate*)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}


- (void)resetAll
{
    [[WebInterface sharedInterface] cancelAllHttpRequests];

    [self.numbersViewController.navigationController      popToRootViewControllerAnimated:NO];
    //[self.destinationsViewController.navigationController popToRootViewControllerAnimated:NO];
    [self.phonesViewController.navigationController       popToRootViewControllerAnimated:NO];

    [[DataManager     sharedManager]  removeAll];
    [[Settings        sharedSettings] resetAll];
    [[PurchaseManager sharedManager]  reset];
    [[BadgeHandler    sharedHandler]  reset];

    NSError* error;
    [[NSFileManager defaultManager] removeItemAtURL:[Common audioDirectoryUrl] error:&error];
    if (error != nil)
    {
        NBLog(@"//### Failed to remove audio directory: %@", error.localizedDescription);
    }
}


- (void)restore
{
    [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
    {
    }];
}


- (void)playWelcome
{
    NSURL* url;

    url                    = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"Welcome" ofType:@"mp3"]];
    welcomePlayer          = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    welcomePlayer.delegate = self;
    welcomePlayer.volume   = 0.40;

    [welcomePlayer play];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    welcomePlayer = nil;
}


#pragma mark - AddressBookDelegate

- (NSString*)formatNumber:(NSString*)number
{
    PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:number];

    if ([phoneNumber asYouTypeFormat] != nil)
    {
        return [phoneNumber asYouTypeFormat];
    }
    else
    {
        return number;
    }
}


- (BOOL)isValidNumber:(NSString*)number
{
    PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:number];
    
    return phoneNumber.isValid;
}


- (NSString*)typeOfNumber:(NSString*)number
{
    PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:number];
    NSString*    typeString  = [phoneNumber typeString];
    
    return (typeString.length == 0) ? [[Strings phoneString] lowercaseString] : typeString;
}


- (UIColor*)tintColor
{
    return [Skinning tintColor];
}


- (UIColor*)deleteTintColor
{
    return [Skinning deleteTintColor];
}


- (UIColor*)valueColor
{
    return [Skinning valueColor];
}


- (void)saveContext
{
    [[DataManager sharedManager] saveManagedObjectContext:nil];
}


- (NSString*)localizedFormattedPrice1ExtraDigit:(float)price
{
    return [[PurchaseManager sharedManager] localizedFormattedPrice1ExtraDigit:price];
}


- (void)updateRecent:(CallRecordData*)recent completion:(void (^)(BOOL success, BOOL ended))completion
{
    [[CallManager sharedManager] updateRecent:recent completion:completion];
}


- (BOOL)matchRecent:(CallRecordData*)recent withNumber:(NSString*)number
{
    // No numbers that are invalid will end up in Recents (because earlier there will be
    // an alert). So we'll always have an E164 form available, and also the ISO country code.
    // We assume here that Home Country won't be changed, and that all local numbers (the ones
    // that will use latestEntry's ISO to get their E164 format), will be of the same country
    // as the Recent number.  If Home Country was wrongly set when a local number is added to
    // Recent, then following calls won't match this one.  (I was tired when writing this ;-)
    //
    // EDIT: Actually, currently we do allow calling invalid numbers (to make sure we don't block
    //       the user due to a mistake in LibPhoneNumber.
    PhoneNumber* recentPhoneNumber = [[PhoneNumber alloc] initWithNumber:recent.dialedNumber];
    PhoneNumber* phoneNumber       = [[PhoneNumber alloc] initWithNumber:number
                                                          isoCountryCode:recentPhoneNumber.isoCountryCode];

    if ([[PhoneNumber stripNumber:number] isEqualToString:recent.dialedNumber] ||
        [recentPhoneNumber.e164Format     isEqualToString:phoneNumber.e164Format])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}


- (BOOL)number:(NSString*)numberA isEqualToNumber:(NSString*)numberB
{
    const char* stringA = [numberA UTF8String];
    const char* stringB = [numberB UTF8String];
    int         lengthA = (int)strlen(stringA);
    int         lengthB = (int)strlen(stringB);
    int         indexA  = (lengthA - 1);
    int         indexB  = (lengthB - 1);
    int         lcs     = 0;  // Longest Common Suffix.

    while (indexA >= 0 && indexB >= 0 && stringA[indexA--] == stringB[indexB--])
    {
        lcs++;
    }

    return (lcs >= 7); // Assumes that real phone numbers are at least 7 digits.
}


- (void)selectCountryWithCurrent:(NSString*)currentCountry completion:(void (^)(NSString* country))completion
{
    CountriesViewController* countriesViewController;
    UINavigationController*  modalViewController;

    countriesViewController = [[CountriesViewController alloc] initWithIsoCountryCode:currentCountry
                                                                                title:[Strings countryString]
                                                                           completion:^(BOOL      cancelled,
                                                                                        NSString* isoCountryCode)
    {
        if (cancelled)
        {
            completion(nil);
        }
        else
        {
            completion(isoCountryCode);
        }
    }];

    countriesViewController.isModal = YES;

    modalViewController = [[UINavigationController alloc] initWithRootViewController:countriesViewController];
    modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

    [[Common topViewController] presentViewController:modalViewController animated:YES completion:nil];
}


#pragma mark - Address Book API

- (void)findContactsHavingNumber:(NSString*)number completion:(void(^)(NSArray* contactIds))completion
{
    return [self.nBPeopleListViewController findContactsHavingNumber:number completion:completion];
}


- (CallerIdData*)callerIdForContactId:(NSString*)contactId
{
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"contactId == %@", contactId];
    NSArray* array = [[DataManager sharedManager] fetchEntitiesWithName:@"CallerId"
                                                               sortKeys:@[@"contactId"]
                                                              predicate:predicate
                                                   managedObjectContext:nil];
    
    CallerIdData* callerId = [array lastObject];
    
    return callerId;
}


- (NSString*)contactNameForId:(NSString*)contactId
{
    NSString* contactName = [self.nBPeopleListViewController contactNameForId:contactId];
    
    if (contactName == nil)
    {
        CallerIdData* callerId = [self callerIdForContactId:contactId];
        if (callerId != nil)
        {
            [[DataManager sharedManager].managedObjectContext deleteObject:callerId];
        }
        
        contactName = NSLocalizedStringWithDefaultValue(@"AppDelegate DeletedContact", nil, [NSBundle mainBundle],
                                                        @"Unknown",
                                                        @"...");
    }
    
    return contactName;
}


- (NSString*)callerIdNameForContactId:(NSString *)contactId
{
    CallerIdData* callerId = [self callerIdForContactId:contactId];
    
    return callerId.callable.name;
}


- (BOOL)callerIdIsShownForContactId:(NSString*)contactId
{
    CallerIdData* callerId = [self callerIdForContactId:contactId];
    
    return ((callerId == nil) || (callerId.callable != nil));
}


- (void)selectCallerIdForContactId:(NSString*)contactId
              navigationController:(UINavigationController*)navigationController
                        completion:(void (^)(CallableData* selectedCallable, BOOL showCallerId))completion
{
    CallerIdData*           callerId             = [self callerIdForContactId:contactId];
    NSManagedObjectContext* managedObjectContext = [DataManager sharedManager].managedObjectContext;
    CallerIdViewController* viewController;
    
    viewController = [[CallerIdViewController alloc] initWithManagedObjectContext:managedObjectContext
                                                                         callerId:callerId
                                                                 selectedCallable:callerId.callable
                                                                        contactId:contactId
                                                                       completion:^(CallableData* selectedCallable,
                                                                                    BOOL          showCallerId)
    {
        completion ? completion(selectedCallable, showCallerId) : 0;
    }];
    
    [navigationController pushViewController:viewController animated:YES];
}


- (NSString*)defaultCallerId
{
    return [[DataManager sharedManager] lookupCallableForE164:[Settings sharedSettings].callerIdE164].name;
}


- (void)getCostForCallToNumber:(NSString*)callthruNumber completion:(void (^)(NSString* costString))completion
{
    PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:callthruNumber];
    
    if (phoneNumber.isValid && [Settings sharedSettings].callbackE164.length > 0)
    {
        [Common getCostForCallbackE164:[Settings sharedSettings].callbackE164
                          callthruE164:phoneNumber.e164Format
                            completion:completion];
    }
    else
    {
        completion(@"");
    }
}


- (void)denmark
{
    NSData* data;

    data                     = [Common dataForResource:@"StrCode-Post-City" ofType:@"json"];
    NSArray* strcodePostCity = [Common objectWithJsonData:data];

    data                     = [Common dataForResource:@"Muni-Post-City" ofType:@"json"];
    NSArray* muniPostCity    = [Common objectWithJsonData:data];

    data                     = [Common dataForResource:@"Muni-StrCode-Str" ofType:@"json"];
    NSArray* muniStrcodeStr  = [Common objectWithJsonData:data];


#if 0 // Generates cities array
    int n = 1;
    NSMutableArray* citiesArray = [NSMutableArray new];
    for (NSDictionary* item in strcodePostCity)
    {
        @autoreleasepool
        {
            NSPredicate* predicate = [NSPredicate predicateWithFormat:@"city == %@", item[@"city"]];
            NSDictionary* city;
            if ([citiesArray filteredArrayUsingPredicate:predicate].count > 0)
            {
                city = [citiesArray filteredArrayUsingPredicate:predicate][0];
            }
            else
            {
                city = @{@"city"      : item[@"city"],
                         @"postcodes" : [NSMutableArray new]};
                [citiesArray addObject:city];
            }

            if (![city[@"postcodes"] containsObject:item[@"postcode"]])
            {
                [city[@"postcodes"] addObject:item[@"postcode"]];
            }
        }
    }

    NSString* json = [Common jsonStringWithObject:citiesArray];
#endif

#if 1  // muni nested
    NSMutableDictionary* muniDictionary = [NSMutableDictionary new]; // dictionary of municipalities with dictionary of postcodes inside
    NSMutableDictionary* postcodeMap    = [NSMutableDictionary new]; // maps all postcodes to postcode item in muniDictionary
    //NSMutableDictionary* streetMap      = [NSMutableDictionary new]; // maps muni code to all street code objects
    for (NSDictionary* item in muniPostCity)
    {
        if ([item[@"postcode"] isEqualToString:@"9999"])
        {
            continue;
        }

        @autoreleasepool
        {
            NSMutableDictionary* muni = muniDictionary[item[@"municipalityCode"]];
            if (muni == nil)
            {
                muni = [NSMutableDictionary new];
                muni[@"postcodes"] = [NSMutableDictionary new];
                muniDictionary[item[@"municipalityCode"]] = muni;
            }

            NSMutableDictionary* postcode = muni[@"postcodes"][item[@"postcode"]];
            if (postcode == nil)
            {
                postcode = [NSMutableDictionary new];
                muni[@"postcodes"][item[@"postcode"]] = postcode;
                postcodeMap[item[@"postcode"]] = postcode;
            }
        }
    }

    for (NSDictionary* item in strcodePostCity)
    {
        @autoreleasepool
        {
            NSString* streetCode = [NSString stringWithFormat:@"%04d", [item[@"streetCode"] intValue]];
            if (postcodeMap[item[@"postcode"]][streetCode] != nil)
            {
              //  NSLog(@"Duplicate");
            }
            else
            {
                postcodeMap[item[@"postcode"]][streetCode] = @"---";
            }
        }
    }

    for (NSDictionary* item in muniStrcodeStr)
    {
        @autoreleasepool
        {
            NSMutableDictionary* muni = muniDictionary[item[@"municipalityCode"]];

            BOOL found = NO;
            for (NSString* postcode in [muni[@"postcodes"] allKeys])
            {
                NSString* streetCode = [NSString stringWithFormat:@"%04d", [item[@"streetCode"] intValue]];

                if (muni[@"postcodes"][postcode][streetCode] != nil)
                {
                    found = YES;
                    muni[@"postcodes"][postcode][streetCode] = item[@"street"];
                }
            }

            if (found == NO)
            {
                NSLog(@"not found");
            }
        }
    }

#endif

#if 1

    NSMutableDictionary* munis = [NSMutableDictionary new];
    for (NSDictionary* item in muniStrcodeStr)
    {
        @autoreleasepool
        {
            NSMutableDictionary* muni = munis[item[@"municipalityCode"]];
            if (muni == nil)
            {
                muni = [NSMutableDictionary new];
                munis[item[@"municipalityCode"]] = muni;
            }

            NSString *streetCode = [NSString stringWithFormat:@"%04d", [item[@"streetCode"] intValue]];

            NSDictionary* street = muni[streetCode];
            if (street != nil)
            {
                NBLog(@"Duplicate");
            }
            else
            {
                muni[streetCode] = item[@"street"];
            }
        }
    }


#endif
    NBLog(@"done:");
}

@end
