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

@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, weak)   NSFetchedResultsController* fetchedMessagesController;

@property (nonatomic, strong) NSString*                   number_e164;
@property (nonatomic, strong) NSString*                   extern_e164;
@property (nonatomic, strong) NSString*                   contactId;

@end
