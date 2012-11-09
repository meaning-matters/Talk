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

#define REACHABILITY_HOSTNAME   @"www.google.com"
#define LOAD_URL_TEST_URL       @"http://www.apple.com/library/test/success.html"
#define LOAD_URL_TEST_INTERVAL  5
#define LOAD_URL_TEST_TIMEOUT   10

NSString* const kNetworkStatusSimCardChangedNotification         = @"kNetworkStatusSimCardChangedNotification";
NSString* const kNetworkStatusMobileCallStateChangedNotification = @"kNetworkStatusMobileCallStateChangedNotification";
NSString* const kNetworkStatusInternetConnectionNotification     = @"kNetworkStatusInternetConnectionNotification";


@implementation NetworkStatus

static NetworkStatus*           sharedStatus;
static Reachability*            hostReach;
static Reachability*            internetReach;
static Reachability*            wifiReach;
static ReachableStatus          previousHostReachableStatus = NotReachable;
static CTTelephonyNetworkInfo*  networkInfo;
static CTCallCenter*            callCenter;
static NSTimer*                 loadUrlTestTimer;

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
        [sharedStatus setUpReachability];
        [sharedStatus setUpCoreTelephony];
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


- (void)setUpReachability
{
    [[NSNotificationCenter defaultCenter] addObserverForName:kReachabilityChangedNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
     {
         if (note.object == hostReach)
         {
             ReachableStatus    reachableStatus = [hostReach currentReachabilityStatus];

             NSLog(@"    HOST: %@", [hostReach currentReachabilityFlags]);

             if (reachableStatus != previousHostReachableStatus)
             {
                 if (reachableStatus == NotReachable)
                 {
                     NSLog(@"SEND NOTIFICATION change: %d", reachableStatus);
                     previousHostReachableStatus = reachableStatus;
                     [Common postNotificationName:kNetworkStatusInternetConnectionNotification
                                         userInfo:@{ @"status" : @(reachableStatus) }
                                           object:self];
                 }
                 else
                 {
                     // Switch between Wi-Fi and Cellular.  Let's check the connection.
                     [self loadUrlTest:nil];
                 }
             }
         }

         if (note.object == internetReach)
         {
             // Not interesting for app to know - do nothing.
         }

         if (note.object == wifiReach)
         {
             // Not interesting for app to know - do nothing.
         }
     }];

    hostReach     = [Reachability reachabilityWithHostname:REACHABILITY_HOSTNAME];
    internetReach = [Reachability reachabilityForInternetConnection];
    wifiReach     = [Reachability reachabilityForLocalWiFi];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
     {
         // The UIApplicationDidBecomeActiveNotification can be received a second
         // time (e.g. after "Turn Off Airplane More or Use Wi-Fi to Access Data").
         // Use loadUrlTestTimer as flag to make sure we set up only once.
         //
         // (BTW, UIApplicationWillEnterForegroundNotification is not received
         //  the first time, when the app starts.  So that would not have helped.)
         if (loadUrlTestTimer == nil)
         {
             [sharedStatus  loadUrlTest:nil];
             [hostReach     startNotifier];
             [internetReach startNotifier];
             [wifiReach     startNotifier];

             loadUrlTestTimer = [NSTimer scheduledTimerWithTimeInterval:LOAD_URL_TEST_INTERVAL
                                                                 target:self
                                                               selector:@selector(loadUrlTest:)
                                                               userInfo:nil
                                                                repeats:YES];
         }
     }];

    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification
                                                      object:nil
                                                       queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification* note)
     {
         [hostReach     stopNotifier];
         [internetReach stopNotifier];
         [wifiReach     stopNotifier];

         [loadUrlTestTimer invalidate];
         loadUrlTestTimer = nil;
     }];
}


- (void)setUpCoreTelephony
{
    networkInfo = [[CTTelephonyNetworkInfo alloc] init];
    networkInfo.subscriberCellularProviderDidUpdateNotifier = ^(CTCarrier*carrier)
    {
        NSDictionary*   info;

        if ([self isoCountryCode])
        {
            info = @{ @"status"         : @(NetworkStatusSimCardAvailable),
                      @"isoCountryCode" : [self isoCountryCode] };
        }
        else
        {
            info = @{ @"status"         : @(NetworkStatusSimCardNotAvailable) };
        }
        
        [Common postNotificationName:kNetworkStatusSimCardChangedNotification
                            userInfo:info
                              object:self];
    };

    callCenter  = [[CTCallCenter alloc] init];
    callCenter.callEventHandler=^(CTCall* call)
    {
        if (call.callState == CTCallStateDialing)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"status" : @(NetworkStatusMobileCallDialing) }
                                  object:self];
        }
        else if (call.callState == CTCallStateIncoming)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"status" : @(NetworkStatusMobileCallIncoming) }
                                  object:self];
        }
        else if (call.callState == CTCallStateConnected)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"status" : @(NetworkStatusMobileCallConnected) }
                                  object:self];
        }
        else if (call.callState == CTCallStateDisconnected)
        {
            [Common postNotificationName:kNetworkStatusMobileCallStateChangedNotification
                                userInfo:@{ @"status" : @(NetworkStatusMobileCallDisconnected) }
                                  object:self];
        }
    };
}


- (void)loadUrlTest:(NSTimer*)timer
{
    if (timer == nil || [hostReach isReachable])
    {
        NSURL*          url = [NSURL URLWithString:LOAD_URL_TEST_URL];
        NSURLRequest*   request = [NSURLRequest requestWithURL:url
                                                   cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                               timeoutInterval:LOAD_URL_TEST_TIMEOUT];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[[NSOperationQueue alloc] init]
                               completionHandler:^(NSURLResponse* response, NSData* data, NSError* error)
         {
             ReachableStatus reachableStatus;
             if ([data length] > 0 && error == nil)
             {
                 reachableStatus = [hostReach currentReachabilityStatus];
             }
             else
             {
                 reachableStatus = NotReachable;
             }

             if (reachableStatus != previousHostReachableStatus)
             {
                 NSLog(@"SEND NOTIFICATION test: %d", reachableStatus);
                 previousHostReachableStatus = reachableStatus;
                 // IMPORTANT: We assume here that the values of ReachableStatus
                 //            match those of NetworkStatusInternetConnection.
                 [Common postNotificationName:kNetworkStatusInternetConnectionNotification
                                     userInfo:@{ @"status" : @(reachableStatus) }
                                       object:self];
             }
         }];
    }
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
    return [[networkInfo subscriberCellularProvider].isoCountryCode uppercaseString];
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
                   [[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"pdp_ip0"])    // 3G/Edge, ...?
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
