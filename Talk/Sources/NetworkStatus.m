//
//  NetworkStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <SystemConfiguration/CaptiveNetwork.h>
#import <ifaddrs.h>
#import <arpa/inet.h>
#import "NetworkStatus.h"
#import "Common.h"
#import "Reachability.h"


NSString* const kNetworkStatusSimCardChangedNotification         = @"kNetworkStatusSimCardChangedNotification";
NSString* const kNetworkStatusMobileCallStateChangedNotification = @"kNetworkStatusMobileCallStateChangedNotification";
NSString* const kNetworkStatusInternetConnectionNotification     = @"kNetworkStatusInternetConnectionNotification";


@implementation NetworkStatus

static NetworkStatus*           sharedStatus;
static Reachability*            hostReach;
static Reachability*            internetReach;
static Reachability*            wifiReach;
static CTTelephonyNetworkInfo*  networkInfo;
static CTCallCenter*            callCenter;

@synthesize carrierAllowsVoIP;
@synthesize carrierName;
@synthesize isoCountryCode;
@synthesize mobileCountryCode;
@synthesize mobileNetworkCode;
@synthesize mobileCallActive;
@synthesize wifiReachable;
@synthesize wifiAccessNeedsConnection;
@synthesize internetReachable;
@synthesize hostReachable;
@synthesize hostAccessNeedsConnection;


#pragma mark - Singleton Stuff

+ (void)initialize
{
    if ([NetworkStatus class] == self)
    {
        sharedStatus = [self new];
        [NetworkStatus setUp];
    }
}


+ (id)allocWithZone:(NSZone*)zone
{
    if (sharedStatus && [NetworkStatus class] == self)
    {
        [NSException raise:NSGenericException format:@"Duplicate NetworkStatus singleton creation"];
    }

    return [super allocWithZone:zone];
}


+ (NetworkStatus*)sharedStatus
{
    return sharedStatus;
}


+ (void)setUp
{
    hostReach = [Reachability reachabilityWithHostname:@"www.google.com"];
    [hostReach startNotifier];

    internetReach = [Reachability reachabilityForInternetConnection];
    [internetReach startNotifier];

    wifiReach = [Reachability reachabilityForLocalWiFi];
    [wifiReach startNotifier];

    networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    networkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier* carrier)
    {
        [Common postNotificationName:kNetworkStatusSimCardChangedNotification object:self];
    };

    callCenter  = [[CTCallCenter alloc] init];
    callCenter.callEventHandler=^(CTCall* call)
    {
        if (call.callState == CTCallStateDialing)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"state" : CTCallStateDialing }
                                  object:self];
        }
        else if (call.callState == CTCallStateIncoming)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"state" : CTCallStateIncoming }
                                  object:self];
        }
        else if (call.callState == CTCallStateConnected)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"state" : CTCallStateConnected }
                                  object:self];
        }
        else if (call.callState == CTCallStateDisconnected)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"state" : CTCallStateDisconnected }
                                  object:self];
        }
    };

    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
    {
        if (note.object == hostReach)
        {
            //[Common postNotificationName:<#(NSString *)#> object:<#(id)#>]
        }

        if (note.object == internetReach)
        {
        }

        if (note.object == wifiReach)
        {
        }



        NSLog(@"    HOST: %@", [hostReach currentReachabilityFlags]);
        NSLog(@"INTERNET: %@", [internetReach currentReachabilityFlags]);
        NSLog(@"    WIFI: %@", [wifiReach currentReachabilityFlags]);

        
    }];
}


- (void)loadUrlTest
{
    NSURL*          url = [NSURL URLWithString: @"www.google.com"];
    NSURLRequest*   request = [NSURLRequest requestWithURL:url
                                               cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                           timeoutInterval:20.0];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[[NSOperationQueue alloc] init]
                           completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
    {
        if ([data length] > 0 && error == nil)
        {
            // Connected
        }
        else if ([data length] == 0 && error == nil)
        {
            // Empty reply
        }
        else if (error != nil)
        {
            // Error
        }
    }];
}


- (BOOL)carrierAllowsVoIP
{
    return [networkInfo subscriberCellularProvider].allowsVOIP;
}


- (NSString*)carrierName
{
    return [networkInfo subscriberCellularProvider].carrierName;    
}


- (NSString*)isoCountryCode
{
    return [networkInfo subscriberCellularProvider].isoCountryCode;
}


- (NSString*)mobileCountryCode
{
    return [networkInfo subscriberCellularProvider].mobileCountryCode;  
}


- (NSString*)mobileNetworkCode
{
    return [networkInfo subscriberCellularProvider].mobileNetworkCode;     
}


- (BOOL)mobileCallActive
{
    return callCenter.currentCalls.count > 0;
}


- (ReachableStatus)wifiReachable
{
    return [wifiReach currentReachabilityStatus];
}


- (BOOL)wifiAccessNeedsConnection
{
    if ([wifiReach currentReachabilityStatus] == NotReachable)
    {
        return NO;
    }
    else
    {
        return [wifiReach isConnectionRequired];
    }
}


- (ReachableStatus)internetReachable
{
    return [internetReach currentReachabilityStatus];
}


- (ReachableStatus)hostReachable
{
    return [hostReach currentReachabilityStatus];
}


- (BOOL)hostAccessNeedsConnection
{
    if ([hostReach currentReachabilityStatus] == NotReachable)
    {
        return NO;
    }
    else
    {
        return [hostReach isConnectionRequired];
    }
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
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"])    // 3G
                {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
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
