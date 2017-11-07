//
//  NewConversationViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 03/11/2017.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "SearchTableViewController.h"

@interface NewConversationViewController : SearchTableViewController

- (instancetype)initWithManagedObjectContact:(NSManagedObjectContext*)managedObjectContext
                   fetchedMessagesController:(NSFetchedResultsController*)fetchedMessagesController;

@end
