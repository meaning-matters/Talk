//
//  PhoneData.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "PhoneData.h"
#import "WebClient.h"
#import "Strings.h"
#import "BlockAlertView.h"


@implementation PhoneData

@dynamic name;
@dynamic e164;
@dynamic forwardings;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion
{
    if (self.forwardings.count > 0)
    {
        NSString* title;
        NSString* message;
        NSString* phoneString;

        title   = NSLocalizedStringWithDefaultValue(@"Phones PhoneInUserTitle", nil,
                                                    [NSBundle mainBundle], @"Phone Still Used",
                                                    @"Alert title telling that a phone is used.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Phone PhoneInUseMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Phone is still used for %d %@.  To delete, "
                                                    @"make sure it's no longer used.",
                                                    @"Alert message telling that number forwarding is used.\n"
                                                    @"[iOS alert message size - parameters: count, number(s)]");
        phoneString = (self.forwardings.count == 1) ? [Strings phoneString] : [Strings phonesString];
        message = [NSString stringWithFormat:message, self.forwardings.count, phoneString];
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
            }
            else if (error.code == WebClientStatusFailVerfiedNumberInUse)
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"Phone InUseTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Forwarding InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Phone failed: %@"
                                                            @"\n\nChoose another Forwarding for each number that uses this one.",
                                                            @"Alert message telling that an online service is not available.\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, error.localizedDescription];
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
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Phone Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Phone from our server failed: %@"
                                                            @"\n\nSynchronize with the server, and then choose another "
                                                            @"Forwarding for each number that uses this one.",
                                                            @"....\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, error.localizedDescription];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                 {
                     completion ? completion(NO) : 0;
                 }
                                     cancelButtonTitle:[Strings cancelString]
                                     otherButtonTitles:nil];
            }
        }];
    }
}

@end
