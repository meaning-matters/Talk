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
NSString* const HomeIsoCountryCodeKey     = @"HomeIsoCountryCode";
NSString* const UseSimIsoCountryCodeKey   = @"UseSimIsoCountryCode";
NSString* const LastDialedNumberKey       = @"LastDialedNumber";
NSString* const RecentsCheckDateKey       = @"RecentsCheckDate";
NSString* const SynchronizeDateKey        = @"SynchronizeDate";
NSString* const UpdateAppDateKey          = @"UpdateAppDate";
NSString* const WebUsernameKey            = @"WebUsername";            // Used as keychain 'username'.
NSString* const WebPasswordKey            = @"WebPassword";            // Used as keychain 'username'.
NSString* const DeviceTokenReplacementKey = @"DeviceTokenReplacement";
NSString* const ShowCallerIdKey           = @"ShowCallerId";
NSString* const CallerIdE164Key           = @"CallerIdE164";
NSString* const CallbackE164Key           = @"CallbackE164";
NSString* const NumberTypeMaskKey         = @"NumberTypeMask";
NSString* const CountryRegionKey          = @"CountryRegion";
NSString* const SortSegmentKey            = @"SortSegment";
NSString* const ShowFootnotesKey          = @"ShowFootnotes";
NSString* const DestinationsSelectionKey  = @"DestinationsSelection";
NSString* const StoreCurrencyCodeKey      = @"StoreCurrencyCode";
NSString* const StoreCountryCodeKey       = @"StoreCountryCode";
NSString* const CreditKey                 = @"Credit";
NSString* const NeedsServerSyncKey        = @"NeedsServerSync";
NSString* const NumberFilterKey           = @"NumberFilter";

NSString* const AddressUpdatesKey         = @"AddressUpdates";
NSString* const DnsSrvPrefixKey           = @"DnsSrvPrefix";


@interface Settings ()

@property (nonatomic, strong) NSString* deviceTokenReplacement;

@end


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
        
        if (sharedInstance.deviceTokenReplacement == nil)
        {
            sharedInstance.deviceTokenReplacement = [[NSUUID UUID] UUIDString];
        }
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
        NSLocale* locale = [NSLocale currentLocale];

        dictionary = [NSMutableDictionary dictionary];

        // Default for tabBarClassNames is handled in AppDelegate.
        [dictionary setObject:@(2)                                               forKey:TabBarSelectedIndexKey]; // Contacts.

        [dictionary setObject:@"com.numberbay.app"                               forKey:ErrorDomainKey];

        if ([[NetworkStatus sharedStatus].simIsoCountryCode length] > 0)
        {
            [dictionary setObject:[NetworkStatus sharedStatus].simIsoCountryCode forKey:HomeIsoCountryCodeKey];
            [dictionary setObject:@(YES)                                         forKey:UseSimIsoCountryCodeKey];
        }
        else
        {
            NSLocale* locale = [NSLocale currentLocale];
            [dictionary setObject:[locale objectForKey:NSLocaleCountryCode]      forKey:HomeIsoCountryCodeKey];
            [dictionary setObject:@(NO)                                          forKey:UseSimIsoCountryCodeKey];
        }

        [dictionary setObject:@""                                                forKey:LastDialedNumberKey];
        [dictionary setObject:[NSDate date]                                      forKey:RecentsCheckDateKey];
        [dictionary setObject:@(YES)                                             forKey:ShowCallerIdKey];
        [dictionary setObject:@""                                                forKey:CallerIdE164Key];
        [dictionary setObject:@""                                                forKey:CallbackE164Key];
        [dictionary setObject:@(NumberTypeGeographicMask)                        forKey:NumberTypeMaskKey];
        [dictionary setObject:@(CountryRegionEurope)                             forKey:CountryRegionKey];
        [dictionary setObject:@(0)                                               forKey:SortSegmentKey];
        [dictionary setObject:@(YES)                                             forKey:ShowFootnotesKey];
        [dictionary setObject:@(0)                                               forKey:DestinationsSelectionKey];
        [dictionary setObject:[locale objectForKey:NSLocaleCurrencyCode]         forKey:StoreCurrencyCodeKey];
        [dictionary setObject:[locale objectForKey:NSLocaleCountryCode]          forKey:StoreCountryCodeKey];
        [dictionary setObject:@(0.0f)                                            forKey:CreditKey];
        [dictionary setObject:@(NO)                                              forKey:NeedsServerSyncKey];
        [dictionary setObject:@"_api"                                            forKey:DnsSrvPrefixKey];
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


- (NSString*)homeIsoCountryCode
{
    return [userDefaults objectForKey:HomeIsoCountryCodeKey];
}


- (void)setHomeIsoCountryCode:(NSString*)homeIsoCountryCode
{
    [userDefaults setObject:homeIsoCountryCode forKey:HomeIsoCountryCodeKey];
}


