//
//  NetworkStatus.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"


extern NSString* const  kNetworkStatusSimCardChangedNotification;
extern NSString* const  kNetworkStatusMobileCallStateChangedNotification;
extern NSString* const  kNetworkStatusInternetConnectionNotification;

typedef enum
{
    NetworkStatusSimCardAvailable,
    NetworkStatusSimCardNotAvailable,
} NetworkStatusSimCard;

typedef enum
{
    NetworkStatusMobileCallDialing,
    NetworkStatusMobileCallIncoming,
    NetworkStatusMobileCallConnected,
    NetworkStatusMobileCallDisconnected,
} NetworkStatusMobileCall;

typedef enum
{
    NetworkStatusInternetConnectionDisconnected,
    NetworkStatusInternetConnectionCellular,
    NetworkStatusInternetConnectionWifi,
} NetworkStatusInternetConnection;


@class CTCallCenter;

@interface NetworkStatus : NSObject


//  Indicates if the carrier allows VoIP calls to be made on its network.
@property (nonatomic, readonly) BOOL            carrierAllowsVoIP;

//  The name of the user’s home cellular service provider, or nil.
@property (nonatomic, readonly) NSString*       carrierName;

//  The ISO country code for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*       isoCountryCode;

//  The mobile country code (MCC) for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*       mobileCountryCode;

//  The mobile network code (MNC) for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*       mobileNetworkCode;

//  Indicates if (at least) one mobile call is active.
@property (nonatomic, readonly) BOOL            mobileCallActive;

//  Indicates if the local WiFi point can be reached.  Does not guarantee internet connection.
@property (nonatomic, readonly) ReachableStatus wifiReachable;

//  Indicates if Wi-Fi needs a connection; e.g. for VPN on demand.
@property (nonatomic, readonly) BOOL            wifiAccessNeedsConnection;

//  Indicates via which way (Wi-Fi or WWAN) default TCP/IP routing is reachable.
@property (nonatomic, readonly) ReachableStatus internetReachable;

//  Indicates via which way (Wi-Fi or WWAN) we're connect to outside internet.
@property (nonatomic, readonly) ReachableStatus hostReachable;

//  WWAN may be available, but not active until a connection has been established.
@property (nonatomic, readonly) BOOL            hostAccessNeedsConnection;


+ (NetworkStatus*)sharedStatus;

- (NSString*)internalIPAddress;

- (NSString*)getSsid;

@end
