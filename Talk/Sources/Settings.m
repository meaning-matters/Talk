//
//  Settings.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//
//  In Talk we want to save both the SIP username and SIP password in keychain.
//  So we store both these strings as 'password' under names/keys "SipUsername"
//  and "SipPassword" respectively.  So these two are not saved in UserDefaults.
//

#import "Settings.h"
#import "NetworkStatus.h"
#import "KeychainUtility.h"

NSString* const TabBarViewControllerClassesKey = @"TabBarViewControllerClasses";
NSString* const HomeCountryKey                 = @"HomeCountryKey";
NSString* const HomeCountryFromSimKey          = @"HomeCountryFromSim";
NSString* const LastDialedNumberKey            = @"LastDialedNumber";
NSString* const SipUsernameKey                 = @"SipUsername";            // Used as keychain 'username'.
NSString* const SipPasswordKey                 = @"SipPassword";            // Used as keychain 'username'.
NSString* const SipServiveKey                  = @"SipAccount";             // Used as keychain service.
NSString* const RunBefore                      = @"RunBefore";


@implementation Settings

static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;

@synthesize tabBarViewControllerClasses = _tabBarViewControllerClasses;
@synthesize homeCountry                 = _homeCountry;
@synthesize homeCountryFromSim          = _homeCountryFromSim;
@synthesize lastDialedNumber            = _lastDialedNumber;
@synthesize sipUsername                 = _sipUsername;
@synthesize sipPassword                 = _sipPassword;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Settings class] == self)
    {
        sharedSettings = [self new];
        userDefaults = [NSUserDefaults standardUserDefaults];

        [sharedSettings registerDefaults];
        [sharedSettings getInitialValues];

        if ([userDefaults boolForKey:RunBefore] == NO)
        {
            [KeychainUtility deleteItemForUsername:SipUsernameKey andServiceName:SipServiveKey error:nil];
            [KeychainUtility deleteItemForUsername:SipPasswordKey andServiceName:SipServiveKey error:nil];
            
            [userDefaults setBool:YES forKey:RunBefore];
            [userDefaults synchronize];
        }
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

    [defaults setObject:@"" forKey:LastDialedNumberKey];

    [userDefaults registerDefaults:defaults];
}


- (void)getInitialValues
{
    _tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
    _homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    _homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
    _lastDialedNumber            = [userDefaults objectForKey:LastDialedNumberKey];
}


#pragma mark - Setters

- (void)setTabBarViewControllerClasses:(NSArray*)tabBarViewControllerClasses
{
    _tabBarViewControllerClasses = tabBarViewControllerClasses;
    [userDefaults setObject:tabBarViewControllerClasses forKey:TabBarViewControllerClassesKey];
}


- (void)setHomeCountry:(NSString*)homeCountry
{
    _homeCountry = homeCountry;
    [userDefaults setObject:homeCountry forKey:HomeCountryKey];
}


- (void)setHomeCountryFromSim:(BOOL)homeCountryFromSim
{
    _homeCountryFromSim = homeCountryFromSim;
    [userDefaults setBool:homeCountryFromSim forKey:HomeCountryFromSimKey];
}


- (void)setLastDialedNumber:(NSString *)lastDialedNumber
{
    _lastDialedNumber = lastDialedNumber;
    [userDefaults setObject:lastDialedNumber forKey:LastDialedNumberKey];
}

@end
