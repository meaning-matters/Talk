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
#import "Keychain.h"
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
NSString* const SipServerKey                   = @"SipServer";
NSString* const SipRealmKey                    = @"SipRealm";               // Used as keychain 'username'.
NSString* const SipUsernameKey                 = @"SipUsername";            // Used as keychain 'username'.
NSString* const SipPasswordKey                 = @"SipPassword";            // Used as keychain 'username'.
NSString* const AllowCellularDataCallsKey      = @"AllowCellularDataCalls";
NSString* const LouderVolumeKey                = @"LouderVolume";
NSString* const NumberTypeMaskKey              = @"NumberTypeMask";
NSString* const ForwardsingsSelectionKey       = @"ForwardingsSelection";
NSString* const CurrencyCodeKey                = @"CurrencyCode";


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

#warning See if looking "AppleLanguages" item in NSUIserDefaults helps fixing the data loss problem.
        if ((runBefore = [userDefaults boolForKey:RunBeforeKey]) == NO)
        {
            [userDefaults setBool:YES forKey:RunBeforeKey];
            if ([userDefaults synchronize] == NO)
            {
                NSLog(@"//### Failed to synchronize user-defaults!");
            }
/*
            [KeychainUtility deleteItemForUsername:WebUsernameKey andServiceName:WebServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:WebPasswordKey andServiceName:WebServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipRealmKey    andServiceName:SipServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipUsernameKey andServiceName:SipServiceKey error:nil];
            [KeychainUtility deleteItemForUsername:SipPasswordKey andServiceName:SipServiceKey error:nil];
 */
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


- (void)resetAll
{
    [userDefaults removeObjectForKey:RunBeforeKey];
    [userDefaults removeObjectForKey:TabBarViewControllerClassesKey];
    [userDefaults removeObjectForKey:ErrorDomainKey];
    [userDefaults removeObjectForKey:HomeCountryKey];
    [userDefaults removeObjectForKey:HomeCountryFromSimKey];
    [userDefaults removeObjectForKey:LastDialedNumberKey];
    [userDefaults removeObjectForKey:WebBaseUrlKey];
    [Keychain deleteStringForKey:WebUsernameKey];
    [Keychain deleteStringForKey:WebPasswordKey];
    [userDefaults removeObjectForKey:SipServerKey];
    [Keychain deleteStringForKey:SipRealmKey];
    [Keychain deleteStringForKey:SipUsernameKey];
    [Keychain deleteStringForKey:SipPasswordKey];
    [userDefaults removeObjectForKey:AllowCellularDataCallsKey];
    [userDefaults removeObjectForKey:LouderVolumeKey];
    [userDefaults removeObjectForKey:NumberTypeMaskKey];
    [userDefaults removeObjectForKey:ForwardsingsSelectionKey];
    [userDefaults removeObjectForKey:CurrencyCodeKey];

    [userDefaults synchronize];

    [sharedSettings registerDefaults];
    [sharedSettings getInitialValues];
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
    [defaults setObject:[NSNumber numberWithInt:0]                         forKey:ForwardsingsSelectionKey];
    [defaults setObject:@""                                                forKey:CurrencyCodeKey];

    [userDefaults registerDefaults:defaults];
}


- (void)getInitialValues
{
    _tabBarViewControllerClasses = [userDefaults objectForKey:TabBarViewControllerClassesKey];
    _errorDomain                 = [userDefaults objectForKey:ErrorDomainKey];
    _homeCountry                 = [userDefaults objectForKey:HomeCountryKey];
    _homeCountryFromSim          = [userDefaults boolForKey:HomeCountryFromSimKey];
    _lastDialedNumber            = [userDefaults objectForKey:LastDialedNumberKey];
    _webBaseUrl                  = [userDefaults objectForKey:WebBaseUrlKey];
    _webUsername                 = [Keychain getStringForKey:WebUsernameKey];
    _webPassword                 = [Keychain getStringForKey:WebPasswordKey];
    _sipServer                   = [userDefaults objectForKey:SipServerKey];
    _sipRealm                    = [Keychain getStringForKey:SipRealmKey];
    _sipUsername                 = [Keychain getStringForKey:SipUsernameKey];
    _sipPassword                 = [Keychain getStringForKey:SipPasswordKey];
    _allowCellularDataCalls      = [userDefaults boolForKey:AllowCellularDataCallsKey];
    _louderVolume                = [userDefaults boolForKey:LouderVolumeKey];
    _numberTypeMask              = [userDefaults integerForKey:NumberTypeMaskKey];
    _forwardingsSelection        = [userDefaults integerForKey:ForwardsingsSelectionKey];
    _currencyCode                = [userDefaults objectForKey:CurrencyCodeKey];
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


- (void)setErrorDomain:(NSString*)errorDomain
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


- (void)setWebBaseUrl:(NSString*)webBaseUrl
{
    _webBaseUrl = webBaseUrl;
    [userDefaults setObject:webBaseUrl forKey:WebBaseUrlKey];
}


- (void)setWebUsername:(NSString*)webUsername
{
    _webUsername = webUsername;
    [Keychain saveString:webUsername forKey:WebUsernameKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setWebPassword:(NSString*)webPassword
{
    _webPassword = webPassword;
    [Keychain saveString:webPassword forKey:WebPasswordKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipServer:(NSString*)sipServer
{
    _sipServer = sipServer;
    [userDefaults setObject:sipServer forKey:SipServerKey];
}


- (void)setSipRealm:(NSString*)sipRealm
{
    _sipRealm = sipRealm;
    [Keychain saveString:sipRealm forKey:SipRealmKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipUsername:(NSString*)sipUsername
{
    _sipUsername = sipUsername;
    [Keychain saveString:sipUsername forKey:SipUsernameKey];

    [Common postNotificationName:NSUserDefaultsDidChangeNotification userInfo:nil object:self];
}


- (void)setSipPassword:(NSString*)sipPassword
{
    _sipPassword = sipPassword;
    [Keychain saveString:sipPassword forKey:SipPasswordKey];
    
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


- (void)setForwardingsSelection:(NSInteger)forwardingsSelection
{
    _forwardingsSelection = forwardingsSelection;
    [userDefaults setInteger:forwardingsSelection forKey:ForwardsingsSelectionKey];
}


- (void)setCurrencyCode:(NSString*)currencyCode
{
    _currencyCode = currencyCode;
    [userDefaults setObject:currencyCode forKey:CurrencyCodeKey];
}

@end
