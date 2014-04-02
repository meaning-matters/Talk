
//
//  AppDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//### Want to remove CoreData? http://www.gravitywell.co.uk/blog/post/how-to-quickly-add-core-data-to-an-app-in-xcode-4

#import <MediaPlayer/MediaPlayer.h>
#import "HockeySDK.h"
#import "AppDelegate.h"
#import "Settings.h"
#import "PhoneNumber.h"
#import "Skinning.h"
#import "NetworkStatus.h"
#import "LibPhoneNumber.h"
#import "CallManager.h"
#import "CallViewController.h"
#import "PurchaseManager.h"
#import "DataManager.h"
#import "Common.h"
#import "BlockAlertView.h"
#import "Strings.h"


@interface AppDelegate ()
{
    UIImageView*    defaultFadeImage;
    BOOL            hasFadedDefaultImage;
    AVAudioPlayer*  welcomePlayer;
}

@end


@implementation AppDelegate

- (void)setUp
{
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^
    {
        // Trigger singletons.
        [NetworkStatus sharedStatus];   // Called early: because it needs UIApplicationDidBecomeActiveNotification.
        [CallManager   sharedManager];
        [DataManager   sharedManager];

        // Initialize phone number stuff.
        [PhoneNumber setDefaultIsoCountryCode:[Settings sharedSettings].homeCountry];
        [LibPhoneNumber sharedInstance];    // This loads the JavaScript library.

        // Set callback mode on, when there's no VoIP support.
        !HAS_VOIP ? [Settings sharedSettings].callbackMode = YES : 0;

        // Basic UI.
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.tabBarController = [[UITabBarController alloc] init];
        self.tabBarController.delegate = self;

        // Must be placed here, just before tabs are added.  Otherwise navigation bar
        // will overlap with status bar.
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

        [self addViewControllersToTabBar];
        self.window.rootViewController = self.tabBarController;
        self.window.backgroundColor    = [UIColor whiteColor];
        [self.window makeKeyAndVisible];

        // Apply skinning.
        [Skinning sharedSkinning];

        // Reset status bar style. Without this the status bar becomes white sometimes.
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];

        // Set address book delegate.
        [NBAddressBookManager sharedManager].delegate = self;

        // Allow mixing audio from other apps.  By default this is not the case.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient error:nil];

        // Welcome stuff.
        [self showDefaultImage];
        [self playWelcome];

#if HAS_VOIP
        [[AVAudioSession sharedInstance] setActive:YES error:nil]; // Make sure there's an audio session.
        [[NSNotificationCenter defaultCenter] addObserverForName:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if ([MPMusicPlayerController applicationMusicPlayer].volume < 0.1)
            {
                [Common dispatchAfterInterval:0.05 onMain:^
                {
                    [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.1];
                }];
            }
        }];
#endif
    });
}


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
#warning Don't forget to remove, and to switch to NO 'Application supports iTunes file sharing' in .plist.
    // [Common redirectStderrToFile];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge |
                                                                          UIRemoteNotificationTypeSound |
                                                                          UIRemoteNotificationTypeAlert];

    if ([UIApplication sharedApplication].protectedDataAvailable)
    {
        [self setUp];
    }

    [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"6abff73fa5eb64771ac8a5124ebc33f5" delegate:self];
    [[BITHockeyManager sharedHockeyManager] startManager];
    [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];

    return YES;
}


- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication*)application
{
    [self setUp];
}


- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for
    // certain types of temporary interruptions (such as an incoming phone call or SMS message) or
    // when the user quits the application and it begins the transition to the background state.
    //
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates.
    // Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication*)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication*)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication*)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication*)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)token
{
    NSString*   string = [[token description] stringByReplacingOccurrencesOfString:@" " withString:@""];
    self.deviceToken = [string substringWithRange:NSMakeRange(1, [string length] - 2)];   // Strip off '<' and '>'.

    // When account purchase transaction has not been finished, the PurchaseManager receives
    // it again at app startup.  This is however slightly earlier than that device token is
    // received.  Therefore the PurchaseManager is started up here.
    [PurchaseManager sharedManager];
}


- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
    self.deviceToken = nil;
}


- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    if (notification.userInfo != nil)
    {
        NSString*   source = [notification.userInfo objectForKey:@"source"];
        if (source != nil && [source isEqualToString:@"databaseError"])
        {
            [self restore];
        }
    }
}


- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
}


#pragma mark - General & TabBar Delegate & More Navigation Delegate

