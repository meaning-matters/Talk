
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

@interface AppDelegate ()
{
    NSArray*    defaultTabBarViewControllers;
}

@end


@implementation AppDelegate

@synthesize sipInterface              = _sipInterface;
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
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;
    [self addViewControllersToTabBar];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    NSString*   sipConfigPath = [[NSBundle mainBundle] pathForResource:@"SipConfig" ofType:@"cfg"];

 //   self.sipInterface = [[SipInterface alloc] initWithConfigPath:sipConfigPath];
    
    PhoneNumber*    phoneNumber = [[PhoneNumber alloc] initWithNumber:@"0499298238"];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication*)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
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
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}


- (void)applicationWillTerminate:(UIApplication*)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
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
        [viewControllers addObject:[[NSClassFromString(class) alloc] init]];
        SEL selector = NSSelectorFromString([@"set" stringByAppendingFormat:@"%@:", [class description]]);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self performSelector:selector withObject:[viewControllers lastObject]];
#pragma clang diagnostic pop
    }

    self.tabBarController.viewControllers = viewControllers;

    // Save the 
    defaultTabBarViewControllers = @[self.numbersViewController,
                                     self.recentsViewController,
                                     self.groupsViewController,
                                     self.dialerViewController,
                                     self.forwardingsViewController,
                                     self.creditViewController,
                                     self.helpViewController,
                                     self.aboutViewController,
                                     self.settingsViewController,
                                     self.shareViewController];
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
            navigationBar.barStyle = UIBarStyleBlackOpaque;
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
        for (id viewController in self.tabBarController.viewControllers)
        {
            [viewControllerClasses addObject:NSStringFromClass([viewController class])];
        }

        [Settings sharedSettings].tabBarViewControllerClasses = viewControllerClasses;
    }
}

@end
