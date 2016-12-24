//
//  AddressStatus.h
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, AddressStatusMask)
{
    AddressStatusUnknown                   = 0,
    AddressStatusStagedMask                = 1UL << 0,
    AddressStatusNotVerifiedMask           = 1UL << 1,  // Default status for Numbers without Voxbone Address requirement.
    AddressStatusVerificationRequestedMask = 1UL << 2,
    AddressStatusVerifiedMask              = 1UL << 3,
    AddressStatusRejectedMask              = 1UL << 4,
    AddressStatusDisabledMask              = 1UL << 5,
};

typedef NS_ENUM(NSUInteger, RejectionReasonMask)
{
    RejectionReasonUnknown                          = 0,
    RejectionReasonInvalidDoctypeMask               = 1UL <<  0,
    RejectionReasonInvalidDoctypeVirtualAddressMask = 1UL <<  1,
    RejectionReasonInvalidDoctypeThirdPartyMask     = 1UL <<  2,
    RejectionReasonInvalidDoctypeNoAddressMask      = 1UL <<  3,
    RejectionReasonInvalidDoctypeRequiredIdMask     = 1UL <<  4,
    RejectionReasonNotRecentEnoughMask              = 1UL <<  5,
    RejectionReasonDocIllegibleMask                 = 1UL <<  6,
    RejectionReasonInfoMismatchMask                 = 1UL <<  7,
    RejectionReasonInfoMismatchWithProofMask        = 1UL <<  8,
    RejectionReasonInfoMismatchAddressMask          = 1UL <<  9,
    RejectionReasonInfoMismatchLocationMask         = 1UL << 10,
    RejectionReasonInfoIncompleteMask               = 1UL << 11,
    RejectionReasonInfoIncompleteDateMask           = 1UL << 12,
    RejectionReasonInfoIncompleteAddressMask        = 1UL << 13,
    RejectionReasonOtherMask                        = 1UL << 14,
};


@interface AddressStatus : NSObject

+ (AddressStatusMask)addressStatusMaskForString:(NSString*)string;

+ (RejectionReasonMask)rejectionReasonMaskForString:(NSString*)string;

+ (RejectionReasonMask)rejectionReasonsMaskForArray:(NSArray*)array;

+ (NSArray*)rejectionReasonMessagesForMask:(RejectionReasonMask)mask;

/**
 *  Checks if the address mask is of an Address that is available for use;
 *  i.e., it is either AddressStatusNotVerifiedMask or AddressStatusVerifiedMask.
 */
+ (BOOL)isAvailableAddressStatusMask:(AddressStatusMask)mask;

@end
