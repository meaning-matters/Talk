//
//  MessageUpdatesHandler.h
//  Talk
//
//  Created by Jeroen Kooiker on 26/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MessageData;

extern NSString* const MessageUpdatesNotification;


@interface MessageUpdatesHandler : NSObject

+ (MessageUpdatesHandler*)sharedHandler;

- (void)processChangedMessage:(MessageData*)message;

- (NSUInteger)badgeCountForNumberE164:(NSString*)numberE164;

- (NSUInteger)badgeCount;

- (NSDictionary*)messageUpdateWithUuid:(NSString*)uuid;

- (void)removeMessageUpdateWithUuid:(NSString*)uuid;

@end
