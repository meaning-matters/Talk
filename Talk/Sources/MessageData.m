//
//  MessageData.m
//  Talk
//
//  Created by Jeroen Kooiker on 2/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessageData.h"

@implementation MessageData

@dynamic billed;
@dynamic direction;
@dynamic externE164;
@dynamic numberE164;
@dynamic text;
@dynamic timestamp;
@dynamic uuid;
@dynamic contactId;


- (MessageDirectionEnum)directionRaw
{
    return (MessageDirectionEnum)[[self direction] intValue];
}


- (void)setDirectionRaw:(MessageDirectionEnum)direction
{
    [self setDirection:[NSNumber numberWithInt:direction]];
}

@end
