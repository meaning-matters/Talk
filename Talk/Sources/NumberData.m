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
@dynamic isoCountryCode;
@dynamic purchaseDate;
@dynamic expiryDate;
@dynamic notifiedExpiryDays;
@dynamic autoRenew;

@dynamic stateName;
@dynamic stateCode;
@dynamic proofTypes;

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


- (int16_t)expiryDays
{
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

    return INT16_MAX;    // Not expired soon.
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

@end
