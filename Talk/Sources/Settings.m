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
NSString* const SipServerKey                   = @"SipServer";
NSString* const SipRealmKey                    = @"SipRealm";               // Used as keychain 'username'.
NSString* const SipUsernameKey                 = @"SipUsername";            // Used as keychain 'username'.
NSString* const SipPasswordKey                 = @"SipPassword";            // Used as keychain 'username'.
NSString* const SipServiveKey                  = @"SipAccount";             // Used as keychain service.
NSString* const RunBeforeKey                   = @"RunBefore";


@implementation Settings

static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;

@synthesize tabBarViewControllerClasses = _tabBarViewControllerClasses;
@synthesize homeCountry                 = _homeCountry;
@synthesize homeCountryFromSim          = _homeCountryFromSim;
@synthesize lastDialedNumber            = _lastDialedNumber;
@synthesize sipServer                   = _sipServer;
@synthesize sipRealm                    = _sipRealm;
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

        if ([userDefaults boolForKey:RunBeforeKey] == NO)
        {
            [KeychainUtility deleteItemForUsername:SipUsernameKey andServiceName:SipServiveKey error:nil];
            [KeychainUtility deleteItemForUsername:SipPasswordKey andServiceName:SipServiveKey error:nil];
            
            [userDefaults setBool:YES forKey:RunBeforeKey];
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

    if ([[NetworkStatus sharedStatus].simIsoCountryCode length] > 0)
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


- (NSString*)getKeychainValueForKey:(NSString*)key
{
    NSError*    error = nil;
    NSString*   value;

    value = [KeychainUtility getPasswordForUsername:key andServiceName:SipServiveKey error:&error];
    if (value == nil && error != nil)
    {
        NSLog(@"//### Error getting value from keychain: %@", [error localizedDescription]);
    }

    return value;
}


- (void)storeKeychainValue:(NSString*)value forKey:(NSString*)key
{
    NSError*    error = nil;

    if ([KeychainUtility storeUsername:key andPassword:value forServiceName:SipServiveKey updateExisting:YES error:&error] == NO)
    {
        NSLog(@"//### Error storing value in keychain: %@", [error localizedDescription]);
    }
}


- (void)getInitialValues
{
    // We assign to property (with self.xyz, instread of to _xyz) so that a value that
    // was added as default (in registerDefaults) is saved as normal setting.
    
    self.tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
    self.homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    self.homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
    self.lastDialedNumber            = [userDefaults objectForKey:LastDialedNumberKey];
    self.sipServer                   = [userDefaults objectForKey:SipServerKey];
    self.sipRealm                    = [self getKeychainValueForKey:SipRealmKey];
    self.sipUsername                 = [self getKeychainValueForKey:SipUsernameKey];
    self.sipPassword                 = [self getKeychainValueForKey:SipPasswordKey];
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


- (void)setLastDialedNumber:(NSString*)lastDialedNumber
{
    _lastDialedNumber = lastDialedNumber;
    [userDefaults setObject:lastDialedNumber forKey:LastDialedNumberKey];
}


- (void)setSipServer:(NSString *)sipServer
{
    _sipServer = sipServer;
    [userDefaults setObject:sipServer forKey:SipServerKey];
}


- (void)setSipRealm:(NSString*)sipRealm
{
    _sipRealm = sipRealm;
    [self storeKeychainValue:sipRealm forKey:SipRealmKey];
}


- (void)setSipUsername:(NSString*)sipUsername
{
    _sipUsername = sipUsername;
    [self storeKeychainValue:sipUsername forKey:SipUsernameKey];
}


- (void)setSipPassword:(NSString*)sipPassword
{
    _sipPassword = sipPassword;
    [self storeKeychainValue:sipPassword forKey:SipPasswordKey];
}

@end
