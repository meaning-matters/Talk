//
//  AddressStatus.m
//  Talk
//
//  Created by Cornelis van der Bent on 19/03/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "AddressStatus.h"
#import "Strings.h"

@implementation AddressStatus

+ (AddressStatusMask)addressStatusMaskForString:(NSString*)string
{
    AddressStatusMask mask;

    if ([string isEqualToString:@"STAGED"])
    {
        mask = AddressStatusStagedMask;
    }
    else if ([string isEqualToString:@"NOT_VERIFIED"])
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


+ (NSString*)localizedStringForAddressStatusMask:(AddressStatusMask)mask
{
    switch (mask)
    {
        case AddressStatusUnknown:                   return NSLocalizedString(@"Unknown",                  @"");
        case AddressStatusStagedMask:                return NSLocalizedString(@"Awaiting Verification",    @"");
        case AddressStatusVerificationRequestedMask: return NSLocalizedString(@"Verification In Progress", @"");
        case AddressStatusNotVerifiedMask:
        case AddressStatusVerifiedMask:              return NSLocalizedString(@"Verified",                 @"");
        case AddressStatusRejectedMask:              return NSLocalizedString(@"Rejected",                 @"");
        case AddressStatusDisabledMask:              return NSLocalizedString(@"Disabled",                 @"");
    }
}


+ (NSString*)localizedMessageForAddressStatusMask:(AddressStatusMask)mask
{
    switch (mask)
    {
        case AddressStatusUnknown:
        {
            return NSLocalizedString(@"The verification status of this Address is unknown\n\nPlease check again later.",
                                     @"");
        }
        case AddressStatusStagedMask:
        {
            NSString* message;
            message = NSLocalizedString(@"We will soon start verifying your Address. You can still make changes.\n\n%@",
                                        @"");
            return [NSString stringWithFormat:message, [Strings addressVerificationPhraseString]];
        }
        case AddressStatusVerificationRequestedMask:
        {
            NSString* message;
            message = NSLocalizedString(@"Your Address is in the process of being verified. You can no longer make "
                                        @"changes.\n\n%@", @"");
            return [NSString stringWithFormat:message, [Strings addressVerificationPhraseString]];
        }
        case AddressStatusNotVerifiedMask:
        case AddressStatusVerifiedMask:
        {
            return NSLocalizedString(@"Your Address has been successfully verified. Numbers that are purchased using "
                                     @"this Address will be immediately activated.", @"");
        }
        case AddressStatusRejectedMask:
        {
            return NSLocalizedString(@"Verification of your Address was not successful.", @"");
        }
        case AddressStatusDisabledMask:
        {
            return NSLocalizedString(@"This Address has been disabled. Your Numbers that were using this Address have "
                                     @"probably been disconnected.\n\nIf we have not contacted you, please get in touch "
                                     @"via Help > Contact Us so we can resolve this issue as soon as possible.",
                                     @"");
        }
    }
}


+ (BOOL)isAvailableAddressStatusMask:(AddressStatusMask)mask
{
    return ((mask & AddressStatusStagedMask)      > 0) ||   // Not yet verified by NumberBay yet.
           ((mask & AddressStatusNotVerifiedMask) > 0) ||   // Verified by NumberBay and not needing Voxbone check.
           ((mask & AddressStatusVerifiedMask)    > 0);     // Verified by both NumberBay and Voxbone.
}

@end
