//
//  NetworkStatus.h
//  Talk
//
//  Created by Cornelis van der Bent on 08/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Reachability.h"


extern NSString* const  NetworkStatusSimChangedNotification;
extern NSString* const  NetworkStatusMobileCallStateChangedNotification;
extern NSString* const  NetworkStatusReachableNotification;

typedef enum
{
    NetworkStatusSimAvailable,
    NetworkStatusSimNotAvailable,
} NetworkStatusSim;

typedef enum
{
    NetworkStatusMobileCallDialing,
    NetworkStatusMobileCallIncoming,
    NetworkStatusMobileCallConnected,
    NetworkStatusMobileCallDisconnected,
} NetworkStatusMobileCall;

// IMPORTANT: We assume that the values of ReachableStatus match these here!
typedef enum
{
    NetworkStatusReachableDisconnected,
    NetworkStatusReachableCellular,
    NetworkStatusReachableWifi,
    NetworkStatusReachableCaptivePortal,    // Extra compared to ReachableStatus.
} NetworkStatusReachable;


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

//  Give the most recent internet connection status.
@property (nonatomic, readonly) NetworkStatusReachable  reachableStatus;

- (NSString*)internalIPAddress;

- (NSString*)getSsid;

@end
