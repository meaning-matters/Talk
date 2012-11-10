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
#define LOAD_URL_TEST_STRING    @"<TITLE>Success</TITLE>"   // Part of received HTML
#define LOAD_URL_TEST_INTERVAL  5
#define LOAD_URL_TEST_TIMEOUT   10

NSString* const kNetworkStatusSimCardChangedNotification         = @"kNetworkStatusSimCardChangedNotification";
NSString* const kNetworkStatusMobileCallStateChangedNotification = @"kNetworkStatusMobileCallStateChangedNotification";
NSString* const kNetworkStatusReachableNotification              = @"kNetworkStatusReachableNotification";


@implementation NetworkStatus

static NetworkStatus*           sharedStatus;
static Reachability*            hostReach;
static NetworkStatusReachable   previousNetworkStatusReachable;
static CTTelephonyNetworkInfo*  networkInfo;
static CTCallCenter*            callCenter;
static NSTimer*                 loadUrlTestTimer;

@synthesize simAvailable;
@synthesize simAllowsVoIP;
@synthesize simCarrierName;
@synthesize simIsoCountryCode;
@synthesize simMobileCountryCode;
@synthesize simMobileNetworkCode;
@synthesize mobileCallActive;


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
             NetworkStatusReachable networkStatusReachable = [hostReach currentReachabilityStatus];

             NSLog(@"    HOST: %@", [hostReach currentReachabilityFlags]);

             if (networkStatusReachable != previousNetworkStatusReachable)
             {
                 // We always get here when previous is NetworkStatusReachableCaptivePortal.
                 if (networkStatusReachable == NetworkStatusReachableDisconnected)
                 {
                     NSLog(@"SEND NOTIFICATION change: %d", networkStatusReachable);
                     previousNetworkStatusReachable = networkStatusReachable;
                     [Common postNotificationName:kNetworkStatusReachableNotification
                                         userInfo:@{ @"status" : @(networkStatusReachable) }
                                           object:self];
                 }
                 else
                 {
                     // Switch between Wi-Fi and Cellular, or still at captice portal.
                     // Let's check the connection.
                     [self loadUrlTest:nil];
                 }
             }
         }
     }];

    hostReach     = [Reachability reachabilityWithHostname:REACHABILITY_HOSTNAME];

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
         [hostReach stopNotifier];

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

        if (self.simCarrierName != nil)
        {
            info = @{ @"status" : @(NetworkStatusSimCardAvailable) };
        }
        else
        {
            info = @{ @"status" : @(NetworkStatusSimCardNotAvailable) };
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
             NetworkStatusReachable networkStatusReachable;

             NSString*  html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
             if ([html rangeOfString:LOAD_URL_TEST_STRING].location != NSNotFound && error == nil)
             {
                 networkStatusReachable = [hostReach currentReachabilityStatus];
             }
             else if (error == nil)
             {
                 // Received data, but not the expected.  Check for captive portal.
                 if ([html rangeOfString:@"WISPAccessGatewayParam"].location != NSNotFound)
                 {
                     // WISPr portal reply found.
                     networkStatusReachable = NetworkStatusReachableCaptivePortal;
                 }
                 else
                 {
                     // No, or unknown captive portal.
                     //### Could be extended with WiFi & Internet status, and looking at SSID.
                     networkStatusReachable = NetworkStatusReachableDisconnected;
                 }
             }
             else
             {
                 // Error.
                 networkStatusReachable = NetworkStatusReachableDisconnected;
             }

             if (networkStatusReachable != previousNetworkStatusReachable)
             {
                 NSLog(@"SEND NOTIFICATION test: %d", networkStatusReachable);
                 previousNetworkStatusReachable = networkStatusReachable;
                 [Common postNotificationName:kNetworkStatusReachableNotification
                                     userInfo:@{ @"status" : @(networkStatusReachable) }
                                       object:self];
             }
         }];
    }
}


#pragma mark - Public API Methods

- (BOOL)simAvailable
{
    return self.simCarrierName != nil;
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
    return [[networkInfo subscriberCellularProvider].isoCountryCode uppercaseString];
}


- (NSString*)simMobileCountryCode
{
    return [networkInfo subscriberCellularProvider].mobileCountryCode;  
}


- (NSString*)simMobileNetworkCode
{
    return [networkInfo subscriberCellularProvider].mobileNetworkCode;     
}


- (BOOL)mobileCallActive
{
    return callCenter.currentCalls.count > 0;
}


- (NetworkStatusReachable)reachableStatus
{
    return previousNetworkStatusReachable;
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
