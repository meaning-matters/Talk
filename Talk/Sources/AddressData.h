//
//  AddressData.h
//  Talk
//
//  Created by Cornelis van der Bent on 18/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class NumberData;


@interface AddressData : NSManagedObject

// Mandatory.
@property (nonatomic, retain) NSString* salutation;

// Optional.
@property (nonatomic, retain) NSString* name;
@property (nonatomic, retain) NSString* uuid;             // Server assigned UUID for this address.
@property (nonatomic, retain) NSString* firstName;
@property (nonatomic, retain) NSString* lastName;
@property (nonatomic, retain) NSString* companyName;
@property (nonatomic, retain) NSString* companyDescription;
@property (nonatomic, retain) NSString* street;
@property (nonatomic, retain) NSString* buildingNumber;
@property (nonatomic, retain) NSString* buildingLetter;
@property (nonatomic, retain) NSString* city;
@property (nonatomic, retain) NSString* postcode;
@property (nonatomic, retain) NSString* isoCountryCode;
@property (nonatomic, retain) NSString* areaCode;         // Area code without country code nor leading 0.
@property (nonatomic, assign) BOOL      hasAddressProof;  // Indicates there's an image available on server.
@property (nonatomic, assign) BOOL      hasIdentityProof; // Indicates there's an image available on server.
@property (nonatomic, retain) NSData*   addressProof;     // Image data.
@property (nonatomic, retain) NSData*   identityProof;    // Image data.
@property (nonatomic, retain) NSString* idType;
@property (nonatomic, retain) NSString* idNumber;
@property (nonatomic, retain) NSString* nationality;      // ISO country code of nationality.
@property (nonatomic, retain) NSString* fiscalIdCode;
@property (nonatomic, retain) NSString* streetCode;
@property (nonatomic, retain) NSString* municipalityCode;
@property (nonatomic, assign) int16_t   addressStatus;
@property (nonatomic, assign) int32_t   rejectionReasons;

// Relationship.
@property (nonatomic, retain) NSSet<NumberData*>* numbers;


- (void)deleteWithCompletion:(void (^)(BOOL succeeded))completion;

- (void)loadProofImagesWithCompletion:(void (^)(BOOL succeeded))completion;

- (void)cancelLoadProofImages;

@end


@interface AddressData (CoreDataGeneratedAccessors)

- (void)addNumbersObject:(NumberData*)value;
- (void)removeNumbersObject:(NumberData*)value;
- (void)addNumbers:(NSSet<NumberData*>*)values;
- (void)removeNumbers:(NSSet<NumberData*>*)values;

@end
