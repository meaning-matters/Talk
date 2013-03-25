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

@property (nonatomic, readonly) BOOL            runBefore;          // NO if this is the first time the app runs.

@property (nonatomic, strong) NSArray*          tabBarViewControllerClasses;

@property (nonatomic, strong) NSString*         errorDomain;        // Used when creating an NSError.

@property (nonatomic, strong) NSString*         homeCountry;        // ISO Country Code.
@property (nonatomic, assign) BOOL              homeCountryFromSim; // ISO Country Code.

@property (nonatomic, strong) NSString*         lastDialedNumber;

@property (nonatomic, strong) NSString*         webBaseUrl;         // Base URL of web API.
@property (nonatomic, strong) NSString*         webUsername;
@property (nonatomic, strong) NSString*         webPassword;

@property (nonatomic, strong) NSString*         sipServer;
@property (nonatomic, strong) NSString*         sipRealm;
@property (nonatomic, strong) NSString*         sipUsername;
@property (nonatomic, strong) NSString*         sipPassword;

@property (nonatomic, assign) BOOL              allowCellularDataCalls;

@property (nonatomic, assign) BOOL              louderVolume;

@property (nonatomic, assign) NumberTypeMask    numberTypeMask;     // Most recent selected numberType.

@end
