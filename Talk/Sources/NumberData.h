//
//  NumberData.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ForwardingData;

@interface NumberData : NSManagedObject

// Mandatory.
@property (nonatomic, retain) NSString*       name;           // Default: formatted number.
@property (nonatomic, retain) NSString*       e164;
@property (nonatomic, retain) NSString*       numberType;
@property (nonatomic, retain) NSString*       areaCode;
@property (nonatomic, retain) NSString*       areaName;
@property (nonatomic, retain) NSString*       numberCountry;  // ISO country code.
@property (nonatomic, retain) NSDate*         purchaseDate;
@property (nonatomic, retain) NSDate*         renewalDate;

// Optional.
@property (nonatomic, retain) NSString*       salutation;
@property (nonatomic, retain) NSString*       firstName;
@property (nonatomic, retain) NSString*       lastName;
@property (nonatomic, retain) NSString*       company;
@property (nonatomic, retain) NSString*       street;
@property (nonatomic, retain) NSString*       building;
@property (nonatomic, retain) NSString*       city;
@property (nonatomic, retain) NSString*       zipCode;
@property (nonatomic, retain) NSString*       stateName;
@property (nonatomic, retain) NSString*       stateCode;
@property (nonatomic, retain) NSString*       addressCountry; // ISO country code.
@property (nonatomic, retain) NSData*         proofImage;
@property (nonatomic, retain) NSNumber*       proofAccepted;

// Relationships.
@property (nonatomic, retain) ForwardingData* forwarding;


- (void)setPurchaseDateWithString:(NSString*)dateString;

- (NSString*)stringPurchaseDateTime;

- (void)setRenewalDateWithString:(NSString*)dateString;

- (NSString*)stringRenewalDateTime;

@end
