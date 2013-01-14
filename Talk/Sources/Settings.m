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
//  Same applies to web API username and password.
//

#import "Settings.h"
#import "NetworkStatus.h"
#import "KeychainUtility.h"


NSString* const RunBeforeKey                   = @"RunBefore";
NSString* const TabBarViewControllerClassesKey = @"TabBarViewControllerClasses";
NSString* const ErrorDomainKey                 = @"ErrorDomain";
NSString* const HomeCountryKey                 = @"HomeCountry";
NSString* const HomeCountryFromSimKey          = @"HomeCountryFromSim";
NSString* const LastDialedNumberKey            = @"LastDialedNumber";
NSString* const WebBaseUrlKey                  = @"WebBaseUrl";
NSString* const WebUsernameKey                 = @"WebUsername";            // Used as keychain 'username'.
NSString* const WebPasswordKey                 = @"WebPassword";            // Used as keychain 'username'.
NSString* const WebServiceKey                  = @"WebAccount";             // Used as keychain service.
NSString* const SipServerKey                   = @"SipServer";
NSString* const SipRealmKey                    = @"SipRealm";               // Used as keychain 'username'.
NSString* const SipUsernameKey                 = @"SipUsername";            // Used as keychain 'username'.
NSString* const SipPasswordKey                 = @"SipPassword";            // Used as keychain 'username'.
NSString* const SipServiveKey                  = @"SipAccount";             // Used as keychain service.
NSString* const AllowCellularDataCallsKey      = @"AllowCellularDataCalls";
NSString* const LouderVolumeKey                = @"LouderVolume";


@implementation Settings

static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;

@synthesize tabBarViewControllerClasses = _tabBarViewControllerClasses;
@synthesize errorDomain                 = _errorDomain;
@synthesize homeCountry                 = _homeCountry;
@synthesize homeCountryFromSim          = _homeCountryFromSim;
@synthesize lastDialedNumber            = _lastDialedNumber;
@synthesize webBaseUrl                  = _webBaseUrl;
@synthesize webUsername                 = _webUsername;
@synthesize webPassword                 = _webPassword;
@synthesize sipServer                   = _sipServer;
@synthesize sipRealm                    = _sipRealm;
@synthesize sipUsername                 = _sipUsername;
@synthesize sipPassword                 = _sipPassword;
@synthesize allowCellularDataCalls      = _allowCellularDataCalls;
@synthesize louderVolume                = _louderVolume;


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
            [KeychainUtility deleteItemForUsername:WebUsernameKey andServiceName:WebServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:WebPasswordKey andServiceName:WebServiceKey error:nil];
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


#pragma mark - Helper Methods

- (void)registerDefaults
{
    NSMutableDictionary*    defaults = [NSMutableDictionary dictionary];

    // Default for tabBarViewControllerClasses is handled in AppDelegate.

    [defaults setObject:@"com.numberbay.app"         forKey:ErrorDomainKey];

    if ([[NetworkStatus sharedStatus].simIsoCountryCode length] > 0)
    {
        [defaults setObject:[NetworkStatus sharedStatus].simIsoCountryCode forKey:HomeCountryKey];
        [defaults setObject:[NSNumber numberWithBool:YES]                  forKey:HomeCountryFromSimKey];
    }
    else
    {
        [defaults setObject:[NSNumber numberWithBool:NO]                   forKey:HomeCountryFromSimKey];
    }

    [defaults setObject:@"http://5.39.84.168:9090/"  forKey:WebBaseUrlKey];
    [defaults setObject:@""                          forKey:LastDialedNumberKey];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:AllowCellularDataCallsKey];
    [defaults setObject:[NSNumber numberWithBool:NO] forKey:LouderVolumeKey];

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
    self.errorDomain                 = [userDefaults objectForKey:ErrorDomainKey];
    self.homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    self.homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
    self.lastDialedNumber            = [userDefaults objectForKey:LastDialedNumberKey];
    self.webBaseUrl                  = [userDefaults objectForKey:WebBaseUrlKey];
    self.webUsername                 = [self getKeychainValueForKey:WebUsernameKey];
    self.webPassword                 = [self getKeychainValueForKey:WebPasswordKey];
    self.sipServer                   = [userDefaults objectForKey:SipServerKey];
    self.sipRealm                    = [self getKeychainValueForKey:SipRealmKey];
    self.sipUsername                 = [self getKeychainValueForKey:SipUsernameKey];
    self.sipPassword                 = [self getKeychainValueForKey:SipPasswordKey];
    self.allowCellularDataCalls      = [userDefaults boolForKey:AllowCellularDataCallsKey];
    self.louderVolume                = [userDefaults boolForKey:LouderVolumeKey];
}


#pragma mark - Setters

- (void)setTabBarViewControllerClasses:(NSArray*)tabBarViewControllerClasses
{
    _tabBarViewControllerClasses = tabBarViewControllerClasses;
    [userDefaults setObject:tabBarViewControllerClasses forKey:TabBarViewControllerClassesKey];
}


- (void)setErrorDomain:(NSString *)errorDomain
{
    _errorDomain = errorDomain;
    [userDefaults setObject:errorDomain forKey:ErrorDomainKey];
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


- (void)setWebBaseUrl:(NSString *)webBaseUrl
{
    _webBaseUrl = webBaseUrl;
    [userDefaults setObject:webBaseUrl forKey:WebBaseUrlKey];
}


- (void)setWebUsername:(NSString*)webUsername
{
    _webUsername = webUsername;
    [self storeKeychainValue:webUsername forKey:WebUsernameKey];
}


- (void)setWebPassword:(NSString*)webPassword
{
    _webPassword = webPassword;
    [self storeKeychainValue:webPassword forKey:WebPasswordKey];
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


- (void)setAllowCellularDataCalls:(BOOL)allowCellularDataCalls
{
    _allowCellularDataCalls = allowCellularDataCalls;
    [userDefaults setBool:allowCellularDataCalls forKey:AllowCellularDataCallsKey];
}


- (void)setLouderVolume:(BOOL)louderVolume
{
    _louderVolume = louderVolume;
    [userDefaults setBool:louderVolume forKey:LouderVolumeKey];
}

@end
