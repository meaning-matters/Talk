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
#import "NumberData.h"


@interface ConversationsViewController : SearchTableViewController <NSFetchedResultsControllerDelegate>

- (instancetype)initWithNumber:(NumberData*)number managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

@end
