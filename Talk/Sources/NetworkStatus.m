//
//  NetworkStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "NetworkStatus.h"
#import "AFNetworking.h"
#import "Common.h"
#import "Settings.h"

NSString* const NetworkStatusSimChangedNotification             = @"NetworkStatusSimChangedNotification";
NSString* const NetworkStatusMobileCallStateChangedNotification = @"NetworkStatusMobileCallStateChangedNotification";
NSString* const NetworkStatusReachableNotification              = @"NetworkStatusReachableNotification";


@implementation NetworkStatus

static CTTelephonyNetworkInfo*  networkInfo;
static CTCallCenter*            callCenter;
static NSTimer*                 loadUrlTestTimer;


#pragma mark - Singleton Stuff

+ (NetworkStatus*)sharedStatus
{
    static NetworkStatus*   sharedInstance;
    static dispatch_once_t  onceToken;

    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[NetworkStatus alloc] init];

        [sharedInstance setUpReachability];
        [sharedInstance setUpCoreTelephony];
    });

    return sharedInstance;
}


#pragma mark - Helper Methods

- (void)setUpReachability
{
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status)
    {
        NetworkStatusReachable reachable = [self translateAfnReachability:status];
        [[NSNotificationCenter defaultCenter] postNotificationName:NetworkStatusReachableNotification
                                                            object:nil
                                                          userInfo:@{@"status" : @(reachable)}];
    }];
}


- (NetworkStatusReachable)translateAfnReachability:(AFNetworkReachabilityStatus)status
{
    switch (status)
    {
        case AFNetworkReachabilityStatusUnknown:          return NetworkStatusReachableUnknown;
        case AFNetworkReachabilityStatusNotReachable:     return NetworkStatusReachableDisconnected;
        case AFNetworkReachabilityStatusReachableViaWWAN: return NetworkStatusReachableCellular;
        case AFNetworkReachabilityStatusReachableViaWiFi: return NetworkStatusReachableWifi;
    }
}


- (void)setUpCoreTelephony
{
    networkInfo = [[CTTelephonyNetworkInfo alloc] init];

    // The below block is only executed when a different SIM is installed.  Nothing
    // happens when a SIM is removed, or when the same SIM is installed again.
    //
    // To get more triggers observe @"kCTSIMSupportSIMStatusChangeNotification",
    // but this is a private iOS API so may cause trouble with Apple.  And, getting
    // these triggers does not help, because CTTelephonyNetworkInfo is not wiped
    // when a SIM is removed.  Only after restarting the device without SIM:
    // ISOCountryCode is @"", MCC is @"", and MNC is @"00"; HasVoIP remains 1 and
    // even CarrierName remained unchanged (@"Mobistar" e.g.).
    networkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier*carrier)
    {
        NSDictionary*   info;

        if ([self simAvailable])
        {
            info = @{ @"status" : @(NetworkStatusSimAvailable) };
        }
        else
        {
            info = @{ @"status" : @(NetworkStatusSimNotAvailable) };
        }

        [Settings sharedSettings].homeCountry = self.simIsoCountryCode;
        [[NSNotificationCenter defaultCenter] postNotificationName:NetworkStatusSimChangedNotification
                                                            object:nil
                                                          userInfo:info];
    };

    callCenter = [[CTCallCenter alloc] init];
    callCenter.callEventHandler = ^(CTCall* call)
    {
        NBLog(@">>>>>>>>>>>>>>>>>>>>> CallCenter: %lu", (unsigned long)[self convertCallState:call.callState]);

        [[NSNotificationCenter defaultCenter] postNotificationName:NetworkStatusMobileCallStateChangedNotification
                                                            object:nil
                                                          userInfo:@{@"status" : @([self convertCallState:call.callState])}];
    };
}


