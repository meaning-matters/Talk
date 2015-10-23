//
//  ItemsViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 26/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ItemsViewController : UITableViewController <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

- (void)refresh:(id)sender;

// To be overriden by subclass.
- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller;

// To be overriden by subclass.
- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath;

@end
