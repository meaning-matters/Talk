//
//  MessageData.m
//  Talk
//
//  Created by Jeroen Kooiker on 2/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessageData.h"
#import "WebClient.h"

@implementation MessageData

@dynamic cost;
@dynamic direction;
@dynamic externE164;
@dynamic numberE164;
@dynamic text;
@dynamic timestamp;
@dynamic uuid;
@dynamic contactId;
@dynamic status;


- (void)createForNumberE164:(NSString*)numberE164
                 externE164:(NSString*)externE164
                       text:(NSString*)text
                   datetime:(NSDate*)datetime
                 completion:(void (^)(NSError* error))completion
{
    self.numberE164 = numberE164;
    self.externE164 = externE164;
    self.text       = text;
    self.timestamp  = datetime;
    self.direction  = MessageDirectionOutbound;
    
    [[WebClient sharedClient] sendMessage:self
                                    reply:^(NSError* error, NSString* uuid)
    {
        if (error == nil)
        {
            self.uuid = uuid;
        }
        
        completion ? completion(error) : 0;
    }];
}

@end
