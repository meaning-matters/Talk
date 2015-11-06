//
//  NetworkStatus.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


extern NSString* const NetworkStatusSimChangedNotification;
extern NSString* const NetworkStatusMobileCallStateChangedNotification;
extern NSString* const NetworkStatusReachableNotification;

typedef NS_ENUM(NSUInteger, NetworkStatusSim)
{
    NetworkStatusSimAvailable,
    NetworkStatusSimNotAvailable,
};

typedef NS_ENUM(NSUInteger, NetworkStatusMobileCall)
{
    NetworkStatusMobileCallDialing,
    NetworkStatusMobileCallIncoming,
    NetworkStatusMobileCallConnected,
    NetworkStatusMobileCallDisconnected,
};

typedef NS_ENUM(NSInteger, NetworkStatusReachable)
{
    NetworkStatusReachableUnknown      = -1,
    NetworkStatusReachableDisconnected =  0,
    NetworkStatusReachableCellular     =  1,
    NetworkStatusReachableWifi         =  2,
};


@class CTCallCenter;

@interface NetworkStatus : NSObject

// Must be called once early at app startup.
+ (NetworkStatus*)sharedStatus;

//  Tells if there is a SIM card.  Is redundant, because is same as one of
//  below simXyz methods returning non-nil.
@property (nonatomic, readonly) BOOL                    simAvailable;

//  Indicates if the carrier allows VoIP calls to be made on its network.
@property (nonatomic, readonly) BOOL                    simAllowsVoIP;

//  The name of the user’s home cellular service provider, or nil.
@property (nonatomic, readonly) NSString*               simCarrierName;

//  The ISO country code for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*               simIsoCountryCode;

//  The mobile country code (MCC) for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*               simMobileCountryCode;

//  The mobile network code (MNC) for the user’s cellular service provider, or nil.
@property (nonatomic, readonly) NSString*               simMobileNetworkCode;

//  Returns an array of dictionaries.  A dictionary contains a string "id",
//  plus the boxed (in NSNumber) NetworkStatusMobileCall "state".  Nil is
//  returned when there are no calls.
@property (nonatomic, readonly) NSArray*                activeMobileCalls;

@property (nonatomic, readonly) BOOL                    allowsMobileCalls;

//  Give the most recent internet connection status.
@property (nonatomic, readonly) NetworkStatusReachable  reachableStatus;

- (NSString*)internalIPAddress;

- (NSString*)getSsid;

@end
