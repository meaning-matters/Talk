//
//  MessageUpdatesHandler.m
//  Talk
//
//  Created by Jeroen Kooiker on 26/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessageUpdatesHandler.h"
#import "Settings.h"
#import "MessageData.h"
#import "DataManager.h"

NSString* const MessageUpdatesNotification = @"MessageUpdatesNotification";


@implementation MessageUpdatesHandler

+ (MessageUpdatesHandler*)sharedHandler
{
    static MessageUpdatesHandler* sharedInstance;
    static dispatch_once_t        onceToken;
    
    dispatch_once(&onceToken, ^
    {
        sharedInstance = [[MessageUpdatesHandler alloc] init];
    });
    
    return sharedInstance;
}


- (void)processChangedMessage:(MessageData*)message
{
    NSMutableDictionary* messagesUpdates = [[Settings sharedSettings].messageUpdates mutableCopy];
    messagesUpdates[message.uuid]        = message.uuid;
    [self saveMessageUpdates:messagesUpdates];
}


- (void)saveMessageUpdates:(NSDictionary*)messageUpdates
{
    [Settings sharedSettings].messageUpdates = messageUpdates;
    [[NSNotificationCenter defaultCenter] postNotificationName:MessageUpdatesNotification
                                                        object:self
                                                      userInfo:messageUpdates];
}


#pragma Public


- (NSUInteger)badgeCountForNumberE164:(NSString*)numberE164
{
    NSUInteger badgeCount = 0;
    NSArray*   messages   = [[DataManager sharedManager] fetchEntitiesWithName:@"Message"];
    
    // If asked for the badgeCount for a specific number.
    if (numberE164 != nil)
    {
        NSPredicate* predicate = [NSPredicate predicateWithFormat:@"numberE164 = %@", numberE164];
        messages = [messages filteredArrayUsingPredicate:predicate];
    }
    
    for (MessageData* message in messages)
    {
        NSDictionary* messageUpdate = [[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid];
        if (messageUpdate != nil)
        {
            badgeCount++;
        }
    }
    
    return badgeCount;
}


- (NSUInteger)badgeCount
{
    return [self badgeCountForNumberE164:nil];
}


- (NSDictionary *)messageUpdateWithUuid:(NSString*)uuid
{
    return [Settings sharedSettings].messageUpdates[uuid];
}


- (void)removeMessageUpdateWithUuid:(NSString*)uuid
{
    NSMutableDictionary* messageUpdates = [[Settings sharedSettings].messageUpdates mutableCopy];
    
    messageUpdates[uuid] = nil;
    
    [self saveMessageUpdates:messageUpdates];
}

@end
