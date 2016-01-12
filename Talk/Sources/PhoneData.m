//
//  PhoneData.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "PhoneData.h"
#import "WebClient.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "DataManager.h"


@implementation PhoneData

@dynamic destinations;


- (NSString*)cantDeleteMessage
{
    NSString*       message;
    NSArray*        numbersArray;
    CallableData*   callable  = self;
    NSMutableArray* useArray  = [NSMutableArray array];

    NSPredicate*    predicate = [NSPredicate predicateWithFormat:@"ANY destination.phones == %@", self];
    numbersArray = [[DataManager sharedManager] fetchEntitiesWithName:@"Number"
                                                             sortKeys:nil
                                                            predicate:predicate
                                                 managedObjectContext:nil];

    if ([self.e164 isEqualToString:[Settings sharedSettings].callbackE164])
    {
        [useArray addObject:NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberFooter", nil,
                                                              [NSBundle mainBundle],
                                                              @"for Callback",
                                                              @"Table footer that ....\n"
                                                              @"[1 line larger font].")];
    }

    if ([self.e164 isEqualToString:[Settings sharedSettings].callerIdE164])
    {
        [useArray addObject:NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberFooter", nil,
                                                              [NSBundle mainBundle],
                                                              @"as default Caller ID",
                                                              @"Table footer that ....\n"
                                                              @"[1 line larger font].")];
    }

    if (numbersArray.count > 0)
    {
        [useArray addObject:NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberFooter", nil,
                                                              [NSBundle mainBundle],
                                                              @"in one or more Destinations",
                                                              @"Table footer that ....\n"
                                                              @"[1 line larger font].")];
    }

    if (callable.callerIds.count == 1)
    {
        [useArray addObject:NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberFooter", nil,
                                                              [NSBundle mainBundle],
                                                              @"as Caller ID for a contact",
                                                              @"Table footer that ....\n"
                                                              @"[1 line larger font].")];
    }

    if (callable.callerIds.count > 1)
    {
        [useArray addObject:NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberFooter", nil,
                                                              [NSBundle mainBundle],
                                                              @"as Caller ID for contacts",
                                                              @"Table footer that ....\n"
                                                              @"[1 line larger font].")];
    }

    if (useArray.count > 0)
    {
        message = NSLocalizedStringWithDefaultValue(@"PhoneView CanNotDeleteNumberMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Phone can't be deleted because it's used ",
                                                    @"Table footer that ....\n"
                                                    @"[1 line larger font].");

        for (int i = 0; i < useArray.count; i++)
        {
            if (useArray.count == 1)
            {
                message = [message stringByAppendingFormat:@"%@.", useArray[i]];
            }
            else if (useArray.count == 2)
            {
                if (i == 0)
                {
                    message = [message stringByAppendingFormat:@"%@ and ", useArray[i]];
                }
                else
                {
                    message = [message stringByAppendingFormat:@"%@.", useArray[i]];
                }
            }
            else
            {
                if (i == (useArray.count - 2))
                {
                    message = [message stringByAppendingFormat:@"%@, and ", useArray[i]];
                }
                else if (i == (useArray.count - 1))
                {
                    message = [message stringByAppendingFormat:@"%@.", useArray[i]];
                }
                else
                {
                    message = [message stringByAppendingFormat:@"%@, ", useArray[i]];
                }
            }
        }
    }
    else
    {
        message = nil;
    }

    return message;
}


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion
{
    if (self.destinations.count > 0)
    {
        NSString* title;
        NSString* message;
        NSString* destinationString;

        title   = NSLocalizedStringWithDefaultValue(@"Phones PhoneInUserTitle", nil,
                                                    [NSBundle mainBundle], @"Phone Still Used",
                                                    @"Alert title telling that a phone is used.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Phone PhoneInUseMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Phone is still used for %d %@. To delete, "
                                                    @"make sure it's no longer used.",
                                                    @"Alert message telling that number destination is used.\n"
                                                    @"[iOS alert message size - parameters: count, number(s)]");
        destinationString = (self.destinations.count == 1) ? [Strings destinationString] : [Strings destinationsString];
        message = [NSString stringWithFormat:message, self.destinations.count, destinationString];
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
        [[WebClient sharedClient] deleteVerifiedE164:self.e164 reply:^(NSError* error)
        {
            if (error == nil)
            {
                [managedObjectContext deleteObject:self];
                completion ? completion(YES) : 0;

                return;
            }

            NSString* title;
            NSString* message;
            if (error.code == WebStatusFailVerfiedNumberInUse)
            {
                title   = NSLocalizedStringWithDefaultValue(@"Phone InUseTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Phone failed: %@\n\n"
                                                            @"Choose another Destination for each number that uses this one.",
                                                            @"Alert message telling that an online service is not available.\n"
                                                            @"[iOS alert message size]");
            }
            else if (error.code == NSURLErrorNotConnectedToInternet)
            {
                title   = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedInternetTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Phone from your account failed: %@\n\n"
                                                            @"Please try again later.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
            }
            else
            {
                title   = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Phone from your account failed: %@\n\n"
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

@end
