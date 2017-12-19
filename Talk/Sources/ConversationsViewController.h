//
//  ConversationsViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"


@interface ConversationsViewController : SearchTableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UINavigationController* createConversationNavigationController;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

- (void)scrollToChatWithExternE164:(NSString*)externE164;

@end
