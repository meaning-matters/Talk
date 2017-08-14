//
//  NumberData.m
//  Talk
//
//  Created by Cornelis van der Bent on 25/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberData.h"
#import "WebClient.h"
#import "NSString+Common.h"
#import "BlockAlertView.h"
#import "Strings.h"
#import "AppDelegate.h"

@implementation NumberData

@dynamic numberType;
@dynamic addressType;
@dynamic areaCode;
@dynamic areaName;
@dynamic areaId;
@dynamic isoCountryCode;
@dynamic purchaseDate;
@dynamic expiryDate;
@dynamic notifiedExpiryDays;
@dynamic autoRenew;

@dynamic stateName;
@dynamic stateCode;

@dynamic fixedRate;
@dynamic fixedSetup;
@dynamic mobileRate;
@dynamic mobileSetup;
@dynamic payphoneRate;
@dynamic payphoneSetup;

@dynamic monthFee;
@dynamic renewFee;

@dynamic destination;
@dynamic address;


- (BOOL)isPending
{
    return (self.e164 == nil || self.purchaseDate == nil || self.expiryDate == nil);
}


- (int16_t)expiryDays
{
    if (self.isPending)
    {
        return INT16_MAX;   // No expiryDate known yet.
    }

    NSCalendar*       calendar   = [NSCalendar currentCalendar];
    NSDateComponents* components = [NSDateComponents new];  // Below adding to `day` also works around New Year.
    NSDate*           daysDate;

    components.day = 0;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 0;   // Expired.
    }

    components.day = 1;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 1;
    }

    components.day = 3;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 3;
    }

    components.day = 7;
    daysDate       = [calendar dateByAddingComponents:components toDate:[NSDate date] options:0];
    if ([self.expiryDate compare:daysDate] == NSOrderedAscending)
    {
        return 7;
    }

    return INT16_MAX;   // Not expired soon.
}


- (BOOL)isExpiryCritical
{
    return ([self expiryDays] <= 7);
}


- (BOOL)hasExpired
{
    return ([self expiryDays] == 0);
}


- (NSString*)expiryStringForHours:(NSInteger)expiryHours
{
    NSString* when;

    if (expiryHours >= 2 * 24)
    {
        when = [NSString stringWithFormat:NSLocalizedString(@"in %d days", @""), expiryHours / 24];
    }
    else if (expiryHours >= 24)
    {
        when = [NSString stringWithFormat:NSLocalizedString(@"in 1 day", @"")];
    }
    else if (expiryHours >= 2)
    {
        when = [NSString stringWithFormat:NSLocalizedString(@"in %d hours", @""), expiryHours];
    }
    else if (expiryHours >= 1)
    {
        when = [NSString stringWithFormat:NSLocalizedString(@"in 1 hour", @"")];
    }
    else
    {
        when = [NSString stringWithFormat:NSLocalizedString(@"within minutes", @"")];
    }

    return when;
}


- (NSString*)purchaseDateString
{
    return [[self dateFormatter] stringFromDate:self.purchaseDate];
}


- (NSString*)expiryDateString
{
    NSTimeInterval expiryInterval = [self.expiryDate timeIntervalSinceDate:[NSDate date]];
    NSInteger      expiryHours    = floor(expiryInterval / (60 * 60));

    if (expiryInterval <= 0)
    {
        return NSLocalizedString(@"Expired", @"");
    }
    else if (expiryHours > 7 * 24)
    {
        return [[self dateFormatter] stringFromDate:self.expiryDate];
    }
    else
    {
        return [[self expiryStringForHours:expiryHours] capitalizedFirstLetter];
    }
}


