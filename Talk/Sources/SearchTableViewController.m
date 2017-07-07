//
//  SearchTableViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "SearchTableViewController.h"
#import "Skinning.h"
#import "NSString+Common.h"


@interface SearchTableViewController ()

@property (nonatomic, strong) NSArray*             nameIndexArray;            // Array with all first letter(s) of object names.
@property (nonatomic, strong) NSMutableDictionary* indexedObjectsDictionary;  // Dictionary with array of objects per index string.
@property (nonatomic, strong) NSMutableArray*      filteredObjectsArray;      // List of names selected by search.

@property (nonatomic, assign) NSUInteger           width;
@property (nonatomic, strong) NSIndexPath*         selectedIndexPath;

@end


@implementation SearchTableViewController

#pragma mark Life Cycle

- (id)init
{
    if (self = [super initWithNibName:@"SearchTableView" bundle:nil])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;

        self.objectsArray         = [NSMutableArray array];
        self.filteredObjectsArray = [NSMutableArray array];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // This will remove extra separators from tableview.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.searchDisplayController.searchResultsTableView.delegate = self;
    self.searchBar = self.searchDisplayController.searchBar;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    // Needs to run on next run loop or else does not properly scroll to bottom items.
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.tableView scrollToRowAtIndexPath:self.selectedIndexPath
                              atScrollPosition:UITableViewScrollPositionMiddle
                                      animated:NO];
    });
}


#pragma mark - Scrollview Delegate

- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;

    if (scrollView == tableView)
    {
        if ([tableView contentInset].bottom != 0)
        {
            [tableView setContentInset:UIEdgeInsetsZero];
            [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
        }
    }
}


#pragma mark Property Setter

- (void)didSetIsLoading
{
    if (self.isLoading == NO)
    {
        self.searchDisplayController.searchBar.text = self.searchDisplayController.searchBar.text;
    }
}


#pragma mark - Supporting Methods

- (void)filterContentForSearchText:(NSString*)searchText
{
    self.filteredObjectsArray = [NSMutableArray array];

    for (NSString* nameIndex in self.nameIndexArray)
    {
        for (id object in self.indexedObjectsDictionary[nameIndex])
        {
            NSString* name = [self nameForObject:object];
            NSRange range = [name rangeOfString:searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch]; //### With NSAnchoredSearch only searches at begin of words.
            if (range.location != NSNotFound)
            {
                [self.filteredObjectsArray addObject:object];
            }
        }
    }
}


- (void)createIndexOfWidth:(NSUInteger)width
{
    self.width = width;

    self.indexedObjectsDictionary = [NSMutableDictionary dictionary];
    for (id object in self.objectsArray)
    {
        NSString*       name      = [self nameForObject:object];
        NSString*       nameIndex = [[name substringToIndex:self.width] stringByTrimmingLeadingWhiteSpace]; // Trimming done to support South Korea unequal sized postcodes (see AddressPostcodesViewController.m for more changes).
        NSMutableArray* indexArray;
        if ((indexArray = self.indexedObjectsDictionary[nameIndex]) == nil)
        {
            indexArray = [NSMutableArray array];
            self.indexedObjectsDictionary[nameIndex] = indexArray;
        }

        [indexArray addObject:object];
    }

    // Sort indexes.
    self.nameIndexArray = [[self.indexedObjectsDictionary allKeys] sortedArrayUsingSelector:@selector(localizedCompare:)];
    for (NSString* nameIndex in self.nameIndexArray)
    {
        NSArray* indexArray = self.indexedObjectsDictionary[nameIndex];
        indexArray = [indexArray sortedArrayUsingComparator:^NSComparisonResult(id object1, id object2)
        {
            return [[self nameForObject:object1] localizedCompare:[self nameForObject:object2]];
        }];

        self.indexedObjectsDictionary[nameIndex] = indexArray;
    }

    // Now find the index path of the selected name, so we can scroll to it.
    if ([self selectedObject] != nil)
    {
        for (int section = 0; section < self.nameIndexArray.count; section++)
        {
            NSString* nameIndex = self.nameIndexArray[section];
            for (int row = 0; row < [self.indexedObjectsDictionary[nameIndex] count]; row++)
            {
                id object = self.indexedObjectsDictionary[nameIndex][row];
                if (object == [self selectedObject])
                {
                    self.selectedIndexPath = [NSIndexPath indexPathForRow:row inSection:section];
                }
            }
        }
    }

    [self.tableView reloadData];
}


- (NSString*)nameOnTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    if (isFiltered)
    {
        return [self nameForObject:self.filteredObjectsArray[indexPath.row]];
    }
    else
    {
        id object = self.indexedObjectsDictionary[self.nameIndexArray[indexPath.section]][indexPath.row];

        return [self nameForObject:object];
    }
}


- (id)objectOnTableView:(UITableView*)tableView atIndexPath:(NSIndexPath*)indexPath
{
    BOOL isFiltered = (tableView == self.searchDisplayController.searchResultsTableView);

    if (isFiltered)
    {
        return self.filteredObjectsArray[indexPath.row];
    }
    else
    {
        return self.indexedObjectsDictionary[self.nameIndexArray[indexPath.section]][indexPath.row];
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
- (NSString*)selectedObject
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


#pragma mark - Table View Data Source

- (void)tableView:(UITableView*)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    view.tintColor = [Skinning backgroundTintColor];
}


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

    return isFiltered ? self.filteredObjectsArray.count : [self.indexedObjectsDictionary[self.nameIndexArray[section]] count];
}

@end
