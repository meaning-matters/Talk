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
    messagesUpdates[message.uuid]        = @"new message";
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

- (NSUInteger)badgeCount
{
    // @TODO: Rebuild this function so only the updated Conversations (instead of Messages) are counted.
    // Should use the same logic as ConversationsViewController to determine this.
    NSUInteger badgeCount = 0;
    NSArray*   messages = [[DataManager sharedManager] fetchEntitiesWithName:@"Message"];
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
