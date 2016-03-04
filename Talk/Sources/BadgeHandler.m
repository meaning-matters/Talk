//
//  BadgeHandler.m
//  Talk
//
//  Created by Cornelis van der Bent on 03/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "BadgeHandler.h"
#import "AppDelegate.h"
#import "Settings.h"


@implementation BadgeHandler

+ (BadgeHandler*)sharedHandler
{
    static BadgeHandler*   sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[BadgeHandler alloc] init];

        [sharedInstance updateAllBadgeCounts];
    });

    return sharedInstance;
}


- (void)setAddressesBadgeCount:(NSUInteger)count
{
    [Settings sharedSettings].addressesBadgeCount = count;

    [self numbersTabBarItem].badgeValue = [self badgeValueForCount:count];

    [self updateMoreBadgeCount];
}


- (NSUInteger)addressesBadgeCount
{
    return [Settings sharedSettings].addressesBadgeCount;
}


- (void)decrementAddressesBadgeCount
{
    self.addressesBadgeCount -= 1;

    [self updateMoreBadgeCount];
}


- (void)updateMoreBadgeCount
{
    // Determine the total count of all tabs on More with a badge count.
    NSUInteger count = 0;

    // Numbers.
    if ([self indexOfTabBarItem:[self numbersTabBarItem]] > 4)
    {
        count += [Settings sharedSettings].addressesBadgeCount;
    }

    // ... <add tabs here in future>

    if (count > 0)
    {
        [self moreTabBarItem].badgeValue = [self badgeValueForCount:count];
    }
    else
    {
        [self moreTabBarItem].badgeValue = nil;
    }

    UITableView* tableView = (UITableView*)[AppDelegate appDelegate].tabBarController.moreNavigationController.topViewController.view;
    [tableView reloadData];
}


- (void)updateAllBadgeCounts
{
    [self numbersTabBarItem].badgeValue = [self badgeValueForCount:[Settings sharedSettings].addressesBadgeCount];

    [self updateMoreBadgeCount];

    // ... <add tabs here in future>
}


#pragma mark - Helpers

- (UITabBarItem*)numbersTabBarItem
{
    return [AppDelegate appDelegate].numbersViewController.navigationController.tabBarItem;
}


- (UITabBarItem*)moreTabBarItem
{
    return [AppDelegate appDelegate].tabBarController.tabBar.items[4];
}


- (NSString*)badgeValueForCount:(NSUInteger)count
{
    return [NSString stringWithFormat:@"%d", (int)count];
}


- (NSUInteger)indexOfTabBarItem:(UITabBarItem*)tabBarItem
{
    return [[AppDelegate appDelegate].tabBarController.tabBar.items indexOfObject:tabBarItem];
}

@end
