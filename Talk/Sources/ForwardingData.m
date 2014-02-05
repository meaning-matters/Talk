//
//  ForwardingData.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingData.h"
#import "NumberData.h"
#import "RecordingData.h"
#import "WebClient.h"
#import "Strings.h"
#import "BlockAlertView.h"


@implementation ForwardingData

@dynamic uuid;
@dynamic name;
@dynamic statements;
@dynamic numbers;
@dynamic recordings;
@dynamic phones;


- (void)deleteFromManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                            completion:(void (^)(BOOL succeeded))completion
{
    if (self.numbers.count > 0)
    {
        NSString* title;
        NSString* message;
        NSString* numberString;

        title   = NSLocalizedStringWithDefaultValue(@"Forwardings ForwardingInUserTitle", nil,
                                                    [NSBundle mainBundle], @"Forwarding Still Used",
                                                    @"Alert title telling that a number forwarding is used.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Forwardings ForwardingInUserMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Forwarding is still used for %d %@.  To delete, "
                                                    @"make sure it's no longer used.",
                                                    @"Alert message telling that number forwarding is used.\n"
                                                    @"[iOS alert message size - parameters: count, number(s)]");
        numberString = (self.numbers.count == 1) ? [Strings numberString] : [Strings numberString];
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
        [[WebClient sharedClient] deleteIvrForUuid:self.uuid reply:^(NSError* error)
        {
            if (error == nil)
            {
                [managedObjectContext deleteObject:self];
                completion ? completion(YES) : 0;
            }
            else if (error.code == WebClientStatusFailIvrInUse)
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"Forwarding InUseTitle", nil,
                                                            [NSBundle mainBundle], @"Forwarding Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Forwarding InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Forwarding failed: %@"
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

                title   = NSLocalizedStringWithDefaultValue(@"Forwarding DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Forwarding Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Forwarding DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Forwarding from our server failed: %@"
                                                            @"\n\nPlease try again later.",
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
        }];
    }
}

@end
