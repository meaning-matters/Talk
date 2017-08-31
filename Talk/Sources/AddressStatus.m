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
    else if ([string isEqualToString:@"VERIFICATION_NOT_REQUIRED"])
    {
        mask = AddressStatusVerificationNotRequiredMask;
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
    else if ([string isEqualToString:@"NOT_VERIFIED"])
    {
        mask = AddressStatusNotVerifiedMask;
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
    else if ([string isEqualToString:@"INFO_MISMATCH_ADDRESS_NOT_IN_AREA"])      // NumberBay added.
    {
        mask = RejectionReasonInfoMismatchAddressNotInAreaMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_ADDRESS_NOT_PERSONAL"])   // NumberBay added.
    {
        mask = RejectionReasonInvalidDoctypeAddressNotPersonalMask;
    }
    else if ([string isEqualToString:@"INVALID_DOCTYPE_REQUIRED_ADDRESS"])       // NumberBay added.
    {
        mask = RejectionReasonInvalidDoctypeRequiredAddressMask;
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
                                                              @"Document type is not accepted",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeVirtualAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Virtual office address proof is not accepted",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeThirdPartyMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document must be issued by a third party",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeNoAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document does not provide address information",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeRequiredIdMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Proof of identity is required, instead of proof of address",
                                                              @"...")];
    }

    if (mask & RejectionReasonNotRecentEnoughMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document is not recent enough",
                                                              @"...")];
    }

    if (mask & RejectionReasonDocIllegibleMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document is illegible or incomplete",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Document does not match entered information",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchWithProofMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Name (of company) does not match",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Street information does not match",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchLocationMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"City or postcode don't match",
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
                                                              @"Date information is missing",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoIncompleteAddressMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Address information is missing",
                                                              @"...")];
    }

    if (mask & RejectionReasonOtherMask)
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Other issue. Contact us via Help > Chat With Us "
                                                              @"or Send Email",
                                                              @"...")];
    }

    if (mask & RejectionReasonInfoMismatchAddressNotInAreaMask)      // NumberBay added.
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Address does not match the Number's area code",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeAddressNotPersonalMask)  // NumberBay added.
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Proof of address is not personal and could be acquired "
                                                              @"by others",
                                                              @"...")];
    }

    if (mask & RejectionReasonInvalidDoctypeRequiredAddressMask)    // NumberBay added.
    {
        [messages addObject:NSLocalizedStringWithDefaultValue(@"AddressStatus ...", nil, [NSBundle mainBundle],
                                                              @"Proof of address is required, instead of proof of identity",
                                                              @"...")];
    }

    return [messages copy];
}


+ (NSString*)localizedStringForAddressStatusMask:(AddressStatusMask)mask
{
    switch (mask)
    {
        case AddressStatusUnknown:                     return NSLocalizedString(@"Unknown",                  @"");
        case AddressStatusStagedMask:                  return NSLocalizedString(@"Awaiting Verification",    @"");
        case AddressStatusNotVerifiedMask:             // Fall-through.
        case AddressStatusVerificationRequestedMask:   return NSLocalizedString(@"Verification In Progress", @"");
        case AddressStatusVerificationNotRequiredMask: // Fall-through.
        case AddressStatusVerifiedMask:                return NSLocalizedString(@"Verified",                 @"");
        case AddressStatusRejectedMask:                return NSLocalizedString(@"Rejected",                 @"");
        case AddressStatusDisabledMask:                return NSLocalizedString(@"Disabled",                 @"");
    }
}


+ (NSString*)localizedMessageForAddress:(AddressData*)address
{
    NSString* message;

    switch (address.addressStatus)
    {
        case AddressStatusUnknown:
        {
            message = NSLocalizedString(@"The verification status of this Address is unknown\n\nPlease check again later.",
                                        @"");
            break;
        }
        case AddressStatusStagedMask:
        {
            message = NSLocalizedString(@"We will soon start verifying your Address. %@\n\nYou can still make changes, "
                                        @"but only via Numbers > [Number] > Address > Edit.",
                                        @"");
            message = [NSString stringWithFormat:message, [Strings addressVerificationPhraseString]];

            break;
        }
        case AddressStatusNotVerifiedMask: // Fall-through.
        case AddressStatusVerificationRequestedMask:
        {
            message = NSLocalizedString(@"Your Address is in the process of being verified. %@\n\nYou can no longer make "
                                        @"changes.", @"");
            message = [NSString stringWithFormat:message, [Strings addressVerificationPhraseString]];

            break;
        }
        case AddressStatusVerificationNotRequiredMask:  // Fall-through.
        case AddressStatusVerifiedMask:
        {
            message = NSLocalizedString(@"Your Address has been successfully verified. Numbers that are purchased using "
                                        @"this Address will be immediately activated.", @"");
            break;
        }
        case AddressStatusRejectedMask:
        {
            message = NSLocalizedStringWithDefaultValue(@"Address:AddressLocal Verified", nil, [NSBundle mainBundle],
                                                        @"Your Address plus the proof image(s) have been "
                                                        @"checked, but something is not correct yet.\n\n"
                                                        @"Please add a new image or correct the fields and we'll check "
                                                        @"again; you can also create a new Address.",
                                                        @"...");
            break;
        }
        case AddressStatusDisabledMask:
        {
            message = NSLocalizedString(@"This Address has been disabled. Your Numbers that are using this Address have "
                                        @"probably been temporarily disconnected.\n\nIf we have not contacted you, "
                                        @"please get in touch via Help > Contact Us so we can resolve this issue as "
                                        @"soon as possible.",
                                        @"");
            break;
        }
    }

    return message;
}


+ (NSAttributedString*)localizedAttributedRejectionsForAddress:(AddressData*)address
{
    NSMutableString* rejections = [NSMutableString string];
    for (NSString* rejection in [self rejectionReasonMessagesForMask:address.rejectionReasons])
    {
        [rejections appendFormat:@"•\t%@.\n", rejection];
    }

    NSString*                string = [rejections substringToIndex:(rejections.length - 1)];

    NSMutableParagraphStyle* style  = [[NSMutableParagraphStyle alloc] init];
    style.headIndent = 29;

    return [[NSAttributedString alloc] initWithString:string attributes:@{NSParagraphStyleAttributeName : style}];
}


+ (BOOL)isAvailableAddressStatusMask:(AddressStatusMask)mask
{
    return ((mask & AddressStatusStagedMask)                  > 0) || // Not yet verified by NumberBay yet.
           ((mask & AddressStatusRejectedMask)                > 0) || // Rejected by NumberBay and still editable.
           ((mask & AddressStatusVerificationNotRequiredMask) > 0) || // Verified by NumberBay and not needing Voxbone check.
           ((mask & AddressStatusVerifiedMask)                > 0) || // Verified by both NumberBay and Voxbone.
           ((mask & AddressStatusNotVerifiedMask)             > 0);   // Voxbone state meaning meaning that no verification is needed.
}


+ (BOOL)isVerifiedAddressStatusMask:(AddressStatusMask)mask
{
    return ((mask & AddressStatusVerificationNotRequiredMask) > 0) || // Verified by NumberBay and not needing Voxbone check.
           ((mask & AddressStatusNotVerifiedMask)             > 0) || // Voxbone state meaning meaning that no verification is needed.
           ((mask & AddressStatusVerifiedMask)                > 0);   // Verified by both NumberBay and Voxbone.
}

@end
