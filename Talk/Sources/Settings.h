//
//  Settings.h
//  Talk
//
//  Created by Cornelis van der Bent on 07/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NumberType.h"
#import "CountryRegions.h"


@interface Settings : NSObject

+ (Settings*)sharedSettings;

- (void)synchronize;

- (void)resetAll;

- (BOOL)haveAccount;


@property (nonatomic, strong) NSArray*       tabBarClassNames;
@property (nonatomic, assign) NSUInteger     tabBarSelectedIndex;   // The current tab.

@property (nonatomic, strong) NSString*      errorDomain;           // Used when creating an NSError.

@property (nonatomic, strong) NSString*      homeIsoCountryCode;    // ISO country code selected by user.
@property (nonatomic, assign) BOOL           useSimIsoCountryCode;  // Use ISO country code from SIM card.

@property (nonatomic, strong) NSString*      lastDialedNumber;      // Most recent number called from keypad.

@property (nonatomic, strong) NSDate*        recentsCheckDate;      // Date of last time recents were checked on server.
@property (nonatomic, strong) NSDate*        synchronizeDate;       // Date of last synchronisation with server.

@property (nonatomic, strong) NSString*      webUsername;
@property (nonatomic, strong) NSString*      webPassword;
@property (nonatomic, readonly) NSString*    deviceTokenReplacement;

@property (nonatomic, assign) BOOL           showCallerId;
@property (nonatomic, strong) NSString*      callerIdE164;          // Caller ID E164, used until Groups are implemented.
@property (nonatomic, strong) NSString*      callbackE164;          // Called back E164, used until Groups are implemented.

@property (nonatomic, assign) NumberTypeMask numberTypeMask;        // Selected numberType in NumberBuyView.
@property (nonatomic, assign) CountryRegion  countryRegion;         // Selected region in CallRatesView.
@property (nonatomic, assign) NSInteger      sortSegment;           // Selected Numbers/Phones sort segmented control index.
@property (nonatomic, assign) BOOL           showFootnotes;         // If footer titles under tables sections must be shown.
@property (nonatomic, assign) NSInteger      destinationsSelection; // Selected segment/table in DestinationsView.

@property (nonatomic, strong) NSString*      storeCurrencyCode;     // Backup until Store products are received.
@property (nonatomic, strong) NSString*      storeCountryCode;      // Backup until Store products are received.
@property (nonatomic, assign) float          credit;                // Holds most recent credit update.

@property (nonatomic, assign) BOOL           needsServerSync;       // YES when CoreData was wiped after error.

@property (nonatomic, assign) NSDictionary*  numberFilter;          // Dictionary that defines which Number regions to show as being available.

@property (nonatomic, strong) NSDictionary*  addressUpdates;        // Unseen address updates.

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

@property (nonatomic, strong) NSString*      dnsSrvPrefix;          // First path component of DNS-SRV name.  Setting to `nil` selects default.
@property (nonatomic, readonly) NSString*    dnsSrvName;            // DNS-SRV servers name.
@property (nonatomic, readonly) NSString*    serverTestUrlPath;     // Path of server test URL.
@property (nonatomic, readonly) NSString*    fallbackServer;        // Server used when DNS-SRV fails.

@end
