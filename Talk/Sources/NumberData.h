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


@interface NumberData : CallableData

// Mandatory.
@property (nonatomic, retain) NSString*        numberType;
@property (nonatomic, retain) NSString*        areaCode;
@property (nonatomic, retain) NSString*        areaName;
@property (nonatomic, retain) NSString*        numberCountry;  // ISO country code.
@property (nonatomic, retain) NSDate*          purchaseDate;
@property (nonatomic, retain) NSDate*          renewalDate;

// Optional.
@property (nonatomic, retain) NSString*        salutation;
@property (nonatomic, retain) NSString*        firstName;
@property (nonatomic, retain) NSString*        lastName;
@property (nonatomic, retain) NSString*        company;
@property (nonatomic, retain) NSString*        street;
@property (nonatomic, retain) NSString*        building;
@property (nonatomic, retain) NSString*        city;
@property (nonatomic, retain) NSString*        zipCode;
@property (nonatomic, retain) NSString*        stateName;
@property (nonatomic, retain) NSString*        stateCode;
@property (nonatomic, retain) NSString*        addressCountry; // ISO country code.
@property (nonatomic, retain) NSData*          image;          // Proof of address.
@property (nonatomic, retain) NSNumber*        imageAccepted;

// Relationships.
@property (nonatomic, retain) DestinationData* destination;

@end
