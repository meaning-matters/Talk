
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


@interface AppDelegate ()
{
    NSMutableArray* defaultTabBarViewControllers;
}

@end


@implementation AppDelegate

@synthesize managedObjectContext       = _managedObjectContext;
@synthesize managedObjectModel         = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;


- (BOOL)application:(UIApplication*)application didFinishLaunchingWithOptions:(NSDictionary*)launchOptions
{
    [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeSound |
     UIRemoteNotificationTypeAlert];
/*
    //### Set current fixed SIP credentials.
    [Settings sharedSettings].sipServer   = @"178.63.93.9";
    [Settings sharedSettings].sipRealm    = @"*";
    [Settings sharedSettings].sipUsername = @"1000";
    [Settings sharedSettings].sipPassword = @"1234azertytettn";
*/
    // Trigger singletons.
    [Skinning        sharedSkinning];
    [NetworkStatus   sharedStatus];   // Called early: because it needs UIApplicationDidBecomeActiveNotification.
    [CallManager     sharedManager];

    // Initialize phone number stuff.
    [PhoneNumber setDefaultBaseIsoCountryCode:[Settings sharedSettings].homeCountry];
    [LibPhoneNumber sharedInstance];    // This loads the JavaScript library.
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;

    // Must be placed here, just before tabs are added.  Otherwise navigation bar
    // will overlap with status bar.
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];

    [self addViewControllersToTabBar];
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];

    [[AVAudioSession sharedInstance] setActive:YES error:NULL]; // Make sure there's an audio session.
    [[NSNotificationCenter defaultCenter] addObserver:self
#warning Do with block, instead of method.
                                             selector:@selector(keepVolumeAboveZero:)
                                                 name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                               object:nil];

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
    [self saveContext];
}


- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)token
{
    NSString *string = [[token description] stringByReplacingOccurrencesOfString:@" " withString:@""];
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


#pragma mark - Core Data

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext*)managedObjectContext
{
    if (_managedObjectContext != nil)
    {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }

    return _managedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel*)managedObjectModel
{
    if (_managedObjectModel != nil)
    {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"CoreDataTemplate" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    
    return _managedObjectModel;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator*)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil)
    {
        return _persistentStoreCoordinator;
    }

    NSURL*      storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataTemplate.sqlite"];
    NSError*    error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:nil
                                                           error:&error])
    {
#warning //### Replace this implementation with code to handle the error appropriately.
         /* abort() causes the application to generate a crash log and terminate. You should not use this
          function in a shipping application, although it may be useful during development.

         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.


         If the persistent store is not accessible, there is typically something wrong with the file path. 
          Often, a file URL is pointing into the application's resources directory instead of a writeable directory.

         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]

         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}

         Lightweight migration will only work for a limited set of schema changes; consult 
          "Core Data Model Versioning and Data Migration Programming Guide" for details.
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }

    return _persistentStoreCoordinator;
}


- (void)saveContext
{
    NSError*                error = nil;
    NSManagedObjectContext* managedObjectContext = self.managedObjectContext;
    
    if (managedObjectContext != nil)
    {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error])
        {
#warning    //### Replace this implementation with code to handle the error appropriately.
            //    abort() causes the application to generate a crash log and terminate.
            //    You should not use this function in a shipping application, although it
            //    may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}


- (NSURL*)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


+ (AppDelegate*)appDelegate
{
    return (AppDelegate*)[UIApplication sharedApplication].delegate;
}

@end
