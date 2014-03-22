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


NSString* const TabBarClassNamesKey       = @"TabBarClassNames";
NSString* const TabBarSelectedIndexKey    = @"TabBarSelectedIndex";
NSString* const ErrorDomainKey            = @"ErrorDomain";
NSString* const HomeCountryKey            = @"HomeCountry";
NSString* const HomeCountryFromSimKey     = @"HomeCountryFromSim";
NSString* const LastDialedNumberKey       = @"LastDialedNumber";
NSString* const WarnedAboutDefaultCliKey  = @"WarnedAboutDefaultCli";
NSString* const WebBaseUrlKey             = @"WebBaseUrl";
NSString* const WebUsernameKey            = @"WebUsername";            // Used as keychain 'username'.
NSString* const WebPasswordKey            = @"WebPassword";            // Used as keychain 'username'.
NSString* const SipServerKey              = @"SipServer";              // Used as keychain 'username'.
NSString* const SipRealmKey               = @"SipRealm";               // Used as keychain 'username'.
NSString* const SipUsernameKey            = @"SipUsername";            // Used as keychain 'username'.
NSString* const SipPasswordKey            = @"SipPassword";            // Used as keychain 'username'.
NSString* const AllowCellularDataCallsKey = @"AllowCellularDataCalls";
NSString* const ShowCallerIdKey           = @"ShowCallerId";
NSString* const CallbackModeKey           = @"CallbackMode";
NSString* const CallerIdE164Key           = @"CallerIdE164";
NSString* const CallbackE164Key           = @"CallbackE164";
NSString* const NumberTypeMaskKey         = @"NumberTypeMask";
NSString* const NumbersSortSegmentKey     = @"NumbersSortSegment";
NSString* const ForwardingsSelectionKey   = @"ForwardingsSelection";
NSString* const CurrencyCodeKey           = @"CurrencyCode";
NSString* const CreditKey                 = @"Credit";
NSString* const PendingNumberBuyKey       = @"PendingNumberBuy";
NSString* const NeedsServerSyncKey        = @"NeedsServerSync";


@implementation Settings

static NSUserDefaults* userDefaults;


#pragma mark - Singleton Stuff

+ (Settings*)sharedSettings
{
    static Settings*       sharedInstance;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[Settings alloc] init];

        userDefaults = [NSUserDefaults standardUserDefaults];

        [userDefaults registerDefaults:[sharedInstance defaults]];
    });

    return sharedInstance;
}


- (void)synchronize
{
    [userDefaults synchronize];
}


- (void)resetAll
{
    [Keychain deleteStringForKey:WebUsernameKey];
    [Keychain deleteStringForKey:WebPasswordKey];
    [Keychain deleteStringForKey:SipServerKey];
    [Keychain deleteStringForKey:SipRealmKey];
    [Keychain deleteStringForKey:SipUsernameKey];
    [Keychain deleteStringForKey:SipPasswordKey];

    for (NSString* key in [self defaults])
    {
        [userDefaults setObject:[[self defaults] objectForKey:key] forKey:key];
    }

    [userDefaults synchronize];
}


- (BOOL)haveAccount
{
#if HAS_VOIP
    return (self.webUsername.length > 0 && self.webPassword.length > 0 &&
            self.sipUsername.length > 0 && self.sipPassword.length > 0);
#else
    return (self.webUsername.length > 0 && self.webPassword.length > 0);
#endif
}


#pragma mark - Helper Methods

- (NSDictionary*)defaults
{
    static NSMutableDictionary* dictionary;
    static dispatch_once_t      onceToken;

    dispatch_once(&onceToken, ^
    {
        dictionary = [NSMutableDictionary dictionary];

        // Default for tabBarClassNames is handled in AppDelegate.
        [dictionary setObject:@(2)                                               forKey:TabBarSelectedIndexKey]; // Contacts.

        [dictionary setObject:@"com.numberbay.app"                               forKey:ErrorDomainKey];

        if ([[NetworkStatus sharedStatus].simIsoCountryCode length] > 0)
        {
            [dictionary setObject:[NetworkStatus sharedStatus].simIsoCountryCode forKey:HomeCountryKey];
            [dictionary setObject:@(YES)                                         forKey:HomeCountryFromSimKey];
        }
        else
        {
            [dictionary setObject:@""                                            forKey:HomeCountryKey];
            [dictionary setObject:@(NO)                                          forKey:HomeCountryFromSimKey];
        }

        [dictionary setObject:@""                                                forKey:LastDialedNumberKey];
        [dictionary setObject:@(NO)                                              forKey:WarnedAboutDefaultCliKey];
        [dictionary setObject:@"https://api.numberbay.com/"                      forKey:WebBaseUrlKey];
        [dictionary setObject:@(NO)                                              forKey:AllowCellularDataCallsKey];
        [dictionary setObject:@(YES)                                             forKey:ShowCallerIdKey];
        [dictionary setObject:@(NO)                                              forKey:CallbackModeKey];
        [dictionary setObject:@""                                                forKey:CallerIdE164Key];
        [dictionary setObject:@(NumberTypeGeographicMask)                        forKey:NumberTypeMaskKey];
        [dictionary setObject:@(0)                                               forKey:NumbersSortSegmentKey];
        [dictionary setObject:@(0)                                               forKey:ForwardingsSelectionKey];
        [dictionary setObject:@""                                                forKey:CurrencyCodeKey];
        [dictionary setObject:@(0.0f)                                            forKey:CreditKey];
        [dictionary setObject:@(NO)                                              forKey:NeedsServerSyncKey];
    });

    return dictionary;
}


