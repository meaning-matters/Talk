//
//  DestinationData.m
//  Talk
//
//  Created by Cornelis van der Bent on 27/03/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "DestinationData.h"
#import "NumberData.h"
#import "RecordingData.h"
#import "WebClient.h"
#import "Strings.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "DataManager.h"


@implementation DestinationData

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

        title   = NSLocalizedStringWithDefaultValue(@"Destinations DestinationInUseTitle", nil,
                                                    [NSBundle mainBundle], @"Destination Still Used",
                                                    @"Alert title telling that a number destination is used.\n"
                                                    @"[iOS alert title size].");
        message = NSLocalizedStringWithDefaultValue(@"Destinations DestinationInUseMessage", nil,
                                                    [NSBundle mainBundle],
                                                    @"This Destination is still used for %d %@. To delete, "
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
        [[WebClient sharedClient] deleteIvrForUuid:self.uuid reply:^(NSError* error)
        {
            if (error == nil)
            {
                [managedObjectContext deleteObject:self];
                completion ? completion(YES) : 0;
            }
            else if (error.code == WebStatusFailIvrInUse)
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"Destination InUseTitle", nil,
                                                            [NSBundle mainBundle], @"Destination Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Destination InUseMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Destination from our server failed: %@"
                                                            @"\n\nSynchronize with the server, and then choose another "
                                                            @"Destination for each number that uses this one.",
                                                            @"...\n"
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

                title   = NSLocalizedStringWithDefaultValue(@"Destination DeleteFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Destination Not Deleted",
                                                            @"Alert title telling that something could not be deleted.\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"Destination DeleteFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Deleting this Destination from our server failed: %@"
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


// Overrides a NSManagedObject setter.
- (void)setStatements:(NSString*)statements
{
    // Required for the override.
    [self willChangeValueForKey:@"statements"];
    [self setPrimitiveValue:statements forKey:@"statements"];

    [self updateDependenciesWithStatements:statements];

    // Required for the override.
    [self didChangeValueForKey:@"statements"];
}


- (void)updateDependenciesWithStatements:(NSString*)statements
{
    NSArray*     statementsArray = [Common mutableObjectWithJsonString:statements];
    NSString*    e164            = statementsArray[0][@"call"][@"e164"][0];

    if ([e164 length] == 0)
    {
        return;
    }

    NSPredicate* predicate       = [NSPredicate predicateWithFormat:@"e164 == %@", e164];
    NSArray*     phones          = [[DataManager sharedManager] fetchEntitiesWithName:@"Phone"
                                                                             sortKeys:nil
                                                                            predicate:predicate
                                                                 managedObjectContext:self.managedObjectContext];

    if (phones.count == 0)
    {
        return;
    }

    [self removePhones:self.phones];
    [self addPhonesObject:phones[0]];
}

@end
