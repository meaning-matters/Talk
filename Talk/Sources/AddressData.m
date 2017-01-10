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
@dynamic areaCode;
@dynamic hasAddressProof;
@dynamic hasIdentityProof;
@dynamic addressProof;
@dynamic identityProof;
@dynamic idType;
@dynamic idNumber;
@dynamic nationality;
@dynamic fiscalIdCode;
@dynamic streetCode;
@dynamic municipalityCode;
@dynamic addressStatus;
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
                [self.managedObjectContext deleteObject:self]; // This notifies AddressUpdatesHandler.
                completion ? completion(YES) : 0;
                
                return;
            }
            
            NSString* title = NSLocalizedStringWithDefaultValue(@"Address InUseTitle", nil,
                                                                [NSBundle mainBundle], @"Address Not Deleted",
                                                                @"Alert title telling that something could not be deleted.\n"
                                                                @"[iOS alert title size].");
            NSString* message;
            if (error.code == WebStatusFailAddressInUse)
            {
                message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address failed: %@\n\n"
                                                            @"This Address can only be deleted when the Number(s) that "
                                                            @"reference it have expired and are no longer yours.",
                                                            @"[iOS alert message size]");
            }
            else if (error.code == WebStatusFailNoInternet)
            {
                message = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address failed: %@\n\n"
                                                            @"Please try again later.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
            else if (error.code == WebStatusFailSecureInternet  ||
                     error.code == WebStatusFailProblemInternet ||
                     error.code == WebStatusFailInternetLogin)
            {
                message = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address: %@\n\n"
                                                            @"Please check the Internet connection.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
            else
            {
                message = NSLocalizedStringWithDefaultValue(@"Address DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Address failed: %@\n\n"
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


- (void)loadProofImagesWithCompletion:(void (^)(BOOL succeeded))completion
{
    [[WebClient sharedClient] retrieveProofImagesForAddressId:self.addressId
                                                        reply:^(NSError* error,
                                                                NSData*  addressProof,
                                                                NSData*  identityProof)
    {
        if (error == nil)
        {
            self.addressProof  = addressProof;
            self.identityProof = identityProof;
            completion ? completion(YES) : 0;
        }
        else
        {
            completion ? completion(NO) : 0;
        }
    }];
}


- (void)cancelLoadProofImages
{
    [[WebClient sharedClient] cancelAllRetrieveProofImagesForAddressId:self.addressId];
}

@end
