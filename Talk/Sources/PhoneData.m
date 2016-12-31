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

        title = NSLocalizedStringWithDefaultValue(@"PhoneView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                  @"Can't Delete Phone",
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
    [[WebClient sharedClient] deletePhoneWithUuid:self.uuid reply:^(NSError* error)
    {
        if (error == nil)
        {
            [self.managedObjectContext deleteObject:self];
            completion ? completion(YES) : 0;

            return;
        }

        NSString* title = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
        NSString* message;
        if (error.code == WebStatusFailPhoneInUse)
        {
            message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Phone failed: %@\n\n"
                                                        @"Choose another Phone for each Destination that uses this one.",
                                                        @"Alert message telling ....\n"
                                                        @"[iOS alert message size]");
        }
        else if (error.code == WebStatusFailNoInternet)
        {
            message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Phone failed: %@\n\n"
                                                        @"Please try again later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
        }
        else if (error.code == WebStatusFailSecureInternet  ||
                 error.code == WebStatusFailProblemInternet ||
                 error.code == WebStatusFailInternetLogin)
        {
            message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Phone failed: %@\n\n"
                                                        @"Please check the Internet connection.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
        }
        else
        {
            message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Phone failed: %@\n\n"
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

@end
