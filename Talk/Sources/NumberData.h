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
@property (nonatomic, retain) NSString*        areaId;
@property (nonatomic, retain) NSString*        isoCountryCode;
@property (nonatomic, retain) NSDate*          purchaseDate;
@property (nonatomic, retain) NSDate*          expiryDate;
@property (nonatomic, assign) int16_t          notifiedExpiryDays;  // Can be INT16_MAX, 7, 3, 1, or 0 (expired).
@property (nonatomic, assign) BOOL             autoRenew;

// Optional.
@property (nonatomic, retain) NSString*        stateName;
@property (nonatomic, retain) NSString*        stateCode;

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

- (BOOL)isPending;

// Returns 7, 3, or 1 when expiry is within 7, 3, or 1 days repectively, or return 0 when expiry is longer than 7 days away.
- (int16_t)expiryDays;

// Returns YES when expiry is within 7 days; includes expired state.
- (BOOL)isExpiryCritical;

// Returns YES when expiryDate has passed.
- (BOOL)hasExpired;

- (void)showExpiryAlertWithCompletion:(void (^)(void))completion;

- (NSString*)alertTextForExpiryHours:(NSInteger)expiryHours;

- (NSString*)purchaseDateString;

- (NSString*)expiryDateString;

@end
