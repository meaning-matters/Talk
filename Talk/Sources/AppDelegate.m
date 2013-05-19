
//
//  AppDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//### Want to remove CoreData? http://www.gravitywell.co.uk/blog/post/how-to-quickly-add-core-data-to-an-app-in-xcode-4

#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
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


@interface AppDelegate ()
{
    NSMutableArray* defaultTabBarViewControllers;
    UIImageView*    defaultFadeImage;
    BOOL            hasFadedDefaultImage;
}

@end


@implementation AppDelegate

- (void)setUp
{
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^
    {
        // Trigger singletons.
        [Skinning      sharedSkinning];
        [NetworkStatus sharedStatus];   // Called early: because it needs UIApplicationDidBecomeActiveNotification.
        [CallManager   sharedManager];
        [DataManager   sharedManager];

        // Initialize phone number stuff.
        [PhoneNumber setDefaultBaseIsoCountryCode:[Settings sharedSettings].homeCountry];
        [LibPhoneNumber sharedInstance];    // This loads the JavaScript library.

        // Basic UI.
        self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
        self.tabBarController = [[UITabBarController alloc] init];
        self.tabBarController.delegate = self;

        // Must be placed here, just before tabs are added.  Otherwise navigation bar
        // will overlap with status bar.
        [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];

        [self addViewControllersToTabBar];
        self.window.rootViewController = self.tabBarController;
        [self.window makeKeyAndVisible];

        [self showDefaultImage];

        [[AVAudioSession sharedInstance] setActive:YES error:nil]; // Make sure there's an audio session.
        [[NSNotificationCenter defaultCenter] addObserver:self
#warning Do with block, instead of method.
                                                 selector:@selector(keepVolumeAboveZero:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
    });
}


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
#warning Don't forget to remove, and to switch to NO 'Application supports iTunes file sharing' in .plist.
    // [Common redirectStderrToFile];

    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert];

    if ([UIApplication sharedApplication].protectedDataAvailable)
    {
        [self setUp];
    }

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
    [self performSelectorOnMainThread:@selector(answer_call) withObject:nil waitUntilDone:YES];
}


- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
}


#pragma mark - Helper Methods

- (void)keepVolumeAboveZero:(NSNotification*)notification
{
    if ([MPMusicPlayerController applicationMusicPlayer].volume < 0.1)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05f * NSEC_PER_SEC), dispatch_get_main_queue(), ^
        {
            [[MPMusicPlayerController applicationMusicPlayer] setVolume:0.1];
        });
    }
}


#pragma mark - TabBar Delegate & General

- (void)addViewControllersToTabBar
{
    NSArray* viewControllerClasses = @[NSStringFromClass([NumbersViewController     class]),
                                       //NSStringFromClass([RecentsViewController     class]),
                                       //NSStringFromClass([GroupsViewController      class]),
                                       NSStringFromClass([DialerViewController      class]),
                                       NSStringFromClass([ForwardingsViewController class]),
                                       //NSStringFromClass([CreditViewController      class]),
                                       //NSStringFromClass([HelpViewController        class]),
                                       //NSStringFromClass([AboutViewController       class]),
                                       NSStringFromClass([SettingsViewController    class]),
                                       //NSStringFromClass([ShareViewController       class])];
                                       ];
    NSSet*  preferredSet = [NSSet setWithArray:[Settings sharedSettings].tabBarViewControllerClasses];
    NSSet*  defaultSet   = [NSSet setWithArray:viewControllerClasses];

    if ([preferredSet isEqualToSet:defaultSet])
    {
        // No view controllers were added/deleted/renamed.  Safe to use preferred set.
        viewControllerClasses = [Settings sharedSettings].tabBarViewControllerClasses;
    }
    else
    {
        // First time, or view controllers were added/deleted/renamed.  Reset preferred set.
        [Settings sharedSettings].tabBarViewControllerClasses = viewControllerClasses;
    }

    NSMutableArray* viewControllers = [NSMutableArray array];
    for (NSString* class in viewControllerClasses)
    {
        // All view controllers are embedded in a navigation controller.
        UIViewController*   viewController = [[NSClassFromString(class) alloc] init];
        [viewControllers addObject:viewController.navigationController];

        // Set appropriate AppDelegate property.
        SEL selector = NSSelectorFromString([@"set" stringByAppendingFormat:@"%@:", [class description]]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:[[viewControllers lastObject] topViewController]];
#pragma clang diagnostic pop
    }

    defaultTabBarViewControllers = viewControllers;
    self.tabBarController.viewControllers = viewControllers;
}


- (void)setDefaultTabBarViewControllers
{
    [self.tabBarController setViewControllers:defaultTabBarViewControllers animated:YES];
}


- (void)tabBarController:(UITabBarController*)tabBarController didSelectViewController:(UIViewController*)viewController
{
}


- (void)tabBarController:(UITabBarController*)tabBarController willBeginCustomizingViewControllers:(NSArray*)viewControllers
{
    id customizeView = [[tabBarController view] subviews][1];
    if([customizeView isKindOfClass:NSClassFromString(@"UITabBarCustomizeView")] == YES)
    {
        UINavigationBar*    navigationBar = (UINavigationBar*)[customizeView subviews][0];
        if ([navigationBar isKindOfClass:[UINavigationBar class]])
        {
            navigationBar.topItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemUndo
                                                                                                    target:self
                                                                                                    action:@selector(setDefaultTabBarViewControllers)];
        }
    }
}


- (void)tabBarController:(UITabBarController*)tabBarController willEndCustomizingViewControllers:(NSArray*)viewControllers changed:(BOOL)changed
{
    if (changed)
    {
        NSMutableArray* viewControllerClasses = [NSMutableArray array];
        for (UINavigationController* navigationController in self.tabBarController.viewControllers)
        {
            Class   class = [navigationController.topViewController class];
            [viewControllerClasses addObject:NSStringFromClass(class)];
        }

        [Settings sharedSettings].tabBarViewControllerClasses = viewControllerClasses;
        defaultTabBarViewControllers = [NSMutableArray arrayWithArray:viewControllers];
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

    [[DataManager sharedManager] removeAll];

    [[Settings sharedSettings] resetAll];

    NSError*    error;
    [[NSFileManager defaultManager] removeItemAtURL:[Common audioDirectoryUrl] error:&error];
    if (error != nil)
    {
        NSLog(@"//### Failed to remove audio directory: %@", [error localizedDescription]);
    }
}

@end
