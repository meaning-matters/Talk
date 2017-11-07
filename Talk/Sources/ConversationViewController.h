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

@interface ConversationViewController : JSQMessagesViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
                                  numberE164:(PhoneNumber*)numberE164
                                  externE164:(PhoneNumber*)externE164
                                   contactId:(NSString*)contactId;

@end
