//
//  Settings.m
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//
//  In Talk we want to save both the API username and API password in keychain.
//  So we store both these strings as 'password' under names/keys "WebUsername"
//  and "WebPassword" respectively.  So these two are not saved in UserDefaults.
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
NSString* const WebUsernameKey            = @"WebUsername";            // Used as keychain 'username'.
NSString* const WebPasswordKey            = @"WebPassword";            // Used as keychain 'username'.
NSString* const ShowCallerIdKey           = @"ShowCallerId";
NSString* const CallerIdE164Key           = @"CallerIdE164";
NSString* const CallbackE164Key           = @"CallbackE164";
NSString* const NumberTypeMaskKey         = @"NumberTypeMask";
NSString* const NumbersSortSegmentKey     = @"NumbersSortSegment";
NSString* const ForwardingsSelectionKey   = @"ForwardingsSelection";
NSString* const StoreCurrencyCodeKey      = @"StoreCurrencyCode";
NSString* const StoreCountryCodeKey       = @"StoreCountryCode";
NSString* const CreditKey                 = @"Credit";
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
        sharedInstance.dnsSrvName = nil;  // Select hard-coded default.
        
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

    for (NSString* key in [self defaults])
    {
        [userDefaults setObject:[[self defaults] objectForKey:key] forKey:key];
    }
    
    self.dnsSrvName = nil;  // Select hard-coded default.

    [userDefaults synchronize];
}


- (BOOL)haveAccount
{
    return (self.webUsername.length > 0 && self.webPassword.length > 0);
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
        [dictionary setObject:@(YES)                                             forKey:ShowCallerIdKey];
        [dictionary setObject:@""                                                forKey:CallerIdE164Key];
        [dictionary setObject:@""                                                forKey:CallbackE164Key];
        [dictionary setObject:@(NumberTypeGeographicMask)                        forKey:NumberTypeMaskKey];
        [dictionary setObject:@(0)                                               forKey:NumbersSortSegmentKey];
        [dictionary setObject:@(0)                                               forKey:ForwardingsSelectionKey];
        [dictionary setObject:@""                                                forKey:StoreCurrencyCodeKey];
        [dictionary setObject:@""                                                forKey:StoreCountryCodeKey];
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


- (BOOL)showCallerId
{
    return [userDefaults boolForKey:ShowCallerIdKey];
}


- (void)setShowCallerId:(BOOL)showCallerId
{
    [userDefaults setBool:showCallerId forKey:ShowCallerIdKey];
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
    return (NumberTypeMask)[userDefaults integerForKey:NumberTypeMaskKey];
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


- (NSString*)storeCurrencyCode
{
    return [userDefaults objectForKey:StoreCurrencyCodeKey];
}


- (void)setStoreCurrencyCode:(NSString*)storeCurrencyCode
{
    [userDefaults setObject:storeCurrencyCode forKey:StoreCurrencyCodeKey];
}


- (NSString*)storeCountryCode
{
    return [userDefaults objectForKey:StoreCountryCodeKey];
}


- (void)setStoreCountryCode:(NSString*)storeCountryCode
{
    [userDefaults setObject:storeCountryCode forKey:StoreCountryCodeKey];
}


- (float)credit
{
    return [userDefaults floatForKey:CreditKey];
}


- (void)setCredit:(float)credit
{
    [userDefaults setFloat:credit forKey:CreditKey];
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


#pragma mark - Company Details

- (NSString*)companyName
{
    return @"NumberBay Ltd.";
}


- (NSString*)companyAddress1
{
    return @"Suite 101";
}


- (NSString*)companyAddress2
{
    return @"128 Aldersgate Street";
}


- (NSString*)companyCity
{
    return @"London";
}


- (NSString*)companyPostcode
{
    return @"EC1A 4AE";
}


- (NSString*)companyCountry
{
    return @"United Kingdom";
}


- (NSString*)companyPhone
{
    return @"+442038083855";
}


- (NSString*)companyEmail
{
    return @"info@numberbay.com";
}


- (NSString*)companyWebsite
{
    return @"http://www.numberbay.com";
}


#pragma mark - Hard-Coded URLs

- (void)setDnsSrvName:(NSString*)dnsSrvName
{
    if (dnsSrvName.length == 0)
    {
        _dnsSrvName = @"_api._tcp.numberbay.com";
    }
    else
    {
        _dnsSrvName = dnsSrvName;
    }
}


- (NSString*)serverTestUrlPath
{
    return @"/test/system";
}

@end
