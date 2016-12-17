//
//  AddressStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "AddressStatus.h"

@implementation AddressStatus

+ (AddressStatusMask)addressStatusMaskForString:(NSString*)string
{
    AddressStatusMask mask;

    if ([string isEqualToString:@"STAGED"])
    {
        mask = AddressStatusStagedMask;
    }
    if ([string isEqualToString:@"NOT_VERIFIED"])
    {
        mask = AddressStatusNotVerifiedMask;
    }
    else if ([string isEqualToString:@"VERIFICATION_REQUESTED"])
    {
        mask = AddressStatusVerificationRequestedMask;
    }
    else if ([string isEqualToString:@"VERIFIED"])
    {
        mask = AddressStatusVerifiedMask;
    }
    else if ([string isEqualToString:@"REJECTED"])
    {
        mask = AddressStatusRejectedMask;
    }
    else if ([string isEqualToString:@"DISABLED"])
    {
        mask = AddressStatusDisabledMask;
    }
    else
    {
        mask = AddressStatusUnknown;   //### We should never get here.
    }

    return mask;
}


+ (RejectionReasonMask)rejectionReasonMaskForString:(NSString*)string
{
    RejectionReasonMask mask;

    if ([string isEqualToString:@"INVALID_DOCTYPE"])
    {
        mask = RejectionReasonInvalidDoctypeMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_VIRTUAL_ADDRESS"])
    {
        mask = RejectionReasonInvalidDoctypeVirtualAddressMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_THIRD_PARTY"])
    {
        mask = RejectionReasonInvalidDoctypeThirdPartyMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_NO_ADDRESS"])
    {
        mask = RejectionReasonInvalidDoctypeNoAddressMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_REQUIRED_ID"])
    {
        mask = RejectionReasonInvalidDoctypeRequiredIdMask;
    }
    else if ([string isEqualToString:@"NOT_RECENT_ENOUGH"])
    {
        mask = RejectionReasonNotRecentEnoughMask;
    }
    else if ([string isEqualToString:@"DOC_ILLEGIBLE"])
    {
        mask = RejectionReasonDocIllegibleMask;
    }
    else if ([string isEqualToString:@"INFO_MISMATCH"])
    {
        mask = RejectionReasonInfoMismatchMask;
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_WITH_PROOF"])
    {
        mask = RejectionReasonInfoMismatchWithProofMask;
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_ADDRESS"])
    {
        mask = RejectionReasonInfoMismatchAddressMask;
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_LOCATION"])
    {
        mask = RejectionReasonInfoMismatchLocationMask;
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE"])
    {
        mask = RejectionReasonInfoIncompleteMask;
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE_DATE"])
    {
        mask = RejectionReasonInfoIncompleteDateMask;
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE_ADDRESS"])
    {
        mask = RejectionReasonInfoIncompleteAddressMask;
    }
    else if ([string isEqualToString:@"OTHER"])
    {
        mask = RejectionReasonOtherMask;
    }
    else
    {
        mask = RejectionReasonOtherMask;
    }

    return mask;
}


+ (RejectionReasonMask)rejectionReasonsMaskForArray:(NSArray*)array
{
    RejectionReasonMask mask = 0;

    for (NSString* string in array)
    {
        mask |= [self rejectionReasonMaskForString:string];
    }

    return mask;
}


+ (NSArray*)rejectionReasonMessagesForMask:(RejectionReasonMask)mask
{
    NSMutableArray* messages = [NSMutableArray array];

    if (mask & RejectionReasonInvalidDoctypeMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document type not accepted",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeVirtualAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document type not accepted - Virtual Office address proofs not accepted",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeThirdPartyMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document type not accepted - Document must be issued by a third party",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeNoAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document type not accepted - Document does not provide address information",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeRequiredIdMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document type not accepted - Proof of ID required instead of proof of address",
                                                              @"...")];
    }

    if (mask & RejectionReasonNotRecentEnoughMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Not recent enough",
                                                              @"...")];
    }

    if (mask & RejectionReasonDocIllegibleMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document Illegible/Document incomplete (please submit full copy)",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Information does not match information in the web portal",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchWithProofMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Information does not match information in web portal - Company name/End user name differs in portal from information on proo",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Information does not match information in web portal - Address Information differs (street name, street number, etc.)",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchLocationMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Information does not match information in web portal - Address Information differs (city or postcode)",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoIncompleteMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Incomplete information",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoIncompleteDateMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Incomplete Information (date missing)",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoIncompleteAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Incomplete Information (address information missing)",
                                                              @"...")];
    }

    if (mask & RejectionReasonOtherMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Other (please contact us at regulations@numberbay.com",
                                                              @"...")];
    }

    return [messages copy];
}


+ (BOOL)isAvailableAddressStatusMask:(AddressStatusMask)mask
{
    return ((mask & AddressStatusNotVerifiedMask) > 0) || ((mask & AddressStatusVerifiedMask) > 0);
}

@end
