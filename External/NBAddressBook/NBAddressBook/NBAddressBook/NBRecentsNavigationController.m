//
//  NBRecentsNavigationController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 7/18/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NBRecentsNavigationController.h"
#import "NBRecentsListViewController.h"

#ifdef NB_STANDALONE
#import "NBAppDelegate.h"
#endif

@implementation NBRecentsNavigationController

#ifndef NB_STANDALONE
- (instancetype)init
{
    if (self = [super initWithRootViewController:[[NBRecentsListViewController alloc] init]])
    {
        self.title            = NSLocalizedString(@"CNT_RECENTS", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"RecentsTab.png"];
    }

    return self;
}
#else
- (instancetype)init
{
    NSManagedObjectContext * context = [(NBAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    if (self = [super initWithRootViewController:[[NBRecentsListViewController alloc] initWithManagedObjectContext:context]])
    {
        self.title            = NSLocalizedString(@"CNT_RECENTS", @"");
        self.tabBarItem.image = [UIImage imageNamed:@"RecentsTab.png"];
    }
    
    return self;
}
#endif

@end
