//
//  Settings.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Settings.h"

@implementation Settings

static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;

NSString* const TabBarViewControllerClassesKey = @"TabBarViewControllerClasses";


@synthesize tabBarViewControllerClasses = _tabBarViewControllerClasses;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Settings class] == self)
    {
        sharedSettings = [self new];
        userDefaults = [NSUserDefaults standardUserDefaults];

        [sharedSettings registerDefaults];
        [sharedSettings getInitialValues];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedSettings && [Settings class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate Settings singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (Settings*)sharedSettings
{
    return sharedSettings;
}


- (void)registerDefaults
{
    NSDictionary*   defaults = [NSDictionary dictionary];

    // Default for tabBarViewControllerClasses is handled in AppDelegate.

    //...

    [userDefaults registerDefaults:defaults];
}


- (void)getInitialValues
{
    _tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
}


#pragma mark - Setters

- (void)setTabBarViewControllerClasses:(NSArray*)tabBarViewControllerClasses
{
    [userDefaults setObject:tabBarViewControllerClasses forKey:TabBarViewControllerClassesKey];
}

@end
