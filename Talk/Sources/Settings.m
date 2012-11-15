//
//  Settings.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "Settings.h"
#import "NetworkStatus.h"

NSString* const TabBarViewControllerClassesKey = @"TabBarViewControllerClasses";
NSString* const HomeCountryKey                 = @"HomeCountryKey";
NSString* const HomeCountryFromSimKey          = @"HomeCountryFromSim";


@implementation Settings

static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;

@synthesize tabBarViewControllerClasses = _tabBarViewControllerClasses;
@synthesize homeCountry                 = _homeCountry;
@synthesize homeCountryFromSim          = _homeCountryFromSim;


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
    NSMutableDictionary*    defaults = [NSMutableDictionary dictionary];

    // Default for tabBarViewControllerClasses is handled in AppDelegate.

    if ([NetworkStatus sharedStatus].simIsoCountryCode != nil)
    {
        [defaults setObject:[NetworkStatus sharedStatus].simIsoCountryCode forKey:HomeCountryKey];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:HomeCountryFromSimKey];
    }
    else
    {
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:HomeCountryFromSimKey];
    }

    [userDefaults registerDefaults:defaults];
}


- (void)getInitialValues
{
    _tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
    _homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    _homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
}


#pragma mark - Setters

- (void)setTabBarViewControllerClasses:(NSArray*)tabBarViewControllerClasses
{
    [userDefaults setObject:tabBarViewControllerClasses forKey:TabBarViewControllerClassesKey];
    _tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
}


- (void)setHomeCountry:(NSString*)homeCountry
{
    [userDefaults setObject:homeCountry forKey:HomeCountryKey];
    _homeCountry = [userDefaults objectForKey:HomeCountryKey];
}


- (void)setHomeCountryFromSim:(BOOL)homeCountryFromSim
{
    [userDefaults setBool:homeCountryFromSim forKey:HomeCountryFromSimKey];
    _homeCountryFromSim = [userDefaults boolForKey:HomeCountryFromSimKey];
}

@end
