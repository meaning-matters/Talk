//
//  Settings.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NumberType.h"


@interface Settings : NSObject

+ (Settings*)sharedSettings;

- (void)synchronize;

- (void)resetAll;

- (BOOL)haveAccount;


@property (nonatomic, strong) NSArray*       tabBarClassNames;
@property (nonatomic, assign) NSUInteger     tabBarSelectedIndex;   // The current tab.

@property (nonatomic, strong) NSString*      errorDomain;           // Used when creating an NSError.

@property (nonatomic, strong) NSString*      homeCountry;           // ISO Country Code.
@property (nonatomic, assign) BOOL           homeCountryFromSim;    // ISO Country Code.

@property (nonatomic, strong) NSString*      lastDialedNumber;

@property (nonatomic, strong) NSString*      webUsername;
@property (nonatomic, strong) NSString*      webPassword;

@property (nonatomic, assign) BOOL           showCallerId;
@property (nonatomic, strong) NSString*      callerIdE164;          // Caller ID E164, used until Groups are implemented.
@property (nonatomic, strong) NSString*      callbackE164;          // Called back E164, used until Groups are implemented.

@property (nonatomic, assign) NumberTypeMask numberTypeMask;        // Selected numberType in NumberView.
@property (nonatomic, assign) NSInteger      numbersSortSegment;    // Selected numbers sort segmented control index.
@property (nonatomic, assign) NSInteger      forwardingsSelection;  // Selected segment/table in ForwardingsView.

@property (nonatomic, strong) NSString*      storeCurrencyCode;     // Backup until Store products are received.
@property (nonatomic, strong) NSString*      storeCountryCode;      // Backup until Store products are received.
@property (nonatomic, assign) float          credit;                // Holds most recent credit update.

@property (nonatomic, assign) BOOL           needsServerSync;       // YES when CoreData was wiped after error.

@property (nonatomic, readonly) NSString*    appId;                 // Used in rate-app URL.
@property (nonatomic, readonly) NSString*    appVersion;
@property (nonatomic, readonly) NSString*    appDisplayName;

@property (nonatomic, readonly) NSString*    companyName;           // Company official name.
@property (nonatomic, readonly) NSString*    companyAddress1;       // Company address line 1.
@property (nonatomic, readonly) NSString*    companyAddress2;       // Company address line 2.
@property (nonatomic, readonly) NSString*    companyCity;           // Company city.
@property (nonatomic, readonly) NSString*    companyPostcode;       // Company postal code.
@property (nonatomic, readonly) NSString*    companyCountry;        // Company country.
@property (nonatomic, readonly) NSString*    companyPhone;          // Company (support) phone number.
@property (nonatomic, readonly) NSString*    companyEmail;          // Company (support) email address.
@property (nonatomic, readonly) NSString*    companyWebsite;        // Company website URL.

@property (nonatomic, readonly) NSString*    dnsHost;               // URL to DNS request list of servers.
@property (nonatomic, readonly) NSString*    serverTestUrlPath;     // Path of server test URL.

@end
