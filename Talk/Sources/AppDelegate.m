
//
//  AppDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AppDelegate.h"
#import "Settings.h"
#import "PhoneNumber.h"
#import "Skinning.h"
#import "NetworkStatus.h"
#import "LibPhoneNumber.h"
#import "CallManager.h"
#import "CallViewController.h"


@interface AppDelegate ()
{
    NSMutableArray* defaultTabBarViewControllers;
}

@end


@implementation AppDelegate

@synthesize tabBarController          = _tabBarController;
@synthesize aboutViewController       = _aboutViewController;
@synthesize creditViewController      = _creditViewController;
@synthesize dialerViewController      = _dialerViewController;
@synthesize forwardingsViewController = _forwardingsViewController;
@synthesize groupsViewController      = _groupsViewController;
@synthesize helpViewController        = _helpViewController;
@synthesize numbersViewController     = _numbersViewController;
@synthesize recentsViewController     = _recentsViewController;
@synthesize shareViewController       = _shareViewController;
@synthesize settingsViewController    = _settingsViewController;


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
[Settings sharedSettings].sipRealm = nil;

    // Trigger singletons.
    [Skinning      sharedSkinning];
    [NetworkStatus sharedStatus];   // Called early: because it needs UIApplicationDidBecomeActiveNotification.
    [CallManager   sharedManager];
    [Settings      sharedSettings];

    //### Set current fixed SIP credentials.
    [Settings sharedSettings].sipServer   = @"178.63.93.9";
    [Settings sharedSettings].sipRealm    = @"*";
    [Settings sharedSettings].sipUsername = @"1000";
    [Settings sharedSettings].sipPassword = @"1234azertytettn";

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;

    // Must be placed here, just before tabs are added.  Otherwise navigation bar
    // will overlap with status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];

    [self addViewControllersToTabBar];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    // Initialize phone number stuff.
    [PhoneNumber setDefaultBaseIsoCountryCode:[Settings sharedSettings].homeCountry];
    [LibPhoneNumber sharedInstance];    // This loads the JavaScript library.

    // Connect Dialer and CallManager via AppDelegate.
    self.dialerViewController.delegate = self;

    return YES;
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


- (void)application:(UIApplication*)application didReceiveLocalNotification:(UILocalNotification*)notification
{
    [self performSelectorOnMainThread:@selector(answer_call) withObject:nil waitUntilDone:YES];
}


- (void)application:(UIApplication*)application didReceiveRemoteNotification:(NSDictionary*)userInfo
{
}


#pragma mark - TabBar Delegate & General

- (void)addViewControllersToTabBar
{
    NSArray* viewControllerClasses = @[NSStringFromClass([NumbersViewController     class]),
                                       NSStringFromClass([RecentsViewController     class]),
                                       NSStringFromClass([GroupsViewController      class]),
                                       NSStringFromClass([DialerViewController      class]),
                                       NSStringFromClass([ForwardingsViewController class]),
                                       NSStringFromClass([CreditViewController      class]),
                                       NSStringFromClass([HelpViewController        class]),
                                       NSStringFromClass([AboutViewController       class]),
                                       NSStringFromClass([SettingsViewController    class]),
                                       NSStringFromClass([ShareViewController       class])];
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
    id customizeView = [[[tabBarController view] subviews] objectAtIndex:1];
    if([customizeView isKindOfClass:NSClassFromString(@"UITabBarCustomizeView")] == YES)
    {
        UINavigationBar*    navigationBar = (UINavigationBar*)[[customizeView subviews] objectAtIndex:0];
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


#pragma mark - Dialer Delegate

- (BOOL)dialerViewController:(DialerViewController*)dialerViewController
             callPhoneNumber:(PhoneNumber*)phoneNumber
{
    CallViewController* callViewController = [[CallViewController alloc] init];
    Call*               call = [[Call alloc] initWithPhoneNumber:phoneNumber direction:CallDirectionOut];
    [callViewController addCall:call];
    [[CallManager sharedManager] makeCall:call];
    
    callViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self.tabBarController presentViewController:callViewController
                                        animated:YES
                                      completion:nil];

    return YES;
}

@end
