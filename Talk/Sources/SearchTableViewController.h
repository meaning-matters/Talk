//
//  SearchTableViewController.h
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface SearchTableViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate>

@property (nonatomic, weak) IBOutlet UITableView*  tableView;
@property (nonatomic, strong) NSArray*             objectsArray;        // The main list of subclass objects.

@property (nonatomic, strong) NSArray*             nameIndexArray;      // Array with all first letters of object names.
@property (nonatomic, strong) NSMutableDictionary* nameIndexDictionary; // Dictionary with array of names per letter.
@property (nonatomic, strong) NSMutableArray*      filteredNamesArray;  // List of names selected by search.

@property (nonatomic, assign) BOOL                 isLoading;


//  Creates the table index.  Must be invoked by subclass each time it's objects have changed.
//  This method reloads the table.
- (void)createIndexOfWidth:(NSUInteger)width;


//  Get the name of an object on the table.
- (NSString*)nameOnTable:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath;


//  Takes a subclass specific object from the `objectsArray` and return the name that
//  must be used for the table index.  Must be implemented by subclass.
- (NSString*)nameForObject:(id)object;


- (UIKeyboardType)searchBarKeyboardType;


- (NSString*)selectedName;

@end
