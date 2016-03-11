//
//  BadgeHandler.m
//  Talk
//
//  Created by Cornelis van der Bent on 03/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//
//  The More-tab magic was found here: http://www.apeth.com/iOSBook/ch25.html#_uitabbar

#import "BadgeHandler.h"
#import "AppDelegate.h"
#import "Settings.h"
#import "Common.h"
#import "BadgeView.h"

NSString* const BadgeHandlerAddressUpdatesNotification = @"BadgeHandlerAddressUpdatesNotification";


@implementation BadgeHandler

+ (BadgeHandler*)sharedHandler
{
    static BadgeHandler*   sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[BadgeHandler alloc] init];

        [[NSNotificationCenter defaultCenter] addObserverForName:AppDelegateRemoteNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if (note.userInfo[@"addressUpdates"] != nil)
            {
                [sharedInstance processAddressUpdatesNotificationArray:note.userInfo[@"addressUpdates"]];
            }
        }];

        [sharedInstance replaceMoreTableDataSource];
    });

    return sharedInstance;
}


- (void)processAddressUpdatesNotificationArray:(NSArray*)array
{
    // Address updates are received as an array of dictionaries.  We convert
    // this to one dictionary because that's an easier to handle form in the app.
    NSMutableDictionary* addressUpdates = [self mutableDictionaryWithArray:array];

    // Settings contains the up-to-date state of address updates seen by user.
    // The server however only sends updates once, so the new set of updates
    // received by a notification must be OR-ed with the local set.
    for (NSString* addressId in [[Settings sharedSettings].addressUpdates allKeys])
    {
        if (addressUpdates[addressId] == nil)
        {
            addressUpdates[addressId] = [Settings sharedSettings].addressUpdates[addressId];
        }
    }

    [self saveAddressUpdates:addressUpdates];
}


- (void)saveAddressUpdates:(NSDictionary*)addressUpdates
{
    [Settings sharedSettings].addressUpdates = addressUpdates;
    [self update];

    [[NSNotificationCenter defaultCenter] postNotificationName:BadgeHandlerAddressUpdatesNotification
                                                        object:self
                                                      userInfo:addressUpdates];
}


- (void)removeAddressUpdate:(NSString*)addressId
{
    NSMutableDictionary* addressUpdates = [[Settings sharedSettings].addressUpdates mutableCopy];

    addressUpdates[addressId] = nil;

    [self saveAddressUpdates:addressUpdates];
}


- (NSDictionary*)addressUpdates
{
    return [Settings sharedSettings].addressUpdates;
}


- (NSUInteger)addressUpdatesCount
{
    return [[Settings sharedSettings].addressUpdates allKeys].count;
}


- (void)update
{
    [self updateMoreBadgeCount];
    [self updateAppBadgeCount];
}


- (void)updateMoreBadgeCount
{
    // Determine the total count of all tabs on More with a badge count.
    NSUInteger count = 0;

    // Numbers.
    if ([self isOnMoreViewController:[AppDelegate appDelegate].numbersViewController])
    {
        count += [self addressUpdatesCount];
    }

    // ... <add tabs here in future>

    if (count > 0)
    {
        [self moreTabBarItem].badgeValue = [NSString stringWithFormat:@"%d", (int)count];
    }
    else
    {
        [self moreTabBarItem].badgeValue = nil;
    }

    UITableView* tableView;
    tableView = (UITableView*)[AppDelegate appDelegate].tabBarController.moreNavigationController.topViewController.view;
    [tableView reloadData];

    // Force view controllers with a badge to load.
    (void)[AppDelegate appDelegate].numbersViewController.view;
}


- (void)updateAppBadgeCount
{
    NSUInteger count = 0;

    count += [self addressUpdatesCount];

    // ... <add tabs here in future>

    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}


- (UITabBarItem*)tabBarItemForViewController:(UIViewController*)viewController
{
    UITabBarItem* tabBarItem = nil;

    // When a view controller on the More tab is visible, its own navigation controller
    // has been replaced by that of the tab bar.  Of course this makes sense because it has
    // has been pushed on the More's navigation stack.
    //
    // The nasty thing is that we can now no longer reach the view controller tabBarItem.
    // However, as a side-effect of the above, the original navigation controller no longer
    // has children; because of course his only child is now More's child.
    //
    // By iterating all tab bar view controllers, we can still find the original navigation
    // controller and with that the tabBarItem; we simply search for the one with no children.
    if (viewController.navigationController == [AppDelegate appDelegate].tabBarController.moreNavigationController)
    {
        for (UINavigationController* navigationController in [AppDelegate appDelegate].tabBarController.viewControllers)
        {
            if (navigationController.childViewControllers.count == 0)
            {
                tabBarItem = navigationController.tabBarItem;
            }
        }
    }
    else
    {
        tabBarItem = viewController.navigationController.tabBarItem;
    }

    return tabBarItem;
}


#pragma mark - Helpers

- (UITabBarItem*)moreTabBarItem
{
    return [AppDelegate appDelegate].tabBarController.tabBar.items[4];
}


- (NSUInteger)isOnMoreViewController:(UIViewController*)viewController
{
    NSUInteger index;

    index = [[AppDelegate appDelegate].tabBarController.viewControllers indexOfObject:viewController.parentViewController];

    return (index > 4) || (index == NSNotFound); // NSNotFound occurs if view controller is on More and is visible.
}


- (NSMutableDictionary*)mutableDictionaryWithArray:(NSArray*)array
{
    NSMutableDictionary* mutableDictionary = [NSMutableDictionary dictionary];

    for (NSDictionary* dictionary in array)
    {
        [mutableDictionary addEntriesFromDictionary:dictionary];
    }

    return mutableDictionary;
}


#pragma mark - More-Tab Magic

- (void)replaceMoreTableDataSource
{
    UINavigationController* navigationController = [AppDelegate appDelegate].tabBarController.moreNavigationController;
    UIViewController*       listViewController   = navigationController.viewControllers[0];

    UITableView* moreTableView = (UITableView*)listViewController.view;

    self.moreTableDataSource = moreTableView.dataSource;
    moreTableView.dataSource = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [moreTableView reloadData];
    });
}


- (id)forwardingTargetForSelector:(SEL)selector
{
    if ([self.moreTableDataSource respondsToSelector:selector])
    {
        return self.moreTableDataSource;
    }
    else
    {
        return [super forwardingTargetForSelector:selector];
    }
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    // this is just to quiet the compiler
    return [self.moreTableDataSource tableView:tableView numberOfRowsInSection:section];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.moreTableDataSource tableView:tableView cellForRowAtIndexPath:indexPath];

    if (indexPath.row == 1)
    {
        BadgeView* badgeView = [[BadgeView alloc] init];
        [badgeView addToCell:cell];
        badgeView.count = 2;
        [badgeView addToCell:cell];
    }

    return cell;
}

@end
