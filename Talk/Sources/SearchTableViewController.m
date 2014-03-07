//
//  SearchTableViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 Cornelis van der Bent. All rights reserved.
//

#import "SearchTableViewController.h"

@interface SearchTableViewController ()

@property (nonatomic, assign) int          width;
@property (nonatomic, strong) NSIndexPath* selectedIndexPath;

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


- (void)viewDidLoad
{
    [super viewDidLoad];

    // This will remove extra separators from tableview
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    [self.tableView scrollToRowAtIndexPath:self.selectedIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:NO];
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


- (void)createIndexOfWidth:(int)width
{
    self.width = width;

    self.nameIndexDictionary = [NSMutableDictionary dictionary];
    for (id object in self.objectsArray)
    {
        NSString*       name = [self nameForObject:object];
        NSString*       nameIndex = [name substringToIndex:self.width];
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

    // Now find the index path of the select name, so we can scroll to it.
    if ([self selectedName] != nil)
    {
        for (int section = 0; section < self.nameIndexArray.count; section++)
        {
            NSString* nameIndex = self.nameIndexArray[section];
            for (int row = 0; row < [self.nameIndexDictionary[nameIndex] count]; row++)
            {
                NSString* name = self.nameIndexDictionary[nameIndex][row];
                if ([name isEqualToString:[self selectedName]])
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                }
            }
        }
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


//  Default implementation, but can over overriden by subclass.
- (UIKeyboardType)searchBarKeyboardType
{
    return UIKeyboardTypeDefault;
}


//  Placeholder for subclass implementation.
- (NSString*)selectedName
{
    return nil;
}


#pragma mark - UISearchDisplayControllerDelegate

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController*)controller
{
    self.searchDisplayController.searchBar.keyboardType = [self searchBarKeyboardType];
}


- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchString
{
    [self filterContentForSearchText:searchString];

    // Return YES to cause the search result table view to be reloaded.
    return YES;
}


- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController *)controller
{
    //### Workaround for iOS issue with setting insets.
    if (controller.searchResultsTableView.contentInset.bottom != 0)
    {
        [controller.searchResultsTableView setContentInset:UIEdgeInsetsMake(0, 0, 0, 0)];
        [controller.searchResultsTableView setScrollIndicatorInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    }
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

    return (isFiltered || self.width == 0) ? 1 : [self.nameIndexArray count];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return (isFiltered || self.width == 0) ? nil : self.nameIndexArray[section];
}


- (NSArray*)sectionIndexTitlesForTableView:(UITableView*)tableView
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return (isFiltered || self.width == 0) ? nil : self.nameIndexArray;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    return isFiltered ? self.filteredNamesArray.count : [self.nameIndexDictionary[self.nameIndexArray[section]] count];
}

@end
