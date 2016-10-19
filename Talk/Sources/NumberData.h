//
//  NumberData.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "CallableData.h"

@class DestinationData;
@class AddressData;


@interface NumberData : CallableData

// Mandatory.
@property (nonatomic, retain) NSString*        numberType;
@property (nonatomic, retain) NSString*        addressType;
@property (nonatomic, retain) NSString*        areaCode;
@property (nonatomic, retain) NSString*        areaName;
@property (nonatomic, retain) NSString*        isoCountryCode;
@property (nonatomic, retain) NSDate*          purchaseDate;
@property (nonatomic, retain) NSDate*          expiryDate;
@property (nonatomic, assign) BOOL             autoRenew;

// Optional.
@property (nonatomic, retain) NSString*        stateName;
@property (nonatomic, retain) NSString*        stateCode;
@property (nonatomic, retain) NSDictionary*    proofTypes;

@property (nonatomic, assign) float_t          fixedRate;
@property (nonatomic, assign) float_t          fixedSetup;
@property (nonatomic, assign) float_t          mobileRate;
@property (nonatomic, assign) float_t          mobileSetup;
@property (nonatomic, assign) float_t          payphoneRate;
@property (nonatomic, assign) float_t          payphoneSetup;

@property (nonatomic, assign) float_t          monthFee;
@property (nonatomic, assign) float_t          renewFee;

// Relationships.
@property (nonatomic, retain) DestinationData* destination;
@property (nonatomic, retain) AddressData*     address;

// Returns 1, 3, 7, or 0 when does not expire soon.
- (NSInteger)daysToSoonExpiry;

@end
