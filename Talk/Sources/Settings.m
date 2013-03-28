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
#import "NumberType.h"
#import "Common.h"


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
NSString* const SipServiceKey                  = @"SipAccount";             // Used as keychain service.
NSString* const AllowCellularDataCallsKey      = @"AllowCellularDataCalls";
NSString* const LouderVolumeKey                = @"LouderVolume";
NSString* const NumberTypeMaskKey              = @"NumberTypeMask";


@implementation Settings

static BOOL             runBefore;
static Settings*        sharedSettings;
static NSUserDefaults*  userDefaults;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([Settings class] == self)
    {
        sharedSettings = [self new];
        userDefaults = [NSUserDefaults standardUserDefaults];

        if ((runBefore = [userDefaults boolForKey:RunBeforeKey]) == NO)
        {
            [userDefaults setBool:YES forKey:RunBeforeKey];
            if ([userDefaults synchronize] == NO)
            {
                NSLog(@"//### Failed to synchronize user-defaults!");
            }

            [KeychainUtility deleteItemForUsername:WebUsernameKey andServiceName:WebServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:WebPasswordKey andServiceName:WebServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipRealmKey    andServiceName:SipServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipUsernameKey andServiceName:SipServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipPasswordKey andServiceName:SipServiceKey error:nil];
        }

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


#pragma mark - Helper Methods

- (void)registerDefaults
{
    NSMutableDictionary*    defaults = [NSMutableDictionary dictionary];

    // Default for tabBarViewControllerClasses is handled in AppDelegate.

    [defaults setObject:@"com.numberbay.app"                               forKey:ErrorDomainKey];

    if ([[NetworkStatus sharedStatus].simIsoCountryCode length] > 0)
    {
        [defaults setObject:[NetworkStatus sharedStatus].simIsoCountryCode forKey:HomeCountryKey];
        [defaults setObject:[NSNumber numberWithBool:YES]                  forKey:HomeCountryFromSimKey];
    }
    else
    {
        [defaults setObject:[NSNumber numberWithBool:NO]                   forKey:HomeCountryFromSimKey];
    }

    [defaults setObject:@"http://5.39.84.168:9090/"                        forKey:WebBaseUrlKey];
    [defaults setObject:@""                                                forKey:LastDialedNumberKey];
    [defaults setObject:[NSNumber numberWithBool:NO]                       forKey:AllowCellularDataCallsKey];
    [defaults setObject:[NSNumber numberWithBool:NO]                       forKey:LouderVolumeKey];
    [defaults setObject:[NSNumber numberWithInt:NumberTypeGeographicMask]  forKey:NumberTypeMaskKey];

    [userDefaults registerDefaults:defaults];
}


- (NSString*)getKeychainValueForKey:(NSString*)key service:(NSString*)service
{
    NSError*    error = nil;
    NSString*   value;

    value = [KeychainUtility getPasswordForUsername:key andServiceName:service error:&error];
    if (value == nil && error != nil)
    {
        NSLog(@"//### Error getting value from keychain: %@", [error localizedDescription]);
    }

    return value ? value : @"";
}


- (void)storeKeychainValue:(NSString*)value forKey:(NSString*)key service:(NSString*)service
{
    NSError*    error = nil;

    if ([KeychainUtility storeUsername:key andPassword:value forServiceName:service updateExisting:YES error:&error] == NO)
    {
        NSLog(@"//### Error storing value in keychain: %@", [error localizedDescription]);
    }
}


- (void)getInitialValues
{
    // We assign to property (with self.xyz, instread of to _xyz) so that a value that
    // was added as default (in registerDefaults) is saved as normal setting.
    //
    // This does not apply for the keychain items, which have no default value.  But,
    // more importantly self.xyz for keychain values stores that value in the keychain
    // immediately again, and this caused them to be wiped.
    
    self.tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
    self.errorDomain                 = [userDefaults objectForKey:ErrorDomainKey];
    self.homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    self.homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
    self.lastDialedNumber            = [userDefaults objectForKey:LastDialedNumberKey];
    self.webBaseUrl                  = [userDefaults objectForKey:WebBaseUrlKey];
    _webUsername                     = [self getKeychainValueForKey:WebUsernameKey service:WebServiceKey];
    _webPassword                     = [self getKeychainValueForKey:WebPasswordKey service:WebServiceKey];
    self.sipServer                   = [userDefaults objectForKey:SipServerKey];
    _sipRealm                        = [self getKeychainValueForKey:SipRealmKey    service:SipServiceKey];
    _sipUsername                     = [self getKeychainValueForKey:SipUsernameKey service:SipServiceKey];
    _sipPassword                     = [self getKeychainValueForKey:SipPasswordKey service:SipServiceKey];
    self.allowCellularDataCalls      = [userDefaults boolForKey:AllowCellularDataCallsKey];
    self.louderVolume                = [userDefaults boolForKey:LouderVolumeKey];
    self.numberTypeMask              = [userDefaults integerForKey:NumberTypeMaskKey];
}


#pragma mark - Getter

- (BOOL)runBefore
{
    return runBefore;
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
    [self storeKeychainValue:webUsername forKey:WebUsernameKey service:WebServiceKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setWebPassword:(NSString*)webPassword
{
    _webPassword = webPassword;
    [self storeKeychainValue:webPassword forKey:WebPasswordKey service:WebServiceKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipServer:(NSString *)sipServer
{
    _sipServer = sipServer;
    [userDefaults setObject:sipServer forKey:SipServerKey];
}


- (void)setSipRealm:(NSString*)sipRealm
{
    _sipRealm = sipRealm;
    [self storeKeychainValue:sipRealm forKey:SipRealmKey service:SipServiceKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipUsername:(NSString*)sipUsername
{
    _sipUsername = sipUsername;
    [self storeKeychainValue:sipUsername forKey:SipUsernameKey service:SipServiceKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipPassword:(NSString*)sipPassword
{
    _sipPassword = sipPassword;
    [self storeKeychainValue:sipPassword forKey:SipPasswordKey service:SipServiceKey];
    
    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
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


- (void)setNumberTypeMask:(NumberTypeMask)numberTypeMask
{
    _numberTypeMask = numberTypeMask;
    [userDefaults setInteger:numberTypeMask forKey:NumberTypeMaskKey];
}

@end
