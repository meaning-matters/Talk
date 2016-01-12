//
//  AddressData.m
//  Talk
//
//  Created by Cornelis van der Bent on 18/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressData.h"
#import "NumberData.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "WebClient.h"


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


- (void)deleteWithCompletion:(void (^)(BOOL succeeded))completion
{
    if (self.numbers.count > 0)
    {
        NSString* title;
        NSString* message;
        NSString* numberString;
        
        title   = NSLocalizedStringWithDefaultValue(@"Addresses AddressInUserTitle", nil,
                                                    [NSBundle mainBundle], @"Address Still Used",
                                                    @"Alert title telling that a Address is used.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Address AddressInUseMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Address is still used for %d %@. To delete, "
                                                    @"make sure it's no longer used.",
                                                    @"Alert message telling that number destination is used.\n"
                                                    @"[iOS alert message size - parameters: count, number(s)]");
        numberString = (self.numbers.count == 1) ? [Strings numberString] : [Strings numbersString];
        message = [NSString stringWithFormat:message, self.numbers.count, numberString];
        [BlockAlertView showAlertViewWithTitle:title
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
         {
             completion ? completion(NO) : 0;
         }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:nil];
    }
    else
    {
        [[WebClient sharedClient] deleteAddressWithId:self.addressId reply:^(NSError *error)
        {
            if (error == nil || error.code == WebStatusFailAddressUnknown)
            {
                [self.managedObjectContext deleteObject:self];
                completion ? completion(YES) : 0;
                
                return;
            }
            
            NSString* title;
            NSString* message;
            if (error.code == WebStatusFailAddressInUse)
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address InUseTitle", nil,
                                                            [NSBundle mainBundle], @"Address Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address failed: %@\n\n"
                                                            @"This Address can only be deleted when the Number(s) that "
                                                            @"reference it have expired and are no longer yours.",
                                                            @"[iOS alert message size]");
            }
            else if (error.code == NSURLErrorNotConnectedToInternet)
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedInternetTitle", nil,
                                                            [NSBundle mainBundle], @"Address Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address from your account failed: %@\n\n"
                                                            @"Please try again later.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
            else
            {
                title   = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Address Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address from your account failed: %@\n\n"
                                                            @"Synchronize with the server, and try again.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
            
            message = [NSString stringWithFormat:message, error.localizedDescription];
            [BlockAlertView showAlertViewWithTitle:title
                                           message:message
                                        completion:^(BOOL cancelled, NSInteger buttonIndex)
            {
                completion ? completion(NO) : 0;
            }
                                 cancelButtonTitle:[Strings cancelString]
                                 otherButtonTitles:nil];
        }];
    }
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
