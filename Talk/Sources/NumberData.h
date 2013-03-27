//
//  NumberData.h
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NumberData : NSManagedObject

// Mandatory.
@property (nonatomic, retain) NSString* name;           // Default: formatted number.
@property (nonatomic, retain) NSString* e164;
@property (nonatomic, retain) NSString* areaCode;
@property (nonatomic, retain) NSString* isoCountryCode;
@property (nonatomic, retain) NSDate*   purchaseDateTime;
@property (nonatomic, retain) NSDate*   renewalDateTime;
@property (nonatomic, assign) float     renewalPrice;

// Optional.
@property (nonatomic, retain) NSString* salutation;
@property (nonatomic, retain) NSString* firstName;
@property (nonatomic, retain) NSString* lastName;
@property (nonatomic, retain) NSString* company;
@property (nonatomic, retain) NSString* street;
@property (nonatomic, retain) NSString* building;
@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) NSString* zipCode;
@property (nonatomic, retain) NSString* stateName;
@property (nonatomic, retain) NSString* stateCode;

@end
