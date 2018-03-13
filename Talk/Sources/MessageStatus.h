//
//  MessageStatus.h
//  Talk
//
//  Created by Jeru Koiker on 13/03/2018.
//  Copyright © 2018 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, MessageStatusMask)
{
    MessageStatusSent              = 0,
    MessageStatusDelivedToServer   = 1UL << 0,
    MessageStatusDeliverdToVoxbone = 1UL << 1,
    MessageStatusNotSentNoCredit   = 1UL << 2,
    MessageStatusNotSentNoInternet = 1UL << 3,
    MessageStatusNotSentError      = 1UL << 4,
    MessageStatusUnknown           = 1UL << 5,
};

@interface MessageStatus : NSObject

@end
