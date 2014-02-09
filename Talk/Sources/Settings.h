//
//  Settings.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NumberType.h"


@interface Settings : NSObject

+ (Settings*)sharedSettings;

- (void)resetAll;

- (BOOL)haveAccount;

- (BOOL)haveVerifiedAccount;

@property (nonatomic, strong) NSArray*          tabBarViewControllerClasses;
@property (nonatomic, assign) NSInteger         tabBarSelectedIndex;    // The current tab.

@property (nonatomic, strong) NSString*         errorDomain;            // Used when creating an NSError.

@property (nonatomic, strong) NSString*         homeCountry;            // ISO Country Code.
@property (nonatomic, assign) BOOL              homeCountryFromSim;     // ISO Country Code.

@property (nonatomic, strong) NSString*         lastDialedNumber;
@property (nonatomic, assign) BOOL              warnedAboutDefaultCli;

@property (nonatomic, strong) NSString*         webBaseUrl;             // Base URL of web API.
@property (nonatomic, strong) NSString*         webUsername;
@property (nonatomic, strong) NSString*         webPassword;

@property (nonatomic, strong) NSString*         sipServer;
@property (nonatomic, strong) NSString*         sipRealm;
@property (nonatomic, strong) NSString*         sipUsername;
@property (nonatomic, strong) NSString*         sipPassword;

@property (nonatomic, assign) BOOL              allowCellularDataCalls;
@property (nonatomic, assign) BOOL              showCallerId;
@property (nonatomic, assign) BOOL              callbackMode;
@property (nonatomic, strong) NSString*         callerIdE164;           // Caller ID E164, used until Groups are implemented.
@property (nonatomic, strong) NSString*         callbackE164;           // Called back E164, used until Groups are implemented.

@property (nonatomic, assign) NumberTypeMask    numberTypeMask;         // Selected numberType in NumberView.
@property (nonatomic, assign) NSInteger         numbersSortSegment;     // Selected numbers sort segmented control index.
@property (nonatomic, assign) NSInteger         forwardingsSelection;   // Selected segment/table in ForwardingsView.

@property (nonatomic, strong) NSString*         currencyCode;           // Backup until Store products are received.
@property (nonatomic, assign) float             credit;                 // Holds most recent credit update.

@property (nonatomic, strong) NSDictionary*     pendingNumberBuy;       // Used by PurchaseManager when server failed to process number.

@property (nonatomic, assign) BOOL              needsServerSync;        // YES when CoreData was wiped after error.

@property (nonatomic, readonly) NSString*       appId;                  // Used in rate-app URL.
@property (nonatomic, readonly) NSString*       appVersion;
@property (nonatomic, readonly) NSString*       appDisplayName;
@property (nonatomic, readonly) NSString*       companyNameAddress;     // Used on About.

@property (nonatomic, readonly) NSString*       testNumber;             // The short number for doing VoIP test calls.
@property (nonatomic, readonly) NSString*       supportNumber;          // NumberBay telephone support number.
@property (nonatomic, readonly) NSString*       supportEmail;           // NumberBay email support address.

@end
