//
//  AddressStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "AddressStatus.h"

@implementation AddressStatus

+ (NSString*)stringForAddressStatusMask:(AddressStatusMask)mask
{
    switch (mask)
    {
        case AddressStatusNotVerifiedMask:
        {
            return @"NOT_VERIFIED";
        }
        case AddressStatusVerificationRequestedMask:
        {
            return @"VERIFICATION_REQUESTED";
        }
        case AddressStatusVerifiedMask:
        {
            return @"VERIFIED";
        }
        case AddressStatusRejectedMask:
        {
            return @"REJECTED";
        }
        case AddressStatusDisabledMask:
        {
            return @"DISABLED";
        }
        default:
        {
            NBLog(@"Invalid AddressStatusMask.");
            return @"";
        }
    }
}


+ (AddressStatusMask)addressStatusMaskForString:(NSString*)string
{
    AddressStatusMask mask;

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


+ (NSString*)rejectionReasonMessageForString:(NSString*)string
{
    NSString* message;

    if ([string isEqualToString:@"INVALID_DOCTYPE"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document type not accepted",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_VIRTUAL_ADDRESS"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document type not accepted - Virtual Office address proofs not accepted",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_THIRD_PARTY"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document type not accepted - Document must be issued by a third party",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_NO_ADDRESS"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document type not accepted - Document does not provide address information",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_REQUIRED_ID"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document type not accepted - Proof of ID required instead of proof of address",
                                                    @"...");
    }
    else if ([string isEqualToString:@"NOT_RECENT_ENOUGH"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Not recent enough",
                                                    @"...");
    }
    else if ([string isEqualToString:@"DOC_ILLEGIBLE"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Document Illegible/Document incomplete (please submit full copy)",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_MISMATCH"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Information does not match information in the web portal",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_WITH_PROOF"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Information does not match information in web portal - Company name/End user name differs in portal from information on proo",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_ADDRESS"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Information does not match information in web portal - Address Information differs (street name, street number, etc.)",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_MISMATCH_LOCATION"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Information does not match information in web portal - Address Information differs (city or postcode)",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Incomplete information",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE_DATE"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Incomplete Information (date missing)",
                                                    @"...");
    }
    else if ([string isEqualToString:@"INFO_INCOMPLETE_ADDRESS"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Incomplete Information (address information missing)",
                                                    @"...");
    }
    else if ([string isEqualToString:@"OTHER"])
    {
        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Other (please contact us at regulations@numberbay.com",
                                                    @"...");
    }
    else
    {
        string = [[string componentsSeparatedByString:@"_"] componentsJoinedByString:@" "];
        string = [string capitalizedString];
        string = [string stringByReplacingOccurrencesOfString:@" " withString:@""];

        message = NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                    @"Some address information is not sufficient/correct: %@",
                                                    @"...");
        message = [NSString stringWithFormat:message, string];
    }

    return message;
}

@end
