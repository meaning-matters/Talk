//
//  ConversationViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 18/10/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSQMessages.h"
#import "PhoneNumber.h"


@interface ConversationViewController : JSQMessagesViewController <NSFetchedResultsControllerDelegate>

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
                            localPhoneNumber:(PhoneNumber*)localPhoneNumber
                           externPhoneNumber:(PhoneNumber*)externPhoneNumber
                                   contactId:(NSString*)contactId
                         scrollToMessageUUID:(NSString*)scrollToMessageUUID;

@end