#pragma mark - Setters

- (NSArray*)tabBarClassNames
{
    return [userDefaults objectForKey:TabBarClassNamesKey];
}


- (void)setTabBarClassNames:(NSArray*)tabBarClassNames
{
    [userDefaults setObject:tabBarClassNames forKey:TabBarClassNamesKey];
}


- (NSUInteger)tabBarSelectedIndex
{
    return [userDefaults integerForKey:TabBarSelectedIndexKey];
}


- (void)setTabBarSelectedIndex:(NSUInteger)tabBarSelectedIndex
{
    [userDefaults setInteger:tabBarSelectedIndex forKey:TabBarSelectedIndexKey];
}


- (NSString*)errorDomain
{
    return [userDefaults objectForKey:ErrorDomainKey];
}


- (void)setErrorDomain:(NSString*)errorDomain
{
    [userDefaults setObject:errorDomain forKey:ErrorDomainKey];
}


- (NSString*)homeCountry
{
    return [userDefaults objectForKey:HomeCountryKey];
}


- (void)setHomeCountry:(NSString*)homeCountry
{
    [userDefaults setObject:homeCountry forKey:HomeCountryKey];
}


- (BOOL)homeCountryFromSim
{
    return [userDefaults boolForKey:HomeCountryFromSimKey];
}


- (void)setHomeCountryFromSim:(BOOL)homeCountryFromSim
{
    [userDefaults setBool:homeCountryFromSim forKey:HomeCountryFromSimKey];
}


- (NSString*)lastDialedNumber
{
    return [userDefaults objectForKey:LastDialedNumberKey];
}


- (void)setLastDialedNumber:(NSString*)lastDialedNumber
{
    [userDefaults setObject:lastDialedNumber forKey:LastDialedNumberKey];
}


- (BOOL)warnedAboutDefaultCli
{
    return [userDefaults boolForKey:WarnedAboutDefaultCliKey];
}


- (void)setWarnedAboutDefaultCli:(BOOL)warnedAboutDefaultCli
{
    [userDefaults setBool:warnedAboutDefaultCli forKey:WarnedAboutDefaultCliKey];
}


- (NSString*)webBaseUrl
{
    return [userDefaults objectForKey:WebBaseUrlKey];
}


- (void)setWebBaseUrl:(NSString*)webBaseUrl
{
    [userDefaults setObject:webBaseUrl forKey:WebBaseUrlKey];
}


- (NSString*)webUsername
{
    return [Keychain getStringForKey:WebUsernameKey];
}


