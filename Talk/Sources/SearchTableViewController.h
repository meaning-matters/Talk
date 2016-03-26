//
//  SearchTableViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UIViewController+Common.h"


@interface SearchTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate,
                                                         UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UITableView*  tableView;
@property (nonatomic, strong) NSArray*             objectsArray;        // The main list of subclass objects.

@property (nonatomic, weak) UISearchBar*           searchBar;


//  Creates the table index.  Must be invoked by subclass each time it's objects have changed.
//  This method reloads the table.
- (void)createIndexOfWidth:(NSUInteger)width;


//  Gets the name of an object on the table.
- (NSString*)nameOnTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;


- (id)objectOnTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;


//  Takes a subclass specific object from the `objectsArray` and returns the name that
//  must be used for the table index.  Must be implemented by subclass.
- (NSString*)nameForObject:(id)object;


- (UIKeyboardType)searchBarKeyboardType;


- (NSString*)selectedObject;

@end
