//
//  NBAppDelegate.h
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 Jasper Siebelink. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface NBAppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>
{
    //The tabbar controller
    UITabBarController * tabbarController;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
