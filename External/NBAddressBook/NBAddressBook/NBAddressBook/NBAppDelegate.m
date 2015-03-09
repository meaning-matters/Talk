//
//  NBAppDelegate.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import "NBAppDelegate.h"
#import "NBPeoplePickerNavigationController.h"
#import "NBRecentsNavigationController.h"
#import "NBPeopleListViewController.h"
#import "NBRecentsListViewController.h"
#import "TestRandomViewController.h"

@implementation NBAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    //Delete the 3000 contacts
//    ABAddressBookRef addressBook = [[NBAddressBookManager sharedManager] getAddressBook];
//    NSArray * allContacts = (__bridge NSArray *)(ABAddressBookCopyArrayOfAllPeople(addressBook));
//    for( id contact in allContacts )
//    {
//        ABRecordRef contactRef = (__bridge ABRecordRef)contact;
//        if( [[NBContact getStringProperty:kABPersonFirstNameProperty forContact:contactRef] isEqualToString:@"DELETEME"])
//            ABAddressBookRemoveRecord(addressBook, contactRef, nil);       
//    }
    
    
        //Insert 3000 random contacts
//    NSString * alphabet = @"abcdefghijklmnopqrstuvwxyz  ";
//    for( int i =0 ; i < 3000; i++)
//    {
//        ABRecordRef contact = ABPersonCreate();
//        int nameLength =arc4random()%15 + 1;
//        NSMutableString * nameString = [NSMutableString string];
//        for( int namePos = 0; namePos < nameLength; namePos++ )
//        {
//            [nameString appendString:[alphabet substringWithRange:NSMakeRange(namePos, 1)]];
//        }
//        NSString * number = [NSString stringWithFormat:@"%d", (arc4random()%899999999)+99999999];
//        ABMutableMultiValueRef numberMulti = ABMultiValueCreateMutable(kABMultiStringPropertyType);
//        ABMultiValueAddValueAndLabel(numberMulti, (__bridge CFTypeRef)number, (__bridge CFStringRef)@"home", NULL);
//        ABRecordSetValue(contact, kABPersonPhoneProperty, numberMulti, nil);
//        
//        //Add the contact
//        ABRecordSetValue(contact, kABPersonFirstNameProperty, (__bridge CFTypeRef)nameString, NULL);
//        ABAddressBookAddRecord(addressBook, contact, nil);
//    }
//    ABAddressBookSave(addressBook, nil);
    
    //Ensure the app's status bar is handled properly with the camera activity
    [application setStatusBarHidden:NO];
    [application setStatusBarStyle:UIStatusBarStyleDefault];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //Create the recents tab
    NBRecentsNavigationController * recentsNavController = [[NBRecentsNavigationController alloc]init];
    recentsNavController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemRecents tag:0];
    [recentsNavController.tabBarItem setTitle:NSLocalizedString(@"CNT_RECENTS", @"")];
    
    //Create the contacts tab
    NBPeoplePickerNavigationController * listNavController = [[NBPeoplePickerNavigationController alloc]init];
    listNavController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemContacts tag:0];
    [listNavController.tabBarItem setTitle:NSLocalizedString(@"CNT_TITLE", @"")];
    
    //Create an unknown-number adding tab
    TestRandomViewController * testViewController = [[TestRandomViewController alloc]init];
    testViewController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0];
    [testViewController.tabBarItem setTitle:@"DEBUG"];
    
    //Create the tabbar controller and add the tabs
    tabbarController = [[UITabBarController alloc]init];
    tabbarController.delegate = self;
    [tabbarController setViewControllers:@[recentsNavController, listNavController, testViewController] animated:NO];
    
    //Set the selected tab
    tabbarController.selectedIndex = 0;
    
    //Add the tabbar controller
    [self.window setRootViewController:tabbarController];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACT object:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - Core Data stack
- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"NBRecents" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"NBRecents.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory
// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


@end