- (BOOL)useSimIsoCountryCode
{
    return [userDefaults boolForKey:UseSimIsoCountryCodeKey];
}


- (void)setUseSimIsoCountryCode:(BOOL)useSimIsoCountryCode
{
    [userDefaults setBool:useSimIsoCountryCode forKey:UseSimIsoCountryCodeKey];
}


- (NSString*)lastDialedNumber
{
    return [userDefaults objectForKey:LastDialedNumberKey];
}


- (void)setLastDialedNumber:(NSString*)lastDialedNumber
{
    [userDefaults setObject:lastDialedNumber forKey:LastDialedNumberKey];
}


- (NSDate*)recentsCheckDate
{
    return [userDefaults objectForKey:RecentsCheckDateKey];
}


- (void)setRecentsCheckDate:(NSDate*)recentsCheckDate
{
    [userDefaults setObject:recentsCheckDate forKey:RecentsCheckDateKey];
}


- (NSDate*)synchronizeDate
{
    return [userDefaults objectForKey:SynchronizeDateKey];
}


- (void)setSynchronizeDate:(NSDate*)synchronizeDate
{
    [userDefaults setObject:synchronizeDate forKey:SynchronizeDateKey];
}


- (NSDate*)updateAppDate
{
    return [userDefaults objectForKey:UpdateAppDateKey];
}


- (void)setUpdateAppDate:(NSDate*)updateAppDate
{
    [userDefaults setObject:updateAppDate forKey:UpdateAppDateKey];
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


- (NSString*)deviceTokenReplacement
{
    return [userDefaults objectForKey:DeviceTokenReplacementKey];
}


- (void)setDeviceTokenReplacement:(NSString*)deviceTokenReplacement
{
    [userDefaults setObject:deviceTokenReplacement forKey:DeviceTokenReplacementKey];
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


- (CountryRegion)countryRegion
{
    return (CountryRegion)[userDefaults integerForKey:CountryRegionKey];
}


- (void)setCountryRegion:(CountryRegion)countryRegion
{
    [userDefaults setInteger:countryRegion forKey:CountryRegionKey];
}


- (NSInteger)sortSegment
{
    return [userDefaults integerForKey:SortSegmentKey];
}


- (void)setSortSegment:(NSInteger)sortSegment
{
    [userDefaults setInteger:sortSegment forKey:SortSegmentKey];
}


- (BOOL)showFootnotes
{
    return [userDefaults boolForKey:ShowFootnotesKey];
}


- (void)setShowFootnotes:(BOOL)showFootnotes
{
    [userDefaults setBool:showFootnotes forKey:ShowFootnotesKey];
}


- (NSInteger)destinationsSelection
{
    return [userDefaults integerForKey:DestinationsSelectionKey];
}


- (void)setDestinationsSelection:(NSInteger)destinationsSelection
{
    [userDefaults setInteger:destinationsSelection forKey:DestinationsSelectionKey];
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


- (NSDictionary*)numberFilter
{
    return [userDefaults objectForKey:NumberFilterKey];
}


- (void)setNumberFilter:(NSDictionary*)numberFilter
{
    [userDefaults setObject:numberFilter forKey:NumberFilterKey];
}


- (NSDictionary*)addressUpdates
{
    if ([userDefaults objectForKey:AddressUpdatesKey] == nil)
    {
        [self setAddressUpdates:@{}];
    }

    return [userDefaults objectForKey:AddressUpdatesKey];
}


- (void)setAddressUpdates:(NSDictionary*)addressUpdates
{
    [userDefaults setObject:addressUpdates forKey:AddressUpdatesKey];
}


- (NSString*)appId
{
    return @"642013221";
}


- (NSString*)appVersion
{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];
    
    return [infoDictionary objectForKey:@"CFBundleVersion"];
}


- (NSString*)appDisplayName
{
    NSDictionary* infoDictionary = [[NSBundle mainBundle] infoDictionary];

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


#pragma mark - Server URL

- (NSString*)dnsSrvPrefix
{
    return [userDefaults objectForKey:DnsSrvPrefixKey];
}


- (void)setDnsSrvPrefix:(NSString*)dnsSrvPrefix
{
    if (dnsSrvPrefix.length == 0)
    {
        [userDefaults setObject:@"_api" forKey:DnsSrvPrefixKey];
    }
    else
    {
        [userDefaults setObject:dnsSrvPrefix forKey:DnsSrvPrefixKey];
    }
}


- (NSString*)dnsSrvName
{
    return [NSString stringWithFormat:@"%@._tcp.numberbay.com", self.dnsSrvPrefix];
}


- (NSString*)fallbackServer
{
    return @"api.numberbay.com";
}


- (NSString*)serverTestUrlPath
{
    return @"/test/system";
}

@end