- (void)setWebUsername:(NSString*)webUsername
{
    [Keychain saveString:webUsername forKey:WebUsernameKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (NSString*)webPassword
{
    return [Keychain getStringForKey:WebPasswordKey];
}


- (void)setWebPassword:(NSString*)webPassword
{
    [Keychain saveString:webPassword forKey:WebPasswordKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (NSString*)sipServer
{
    return [Keychain getStringForKey:SipServerKey];
}


- (void)setSipServer:(NSString*)sipServer
{
    [Keychain saveString:sipServer forKey:SipServerKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (NSString*)sipRealm
{
    return [Keychain getStringForKey:SipRealmKey];
}


- (void)setSipRealm:(NSString*)sipRealm
{
    [Keychain saveString:sipRealm forKey:SipRealmKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (NSString*)sipUsername
{
    return [Keychain getStringForKey:SipUsernameKey];
}


- (void)setSipUsername:(NSString*)sipUsername
{
    [Keychain saveString:sipUsername forKey:SipUsernameKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (NSString*)sipPassword
{
    return [Keychain getStringForKey:SipPasswordKey];
}


- (void)setSipPassword:(NSString*)sipPassword
{
    [Keychain saveString:sipPassword forKey:SipPasswordKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NSUserDefaultsDidChangeNotification object:nil];
}


- (BOOL)allowCellularDataCalls
{
    return [userDefaults boolForKey:AllowCellularDataCallsKey];
}


- (void)setAllowCellularDataCalls:(BOOL)allowCellularDataCalls
{
    [userDefaults setBool:allowCellularDataCalls forKey:AllowCellularDataCallsKey];
}


- (BOOL)showCallerId
{
    return [userDefaults boolForKey:ShowCallerIdKey];
}


- (void)setShowCallerId:(BOOL)showCallerId
{
    [userDefaults setBool:showCallerId forKey:ShowCallerIdKey];
}


- (BOOL)callbackMode
{
    return [userDefaults boolForKey:CallbackModeKey];
}


- (void)setCallbackMode:(BOOL)callbackMode
{
    [userDefaults setBool:callbackMode forKey:CallbackModeKey];
}


- (NSString*)callerIdE164
{
    return [userDefaults objectForKey:CallerIdE164Key];
}


- (void)setCallerIdE164:(NSString*)callerIdE164
{
    [userDefaults setObject:callerIdE164 forKey:CallerIdE164Key];
}


- (NSString*)callbackE164
{
    return [userDefaults objectForKey:CallbackE164Key];
}


- (void)setCallbackE164:(NSString*)callbackE164
{
    [userDefaults setObject:callbackE164 forKey:CallbackE164Key];
}


- (NumberTypeMask)numberTypeMask
{
    return [userDefaults integerForKey:NumberTypeMaskKey];
}


- (void)setNumberTypeMask:(NumberTypeMask)numberTypeMask
{
    [userDefaults setInteger:numberTypeMask forKey:NumberTypeMaskKey];
}


- (NSInteger)numbersSortSegment
{
    return [userDefaults integerForKey:NumbersSortSegmentKey];
}


- (void)setNumbersSortSegment:(NSInteger)numbersSortSegment
{
    [userDefaults setInteger:numbersSortSegment forKey:NumbersSortSegmentKey];
}


- (NSInteger)forwardingsSelection
{
    return [userDefaults integerForKey:ForwardingsSelectionKey];
}


- (void)setForwardingsSelection:(NSInteger)forwardingsSelection
{
    [userDefaults setInteger:forwardingsSelection forKey:ForwardingsSelectionKey];
}


- (NSString*)currencyCode
{
    return [userDefaults objectForKey:CurrencyCodeKey];
}


- (void)setCurrencyCode:(NSString*)currencyCode
{
    [userDefaults setObject:currencyCode forKey:CurrencyCodeKey];
}


- (float)credit
{
    return [userDefaults floatForKey:CreditKey];
}


- (void)setCredit:(float)credit
{
    [userDefaults setFloat:credit forKey:CreditKey];
}


- (NSDictionary*)pendingNumberBuy
{
    return [userDefaults objectForKey:PendingNumberBuyKey];
}


- (void)setPendingNumberBuy:(NSDictionary*)pendingNumberBuy
{
    [userDefaults setObject:pendingNumberBuy forKey:PendingNumberBuyKey];
    [userDefaults synchronize]; // We want this extra security, because this data can not be restored!
}


- (BOOL)needsServerSync
{
    return [userDefaults boolForKey:NeedsServerSyncKey];
}


- (void)setNeedsServerSync:(BOOL)needsServerSync
{
    [userDefaults setBool:needsServerSync forKey:NeedsServerSyncKey];
    [userDefaults synchronize];
}


- (NSString*)appId
{
    return @"642013221";
}


- (NSString*)appVersion
{
    NSDictionary*   infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    return [infoDictionary objectForKey:@"CFBundleVersion"];
}


- (NSString*)appDisplayName
{
    NSDictionary*   infoDictionary = [[NSBundle mainBundle] infoDictionary];

    return [infoDictionary objectForKey:@"CFBundleDisplayName"];
}


- (NSString*)companyNameAddress
{
    return @"NumberBay Ltd.\n100 Barbirolli Square\nManchester M2 3AB\nUnited Kingdom";
}


- (NSString*)testNumber
{
    return @"200";
}


- (NSString*)supportNumber
{
    return @"+441617680224";
}


- (NSString*)supportEmail
{
    return @"info@numberbay.com";
}

@end
