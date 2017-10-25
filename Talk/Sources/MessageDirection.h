//
//  MessageDirection.h
//  Talk
//
//  Created by Jeroen Kooiker on 24/10/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef enum
{
    MessageDirectionInbound = 0,
    MessageDirectionOutbound = 1
} MessageDirectionEnum;


@interface MessageDirection : NSObject

+ (NSString*)stringForMessageDirectionEnum:(MessageDirectionEnum)direction;
+ (MessageDirectionEnum)messageDirectionEnumForString:(NSString*)string;

@end
