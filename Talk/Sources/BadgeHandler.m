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
#import "CellBadgeView.h"
#import "TabBadgeView.h"


@interface BadgeHandler ()

@property (nonatomic, strong) UITabBarController* tabBarController;
@property (nonatomic, strong) NSArray*            tabBadgeViews;
@property (nonatomic, strong) NSMapTable*         viewControllerCounts;
@property (nonatomic, strong) UITableView*        moreTableView;

@end


@implementation BadgeHandler

+ (BadgeHandler*)sharedHandler
{
    static BadgeHandler*   sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[BadgeHandler alloc] init];

        sharedInstance.tabBarController = [AppDelegate appDelegate].tabBarController;

        [sharedInstance createTabBadgeViews];
        sharedInstance.viewControllerCounts = [NSMapTable mapTableWithKeyOptions:NSMapTableWeakMemory
                                                                    valueOptions:NSMapTableStrongMemory];

        [sharedInstance replaceMoreTableDataSource];
    });

    return sharedInstance;
}


- (void)createTabBadgeViews
{
    self.tabBadgeViews = @[[[TabBadgeView alloc] init],
                           [[TabBadgeView alloc] init],
                           [[TabBadgeView alloc] init],
                           [[TabBadgeView alloc] init],
                           [[TabBadgeView alloc] init]];

    CGFloat width = self.tabBarController.view.frame.size.width;
    for (NSUInteger index = 0; index < self.tabBadgeViews.count; index++)
    {
        TabBadgeView* tabBadgeView = self.tabBadgeViews[index];
        tabBadgeView.frame = CGRectMake(index * (width / 5.0f) + 42.0f,
                                        3.0f,
                                        tabBadgeView.frame.size.width,
                                        tabBadgeView.frame.size.height);
    }
}


- (void)setBadgeCount:(NSUInteger)count forViewController:(UIViewController*)viewController
{
    [self.viewControllerCounts setObject:@(count) forKey:viewController];

    if (![self isOnMoreViewController:viewController])
    {
        NSUInteger index = [self.tabBarController.viewControllers indexOfObject:viewController.navigationController];

        [self setBadgeCount:count atIndex:index];
    }

    [self update];
}


- (void)setBadgeCount:(NSUInteger)count atIndex:(NSUInteger)index
{
    TabBadgeView* tabBadgeView = self.tabBadgeViews[index];
    if (count == 0)
    {
        [tabBadgeView removeFromSuperview];
    }
    else
    {
        [self.tabBarController.tabBar addSubview:tabBadgeView];
        tabBadgeView.count = count;
    }
}


- (void)update
{
    [self updateMoreBadgeCount];
    [self updateAppBadgeCount];
}


- (void)updateMoreBadgeCount
{
    NSUInteger        count = 0;

    NSEnumerator*     enumerator = [self.viewControllerCounts keyEnumerator];
    UIViewController* viewController;
    while ((viewController = [enumerator nextObject]))
    {
        if ([self isOnMoreViewController:viewController])
        {
            count += [[self.viewControllerCounts objectForKey:viewController] integerValue];
        }
    }

    [self setBadgeCount:count atIndex:4];

    UITableView* tableView;
    tableView = (UITableView*)self.tabBarController.moreNavigationController.viewControllers[0].view;
    [tableView reloadData];

    // Force view controllers with a badge to load.
    (void)[AppDelegate appDelegate].numbersViewController.view;
}


- (void)updateAppBadgeCount
{
    NSUInteger        count = 0;
    NSEnumerator*     enumerator = [self.viewControllerCounts keyEnumerator];
    UIViewController* viewController;
    while ((viewController = [enumerator nextObject]))
    {
        count += [[self.viewControllerCounts objectForKey:viewController] integerValue];
    }

    [UIApplication sharedApplication].applicationIconBadgeNumber = count;
}


#pragma mark - Helpers

- (NSUInteger)isOnMoreViewController:(UIViewController*)viewController
{
    NSUInteger index;

    index = [self.tabBarController.viewControllers indexOfObject:viewController.parentViewController];

    return (index > 4) || (index == NSNotFound); // NSNotFound occurs if view controller is on More and is visible.
}


#pragma mark - More-Tab Magic

- (void)replaceMoreTableDataSource
{
    UINavigationController* navigationController = self.tabBarController.moreNavigationController;
    UIViewController*       listViewController   = navigationController.viewControllers[0];

    self.moreTableView = (UITableView*)listViewController.view;

    self.moreTableDataSource = self.moreTableView.dataSource;
    self.moreTableView.dataSource = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self.moreTableView reloadData];
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


// Silence the compiler.
- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.moreTableDataSource tableView:tableView numberOfRowsInSection:section];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*  cell           = [self.moreTableDataSource tableView:tableView cellForRowAtIndexPath:indexPath];
    UIViewController* viewController = [self viewControllerAtMoreIndexPath:indexPath];
    NSUInteger        count          = [[self.viewControllerCounts objectForKey:viewController] integerValue];

    [CellBadgeView addToCell:cell count:count];

    return cell;
}


- (UIViewController*)viewControllerAtMoreIndexPath:(NSIndexPath*)indexPath
{
    UINavigationController* navigationController;
    UIViewController*       viewController;

    navigationController = [self.tabBarController.viewControllers objectAtIndex:indexPath.row + 4];

    // When a view controller on the More tab is visible, its own navigation controller
    // has been replaced by that of the tab bar.  Of course this makes sense because it has
    // has been pushed on the More's navigation stack.
    //
    // The nasty thing is that we can now no longer reach the view controller directly.
    // However, as a side-effect of the above, the view controller's navigation controller
    // is now pointing to the tab bar's `moreNavigationController`.
    //
    // By iterating all tab bar view controllers, we can still find the original navigation
    // controller; it's the one that has `moreNavigationController` as navigation controller;
    // this is when the user tapped that More list cell.  Alternatively, the view controller's
    // navigation controller is nil when the user pops back to the More list.
    if (navigationController.viewControllers.count == 0)
    {
        for (viewController in [AppDelegate appDelegate].viewControllers)
        {
            if (viewController.navigationController == self.tabBarController.moreNavigationController ||
                viewController.navigationController == nil)
            {
                break;
            }
        }
    }
    else
    {
        viewController = navigationController.viewControllers[0];
    }

    return viewController;
}

@end