- (void)addViewControllersToTabBar
{
    // The order in this aryay defines the default tabs order.
    NSArray* tabBarClassNames =
    @[
        NSStringFromClass([CreditViewController               class]),
        NSStringFromClass([DialerViewController               class]),
        NSStringFromClass([NBPeoplePickerNavigationController class]),
        NSStringFromClass([NBRecentsNavigationController      class]),
        NSStringFromClass([PhonesViewController               class]),
#if HAS_BUYING_NUMBERS
        NSStringFromClass([NumbersViewController              class]),
        NSStringFromClass([ForwardingsViewController          class]),
#endif
        NSStringFromClass([SettingsViewController             class]),
        NSStringFromClass([HelpsViewController                class]),
        NSStringFromClass([AboutViewController                class]),
      //NSStringFromClass([ShareViewController                class]),
      //NSStringFromClass([GroupsViewController               class]),
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

    NSMutableArray* viewControllers = [NSMutableArray array];
    for (NSString* className in tabBarClassNames)
    {
        UIViewController* viewController = [[NSClassFromString(className) alloc] init];

        if ([className isEqualToString:NSStringFromClass([NBPeoplePickerNavigationController class])])
        {
            [viewControllers addObject:viewController];
            [self setPeoplePickerViewController:[viewControllers lastObject]];
        }
        else if ([className isEqualToString:NSStringFromClass([NBRecentsNavigationController class])])
        {
            [viewControllers addObject:viewController];
            [self setRecentsViewController:[viewControllers lastObject]];
        }
        else
        {
            UINavigationController* navigationController;

            navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
            [viewControllers addObject:navigationController];

            // Set appropriate AppDelegate property.
            SEL selector = NSSelectorFromString([@"set" stringByAppendingFormat:@"%@:", className]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self performSelector:selector withObject:[[viewControllers lastObject] topViewController]];
#pragma clang diagnostic pop
        }
    }

    self.tabBarController.viewControllers = viewControllers;
    if ([Settings sharedSettings].tabBarSelectedIndex == NSNotFound)
    {
        self.tabBarController.selectedViewController = self.tabBarController.moreNavigationController;
    }
    else
    {
        self.tabBarController.selectedViewController = viewControllers[[Settings sharedSettings].tabBarSelectedIndex];
    }

    self.tabBarController.moreNavigationController.delegate = self;
}


- (void)tabBarController:(UITabBarController*)tabBarController willBeginCustomizingViewControllers:(NSArray*)viewControllers
{
    id customizeView = [[tabBarController view] subviews][1];
    if ([customizeView isKindOfClass:NSClassFromString(@"UITabBarCustomizeView")] == YES)
    {
        UINavigationBar* navigationBar = (UINavigationBar*)[customizeView subviews][1];
        if ([navigationBar isKindOfClass:[UINavigationBar class]])
        {
            navigationBar.topItem.leftBarButtonItem.tintColor = [Skinning tintColor];
        }
    }
}


- (void)tabBarController:(UITabBarController*)tabBarController willEndCustomizingViewControllers:(NSArray*)viewControllers
                 changed:(BOOL)changed
{
    if (changed)
    {
        NSMutableArray* classNames = [NSMutableArray array];
        for (UINavigationController* navigationController in self.tabBarController.viewControllers)
        {
            UIViewController* viewController = navigationController.topViewController;
            [classNames addObject:[self classNameFromViewController:viewController]];
        }

        [Settings sharedSettings].tabBarClassNames = classNames;
    }
}


- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
    if (tabBarController.selectedIndex == NSNotFound)
    {
        // More tab.
        [Settings sharedSettings].tabBarSelectedIndex = NSNotFound;
    }
    else
    {
        [Settings sharedSettings].tabBarSelectedIndex = [self.tabBarController.viewControllers indexOfObject:viewController];
    }
}


- (void)navigationController:(UINavigationController*)navigationController
       didShowViewController:(UIViewController*)viewController
                    animated:(BOOL)animated
{
    if ([viewController isKindOfClass:NSClassFromString(@"UIMoreListController")])
    {
        [Settings sharedSettings].tabBarSelectedIndex = NSNotFound;
    }
    else
    {
        NSString*  className = [self classNameFromViewController:viewController];
        NSUInteger index     = [[Settings sharedSettings].tabBarClassNames indexOfObject:className];

        // When NSNotFound, we are a level deeper; but we only remember top level choice.
        if (index != NSNotFound)
        {
            [Settings sharedSettings].tabBarSelectedIndex = index;
        }
    }
}


- (NSString*)classNameFromViewController:(UIViewController*)viewController
{
    NSString* className = NSStringFromClass([viewController class]);

    if ([className isEqualToString:@"NBPeopleListViewController"])
    {
        return @"NBPeoplePickerNavigationController";
    }
    else if ([className isEqualToString:@"NBRecentsListViewController"])
    {
        return @"NBRecentsNavigationController";
    }
    else
    {
        return className;
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
    [self performSelector:@selector(fadeDefaultImage) withObject:nil afterDelay:2.0];
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

        [UIView animateWithDuration:1.0
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


#pragma mark - Utility

+ (AppDelegate*)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}


- (void)resetAll
{
#warning Stop things in background, like audio downloads. Especially for conflicts with CoreData being cleared.

    [self.numbersViewController.navigationController     popToRootViewControllerAnimated:NO];
    [self.forwardingsViewController.navigationController popToRootViewControllerAnimated:NO];
    [self.phonesViewController.navigationController      popToRootViewControllerAnimated:NO];

    [[DataManager     sharedManager]  removeAll];
    [[Settings        sharedSettings] resetAll];
    [[CallManager     sharedManager]  resetSipAccount];
    [[PurchaseManager sharedManager]  reset];

    NSError*    error;
    [[NSFileManager defaultManager] removeItemAtURL:[Common audioDirectoryUrl] error:&error];
    if (error != nil)
    {
        NSLog(@"//### Failed to remove audio directory: %@", error.localizedDescription);
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
    welcomePlayer.volume   = 0.25;

    [welcomePlayer play];
}


- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer*)player successfully:(BOOL)flag
{
    welcomePlayer = nil;
}


#pragma mark - Address Book Delegate

- (UIColor*)tintColor
{
    return [Skinning tintColor];
}


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


- (void)saveContext
{
    [[DataManager sharedManager] saveManagedObjectContext:nil];
}

@end
