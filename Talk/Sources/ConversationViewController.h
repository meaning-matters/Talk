//
//  ConversationViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 18/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"

@interface ConversationViewController : JSQMessagesViewController

@property (nonatomic, strong) NSArray*                    messages;

@property (nonatomic, strong) NSString*                   numberE164;
@property (nonatomic, strong) NSString*                   externE164;
@property (nonatomic, strong) NSString*                   contactId;

@end
