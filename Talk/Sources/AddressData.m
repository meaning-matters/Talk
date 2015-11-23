//
//  AddressData.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressData.h"
#import "NumberData.h"


@implementation AddressData

// Mandatory.
@dynamic salutation;

// Optional.
@dynamic name;
@dynamic addressId;
@dynamic firstName;
@dynamic lastName;
@dynamic companyName;
@dynamic companyDescription;
@dynamic street;
@dynamic buildingNumber;
@dynamic buildingLetter;
@dynamic city;
@dynamic postcode;
@dynamic isoCountryCode;
@dynamic hasProof;
@dynamic proofImage;
@dynamic idType;
@dynamic idNumber;
@dynamic fiscalIdCode;
@dynamic streetCode;
@dynamic municipalityCode;
@dynamic status;
@dynamic rejectionReasons;

// Relationship.
@dynamic numbers;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion
{
}


+ (AddressStatus)addressStatusWithString:(NSString*)addressStatusString
{
    if ([addressStatusString isEqualToString:@"NOT_VERIFIED"])
    {
        return AddressStatusNotVerified;
    }
    
    if ([addressStatusString isEqualToString:@"DISABLED"])
    {
        return AddressStatusDisabled;
    }
    
    if ([addressStatusString isEqualToString:@"VERIFIED"])
    {
        return AddressStatusVerified;
    }
    
    if ([addressStatusString isEqualToString:@"VERIFICATION_REQUESTED"])
    {
        return AddressStatusVerificationRequested;
    }
    
    if ([addressStatusString isEqualToString:@"REJECTED"])
    {
        return AddressStatusRejected;
    }
    
    return AddressStatusUnknown;
}


+ (RejectionReasonMask)rejectionReasonMaskWithArray:(NSArray*)rejectionReasons
{
    RejectionReasonMask rejectionReasonMask = 0;

    for (NSString* rejectionReason in rejectionReasons)
    {
        if ([rejectionReason isEqualToString:@"INVALID_DOCTYPE"])
        {
            rejectionReasonMask |= RejectionReasonInvalidDocumentTypeMask;
        }
        
        if ([rejectionReason isEqualToString:@"NOT_RECENT_ENOUGH"])
        {
            rejectionReasonMask |= RejectionReasonNotRecentEnoughMask;
        }
        
        if ([rejectionReason isEqualToString:@"DOC_ILLEGIBLE"])
        {
            rejectionReasonMask |= RejectionReasonDocumentIllegibleMask;
        }
        
        if ([rejectionReason isEqualToString:@"INFO_MISMATCH"])
        {
            rejectionReasonMask |= RejectionReasonInfoMismatchMask;
        }
        
        if ([rejectionReason isEqualToString:@"INFO_INCOMPLETE"])
        {
            rejectionReasonMask |= RejectionReasonInfoIncompleteMask;
        }
        
        if ([rejectionReason isEqualToString:@"OTHER"])
        {
            rejectionReasonMask |= RejectionReasonOtherMask;
        }
    }
    
    return rejectionReasonMask;
}

@end