- (NetworkStatusMobileCall)convertCallState:(NSString* const)callState
{
    NetworkStatusMobileCall status;

    if (callState == CTCallStateDialing)
    {
        status = NetworkStatusMobileCallDialing;
    }
    else if (callState == CTCallStateIncoming)
    {
        status = NetworkStatusMobileCallIncoming;
    }
    else if (callState == CTCallStateConnected)
    {
        status = NetworkStatusMobileCallConnected;
    }
    else if (callState == CTCallStateDisconnected)
    {
        status = NetworkStatusMobileCallDisconnected;
    }
    else
    {
        // We get here when iOS got more/different CTCallState's.
        status = NetworkStatusMobileCallDialing;    //### Clear stack shit - random choice.
    }

    return status;
}


#pragma mark - Public API Methods

- (BOOL)simAvailable
{
    return ([[networkInfo subscriberCellularProvider].isoCountryCode length] == 2 ||
            [[networkInfo subscriberCellularProvider].mobileCountryCode length] == 3);
}


- (BOOL)simAllowsVoIP
{
    return [networkInfo subscriberCellularProvider].allowsVOIP;
}


- (NSString*)simCarrierName
{
    return [networkInfo subscriberCellularProvider].carrierName;    
}


- (NSString*)simIsoCountryCode
{
    if ([[networkInfo subscriberCellularProvider].isoCountryCode length] == 2)
    {
        return [[networkInfo subscriberCellularProvider].isoCountryCode uppercaseString];
    }
    else
    {
        return nil;
    }
}


- (NSString*)simMobileCountryCode
{
    if ([[networkInfo subscriberCellularProvider].mobileCountryCode length] == 3)
    {
        return [networkInfo subscriberCellularProvider].mobileCountryCode;
    }
    else
    {
        return nil;
    }
}


- (NSString*)simMobileNetworkCode
{
    return [networkInfo subscriberCellularProvider].mobileNetworkCode;
}


- (NSArray*)activeMobileCalls
{
    NSMutableArray* calls;

    if (callCenter.currentCalls != nil)
    {
        calls = [NSMutableArray array];
        for (CTCall* call in callCenter.currentCalls)
        {
            [calls addObject:@{ @"id"    : call.callID,
                                @"state" : @([self convertCallState:call.callState]) }];
        }
    }
    else
    {
        calls = nil;
    }

    return calls;
}


- (BOOL)allowsMobileCalls
{
    return [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tel:+11111"]];
}


- (NetworkStatusReachable)reachableStatus
{
    return [self translateAfnReachability:[AFNetworkReachabilityManager sharedManager].networkReachabilityStatus];
}


- (NSString*)internalIPAddress
{
    NSString*       address = @"unknown";
    struct ifaddrs* interfaces = NULL;
    struct ifaddrs* temp_addr = NULL;
    int             success = 0;

    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0)
    {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL)
        {
            if(temp_addr->ifa_addr->sa_family == AF_INET)
            {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"] ||      // Wi-Fi
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"])    // 3G/Edge, ...?
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in*)temp_addr->ifa_addr)->sin_addr)];
                }
            }

            temp_addr = temp_addr->ifa_next;
        }
    }

    // Free memory
    freeifaddrs(interfaces);

    return address;
}


- (NSString*)getSsid
{
    CFArrayRef      interfaces = CNCopySupportedInterfaces();   // "en0"
    CFStringRef     anInterface;
    NSString*       ssid = nil;

    for (int index = 0; index < CFArrayGetCount(interfaces); index++)
    {
        anInterface = CFArrayGetValueAtIndex(interfaces, index);

        CFDictionaryRef   dictionary = CNCopyCurrentNetworkInfo(anInterface);

        if (dictionary != NULL)
        {
            // Connected to Wi-Fi hotspot; but unknown if connected to internet.
            ssid = [NSString stringWithFormat:@"%@", (NSString*)CFDictionaryGetValue(dictionary,
                                                                                     kCNNetworkInfoKeySSID)];
        }

        CFReleaseSafe(dictionary);
    }

    CFReleaseSafe(interfaces);
    
    return ssid;
}

@end