- (void)showExpiryAlertWithCompletion:(void (^)(void))completion
{
    NSTimeInterval expiryInterval = [self.expiryDate timeIntervalSinceDate:[NSDate date]];

    if (expiryInterval > 0)
    {
        NSInteger expiryHours = floor(expiryInterval / (60 * 60));

        [BlockAlertView showAlertViewWithTitle:[Strings extendNumberAlertTitleString]
                                       message:[self alertTextForExpiryHours:expiryHours]
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            completion ? completion() : nil;
            if (buttonIndex == 1)
            {
                [[AppDelegate appDelegate] showNumber:self];
            }
        }
                             cancelButtonTitle:[Strings cancelString]
                             otherButtonTitles:[Strings extendString], nil];
    }
    else
    {
        NSString* message = NSLocalizedString(@"Your Number \"%@\" has expired and can't be extended any longer. "
                                              @"People calling will hear %@.\n\nWhere appropriate, please inform "
                                              @"those that used this Number to reach you.", @"");
        message = [NSString stringWithFormat:message, self.name, [Strings numberDisconnectedToneOrMessageString]];
        [BlockAlertView showAlertViewWithTitle:NSLocalizedString(@"Number Has Expired", @"")
                                       message:message
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            completion ? completion() : nil;
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


// Make sure that `expiryHours` is positive!
- (NSString*)alertTextForExpiryHours:(NSInteger)expiryHours
{
    NSString* format = NSLocalizedString(@"Your Number \"%@\" will expire %@. Extend and let people reach you.", @"");
    NSString* when   = [self expiryStringForHours:expiryHours];

    return [NSString stringWithFormat:format, self.name, when];
}


#pragma mark - Helper

- (NSDateFormatter*)dateFormatter
{
    NSString*        dateFormat    = [NSDateFormatter dateFormatFromTemplate:@"E MMM d yyyy"
                                                                     options:0
                                                                      locale:[NSLocale currentLocale]];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:dateFormat];
    [dateFormatter setLocale:[NSLocale currentLocale]];

    return dateFormatter;
}


#pragma mark - Deletion

- (NSString*)cantDeleteMessage
{
    NSString* message = NSLocalizedString(@"This Number can't be deleted because %@ ", @"");
    NSString* reason;

    if (self.isPending)
    {
        return nil;
    }

    switch (self.address.addressStatus)
    {
        case AddressStatusUnknown:
        {
            reason = NSLocalizedString(@"the status of its Address is unknow. Please try again later.", @"");
            break;
        }
        case AddressStatusVerificationRequestedMask:   // Fallthrough.
        case AddressStatusStagedMask:
        {
            reason = NSLocalizedString(@"its Address is waiting to be verified by us.", @"");
            break;
        }
        case AddressStatusNotVerifiedMask:             // Fallthrough.
        case AddressStatusVerificationNotRequiredMask: // Fallthrough.
        case AddressStatusVerifiedMask:
        {
            reason = NSLocalizedString(@"it's not pending; only pending Number purchases can be cancelled.\n\n"
                                       @"(To stop receiving calls, go to Numbers > [Number] > Destination, "
                                       @"and tap the delete button there. This will disconnect the Number.)", @"");
            break;
        }
        case AddressStatusDisabledMask:
        {
            reason = NSLocalizedString(@"it's not pending; only pending Number purchases can be cancelled.\n\n"
                                       @"(Please be aware that its Address is disabled. Assign a valid Address to "
                                       @"receive calls on this Number!)", @"");
                                       break;
        }
        case AddressStatusRejectedMask:
        {
            return nil;
        }
    }

    return [NSString stringWithFormat:message, reason];
}


- (void)deleteWithCompletion:(void (^)(BOOL succeeded))completion
{
    NSString* cantDeleteMessage = [self cantDeleteMessage];

    if (cantDeleteMessage == nil)
    {
        [self performDeleteWithCompletion:completion];
    }
    else
    {
        NSString* title;

        title = NSLocalizedStringWithDefaultValue(@"NumberView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                  @"Can't Delete Number",
                                                  @"...\n"
                                                  @"[1/3 line small font].");

        [BlockAlertView showAlertViewWithTitle:title
                                       message:cantDeleteMessage
                                    completion:^(BOOL cancelled, NSInteger buttonIndex)
        {
            completion ? completion(NO) : 0;
        }
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }
}


- (void)performDeleteWithCompletion:(void (^)(BOOL succeeded))completion
{
    [[WebClient sharedClient] deleteNumberWithUuid:self.uuid reply:^(NSError* error)
    {
        if (error == nil)
        {
             [self.managedObjectContext deleteObject:self];
             completion ? completion(YES) : 0;

             return;
        }

        NSString* title = NSLocalizedStringWithDefaultValue(@"Number DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Number Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
        NSString* message;
        if (error.code == WebStatusFailAddressNotRejected ||
            error.code == WebStatusFailNumberCancelled    ||
            error.code == WebStatusFailNumberPurchased)
        {
            message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Number failed: %@\n\n"
                                                        @"Please drag down the list of Numbers to refresh.",
                                                        @"Alert message telling ....\n"
                                                        @"[iOS alert message size]");
        }
        else if (error.code == WebStatusFailNoInternet)
        {
            message = NSLocalizedStringWithDefaultValue(@"Number DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Number failed: %@\n\n"
                                                        @"Please try again later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
        }
        else if (error.code == WebStatusFailSecureInternet  ||
                 error.code == WebStatusFailProblemInternet ||
                 error.code == WebStatusFailInternetLogin   ||
                 error.code == WebStatusFailRoamingOff)
        {
            message = NSLocalizedStringWithDefaultValue(@"Number DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Number failed: %@\n\n"
                                                        @"Please check the Internet connection.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
        }
        else
        {
            message = NSLocalizedStringWithDefaultValue(@"Number DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Number failed: %@\n\n"
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
                             cancelButtonTitle:[Strings closeString]
                             otherButtonTitles:nil];
    }];
}

@end
