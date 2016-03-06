//
//  RecordingData.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "RecordingData.h"
#import "DestinationData.h"
#import "WebClient.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "DataManager.h"


@implementation RecordingData

@dynamic uuid;
@dynamic name;
@dynamic audio;
@dynamic destinations;


- (NSString*)cantDeleteMessage
{
    return @"//#######";
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

        title = NSLocalizedStringWithDefaultValue(@"RecordingView CantDeleteTitle", nil, [NSBundle mainBundle],
                                                  @"Can't Delete Recording",
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
    [[WebClient sharedClient] deleteAudioForUuid:self.uuid reply:^(NSError *error)
    {
        if (error == nil)
        {
            [self.managedObjectContext deleteObject:self];
            completion ? completion(YES) : 0;

            return;
        }

        NSString* title;
        NSString* message;
        if (error.code == WebStatusFailAudioInUse)
        {
            title   = NSLocalizedStringWithDefaultValue(@"Recording InUseTitle", nil,
                                                        [NSBundle mainBundle], @"Recording Not Deleted",
                                                        @"Alert title telling that something could not be deleted.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Recording failed: %@\n\n"
                                                        @"Choose another Recording for each Destination that uses this one.",
                                                        @"Alert message telling ....\n"
                                                        @"[iOS alert message size]");
        }
        else if (error.code == NSURLErrorNotConnectedToInternet)
        {
            title   = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedInternetTitle", nil,
                                                        [NSBundle mainBundle], @"Recording Not Deleted",
                                                        @"Alert title telling that something could not be deleted.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Recording failed: %@\n\n"
                                                        @"Please try again later.",
                                                        @"....\n"
                                                        @"[iOS alert message size]");
        }
        else
        {
            title   = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedTitle", nil,
                                                        [NSBundle mainBundle], @"Recording Not Deleted",
                                                        @"Alert title telling that something could not be deleted.\n"
                                                        @"[iOS alert title size].");
            message = NSLocalizedStringWithDefaultValue(@"Phone DeleteFailedMessage", nil,
                                                        [NSBundle mainBundle],
                                                        @"Deleting this Recording failed: %@\n\n"
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
