//
//  MessagesViewController.h
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SearchTableViewController.h"


@class MessageData;

@interface MessagesViewController : SearchTableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) UINavigationController* writeMessageNavigationController;

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
