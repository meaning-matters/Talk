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

typedef NS_ENUM(NSUInteger, AddressStatus)
{
    AddressStatusUnknown               = 0,
    AddressStatusNotVerified           = 1,
    AddressStatusDisabled              = 2,
    AddressStatusVerified              = 3,
    AddressStatusVerificationRequested = 4,
    AddressStatusRejected              = 5,
};

/*INVALID_DOCTYPE, NOT_RECENT_ENOUGH, DOC_ILLEGIBLE, INFO_MISMATCH, INFO_INCOMPLETE, OTHER*/
typedef NS_ENUM(NSUInteger, RejectionReasonMask)
{
    RejectionReasonInvalidDocumentTypeMask = 1UL << 0,
    RejectionReasonNotRecentEnoughMask     = 1UL << 1,
    RejectionReasonDocumentIllegibleMask   = 1UL << 2,
    RejectionReasonInfoMismatchMask        = 1UL << 3,
    RejectionReasonInfoIncompleteMask      = 1UL << 4,
    RejectionReasonOtherMask               = 1UL << 5,
};


@interface AddressData : NSManagedObject

// Mandatory.
@property (nonatomic, retain) NSString*           salutation;

// Optional.
@property (nonatomic, retain) NSString*           name;
@property (nonatomic, retain) NSString*           addressId;        // Server assigned ID for this address.
@property (nonatomic, retain) NSString*           firstName;
@property (nonatomic, retain) NSString*           lastName;
@property (nonatomic, retain) NSString*           companyName;
@property (nonatomic, retain) NSString*           companyDescription;
@property (nonatomic, retain) NSString*           street;
@property (nonatomic, retain) NSString*           buildingNumber;
@property (nonatomic, retain) NSString*           buildingLetter;
@property (nonatomic, retain) NSString*           city;
@property (nonatomic, retain) NSString*           postcode;
@property (nonatomic, retain) NSString*           isoCountryCode;
@property (nonatomic, assign) BOOL                hasProof;         // Indicates there's an image available on server.
@property (nonatomic, retain) NSData*             proofImage;
@property (nonatomic, retain) NSString*           idType;
@property (nonatomic, retain) NSString*           idNumber;
@property (nonatomic, retain) NSString*           fiscalIdCode;
@property (nonatomic, retain) NSString*           streetCode;
@property (nonatomic, retain) NSString*           municipalityCode;
@property (nonatomic, assign) int16_t             status;
@property (nonatomic, assign) int16_t             rejectionReasons;

// Relationship.
@property (nonatomic, retain) NSSet<NumberData*>* numbers;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion;

+ (AddressStatus)addressStatusWithString:(NSString*)addressStatusString;

+ (RejectionReasonMask)rejectionReasonMaskWithArray:(NSArray*)rejectionReasons;

@end


@interface AddressData (CoreDataGeneratedAccessors)

- (void)addNumbersObject:(NumberData*)value;
- (void)removeNumbersObject:(NumberData*)value;
- (void)addNumbers:(NSSet<NumberData*>*)values;
- (void)removeNumbers:(NSSet<NumberData*>*)values;

@end
