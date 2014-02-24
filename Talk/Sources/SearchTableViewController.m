//
//  SearchTableViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "SearchTableViewController.h"

@interface SearchTableViewController ()

@end


@implementation SearchTableViewController

- (id)init
{
    if (self = [super initWithNibName:@"SearchTableView" bundle:nil])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;

        self.objectsArray       = [NSMutableArray array];
        self.filteredNamesArray = [NSMutableArray array];
    }

    return self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];
}


- (void)filterContentForSearchText:(NSString*)searchText
{
    self.filteredNamesArray = [NSMutableArray array];

    for (NSString* nameIndex in self.nameIndexArray)
    {
        for (NSString* name in self.nameIndexDictionary[nameIndex])
        {
            NSRange range = [name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                [self.filteredNamesArray addObject:name];
            }
        }
    }
}


- (void)createIndex
{
    // Create indexes.
    self.nameIndexDictionary = [NSMutableDictionary dictionary];
    for (id object in self.objectsArray)
    {
        NSString*       name = [self nameForObject:object];
        NSString*       nameIndex = [name substringToIndex:1];
        NSMutableArray* indexArray;
        if ((indexArray = [self.nameIndexDictionary valueForKey:nameIndex]) != nil)
        {
            [indexArray addObject:name];
        }
        else
        {
            indexArray = [NSMutableArray array];
            self.nameIndexDictionary[nameIndex] = indexArray;
            [indexArray addObject:name];
        }
    }

    // Sort indexes.
    self.nameIndexArray = [[self.nameIndexDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
    for (NSString* nameIndex in self.nameIndexArray)
    {
        self.nameIndexDictionary[nameIndex] = [self.nameIndexDictionary[nameIndex] sortedArrayUsingSelector:@selector(localizedCompare:)];
    }

    [self.tableView reloadData];
}


- (NSString*)nameOnTable:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    if (isFiltered)
    {
        return self.filteredNamesArray[indexPath.row];
    }
    else
    {
        return self.nameIndexDictionary[self.nameIndexArray[indexPath.section]][indexPath.row];
    }
}


//  Placeholder for subclass implementation.
- (NSString*)nameForObject:(id)object
{
    return nil;
}


#pragma mark - UISearchDisplayControllerDelegate

- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
    [self filterContentForSearchText:searchString];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}



#pragma mark - Table View Data Source

//  Placeholder for subclass implementation.
- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return nil;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return isFiltered ? 1 : [self.nameIndexArray count];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return isFiltered ? nil : self.nameIndexArray[section];
}


- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return isFiltered ? nil : self.nameIndexArray;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return isFiltered ? self.filteredNamesArray.count : [self.nameIndexDictionary[self.nameIndexArray[section]] count];
}

@end
