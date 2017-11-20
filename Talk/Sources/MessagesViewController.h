//
//  MessagesViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
//#import "ItemsViewController.h"
#import "SearchTableViewController.h"

@class MessageData;

@interface MessagesViewController : SearchTableViewController

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedMessage:(MessageData*)selectedMessage
                                  completion:(void (^)(MessageData* selectedMessage))completion;

@end
