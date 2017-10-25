//
//  MessageDirection.m
//  Talk
//
//  Created by Jeroen Kooiker on 24/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessageDirection.h"


@implementation MessageDirection

+ (NSString*)stringForMessageDirectionEnum:(MessageDirectionEnum)direction;
{
    switch (direction)
    {
        case MessageDirectionInbound:
        {
            return @"IN";
        }
        case MessageDirectionOutbound:
        {
            return @"OUT";
        }
        default:
        {
            NBLog(@"Invalid MessageDirectionEnum.");
            return @"";
        }
    }
}


+ (MessageDirectionEnum)messageDirectionEnumForString:(NSString*)string;
{
    MessageDirectionEnum direction;
    
    if ([string isEqualToString:@"IN"])
    {
        direction = MessageDirectionInbound;
    }
    else if ([string isEqualToString:@"OUT"])
    {
        direction = MessageDirectionOutbound;
    }
    else
    {
        NBLog(@"Received unknown message direction: %@", string);
        direction = MessageDirectionOutbound; // We should never get here.
    }
    
    return (MessageDirectionEnum)direction;
}

@end
