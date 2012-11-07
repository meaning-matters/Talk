
//
//  AppDelegate.m
//  Talk
//
//  Created by Cornelis van der Bent on 28/09/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "AppDelegate.h"
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
@synthesize settingsVierController    = _settingsVierController;


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;

    self.aboutViewController       = [[AboutViewController       alloc] init];
    self.creditViewController      = [[CreditViewController      alloc] init];
    self.dialerViewController      = [[DialerViewController      alloc] init];
    self.forwardingsViewController = [[ForwardingsViewController alloc] init];
    self.groupsViewController      = [[GroupsViewController      alloc] init];
    self.helpViewController        = [[HelpViewController        alloc] init];
    self.numbersViewController     = [[NumbersViewController     alloc] init];
    self.recentsViewController     = [[RecentsViewController     alloc] init];
    self.shareViewController       = [[ShareViewController       alloc] init];
    self.settingsVierController    = [[SettingsViewController    alloc] init];

    self.tabBarController.viewControllers = @[self.numbersViewController,
                                              self.recentsViewController,
                                              self.groupsViewController,
                                              self.dialerViewController,
                                              self.forwardingsViewController,
                                              self.creditViewController,
                                              self.helpViewController,
                                              self.aboutViewController,
                                              self.settingsVierController,
                                              self.shareViewController];
    defaultTabBarViewControllers = [NSArray arrayWithArray:self.tabBarController.viewControllers];
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


#pragma mark - TabBar Delegate


- (void)setDefaultTabBarViewControllers
{
    [self.tabBarController setViewControllers:defaultTabBarViewControllers animated:YES];
}


- (BOOL)tabBarController:(UITabBarController*)tabBarController shouldSelectViewController:(UIViewController*)viewController
{
    return YES;
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
}


- (void)tabBarController:(UITabBarController*)tabBarController didEndCustomizingViewControllers:(NSArray*)viewControllers changed:(BOOL)changed
{
}

@end
