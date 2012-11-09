//
//  Reachability.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2011 Tony Million.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>


extern NSString* const  kReachabilityChangedNotification;


// Apple NetworkStatus Compatible Names.
typedef enum
{
    NotReachable     = 0,
    ReachableViaWWAN = 1,
    ReachableViaWiFi = 2,
} ReachableStatus;


@class Reachability;

typedef void (^NetworkReachable)(Reachability* reachability);
typedef void (^NetworkUnreachable)(Reachability* reachability);


@interface Reachability : NSObject

@property (nonatomic, copy) NetworkReachable    reachableBlock;
@property (nonatomic, copy) NetworkUnreachable  unreachableBlock;


+ (Reachability*)reachabilityWithHostname:(NSString*)hostname;
+ (Reachability*)reachabilityForInternetConnection;
+ (Reachability*)reachabilityWithAddress:(const struct sockaddr_in*)hostAddress;
+ (Reachability*)reachabilityForLocalWiFi;

- (BOOL)startNotifier;
- (void)stopNotifier;

- (BOOL)isReachable;
- (BOOL)isReachableViaWWAN;
- (BOOL)isReachableViaWiFi;

// WWAN may be available, but not active until a connection has been established.
// Wi-Fi may require a connection for VPN on Demand.
- (BOOL)isConnectionRequired;

// Dynamic, on demand connection?
- (BOOL)isConnectionOnDemand;

// Is user intervention required?
- (BOOL)isInterventionRequired;

- (ReachableStatus)currentReachabilityStatus;
- (SCNetworkReachabilityFlags)reachabilityFlags;
- (NSString*)currentReachabilityString;
- (NSString*)currentReachabilityFlags;

@end
