//
//  NewConversationViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 03/11/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "SearchTableViewController.h"
#import "ConversationViewController.h"
#import "ConversationsViewController.h"

@interface NewConversationViewController : SearchTableViewController

@property (nonatomic, strong) ConversationsViewController* conversationsViewcontroller;

- (instancetype)initWithManagedObjectContact:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController
                            localPhoneNumber:(PhoneNumber*)localPhoneNumber;

@end
