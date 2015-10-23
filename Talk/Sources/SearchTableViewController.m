//
//  SearchTableViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 23/02/14.
//  Copyright (c) 2014 NumberBay Ltd. All rights reserved.
//

#import "SearchTableViewController.h"
#import "Skinning.h"


@interface SearchTableViewController ()

@property (nonatomic, assign) NSUInteger               width;
@property (nonatomic, strong) NSIndexPath*             selectedIndexPath;
@property (nonatomic, strong) UIActivityIndicatorView* activityIndicator;
@property (nonatomic, assign) BOOL                     hasCenteredActivityIndicator;

@end


@implementation SearchTableViewController

#pragma mark Life Cycle

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

    // This will remove extra separators from tableview.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    self.searchDisplayController.searchResultsTableView.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

    [self.tableView scrollToRowAtIndexPath:self.selectedIndexPath
                          atScrollPosition:UITableViewScrollPositionMiddle
                                  animated:NO];
}


- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];

    if (self.hasCenteredActivityIndicator == NO)
    {
        UIView* topView = [[[[UIApplication sharedApplication] keyWindow] subviews] lastObject];
        CGPoint center = topView.center;
        center = [topView convertPoint:center toView:self.view];
        self.activityIndicator.center = center;

        self.hasCenteredActivityIndicator = YES;
    }
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

- (void)setIsLoading:(BOOL)isLoading
{
    _isLoading = isLoading;

    if (isLoading == YES && self.activityIndicator == nil)
    {
        self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        self.activityIndicator.color = [UIColor blackColor];

        [self.activityIndicator startAnimating];
        [self.view addSubview:self.activityIndicator];
    }
    else if (self.isLoading == NO && self.activityIndicator != nil)
    {
        [self.activityIndicator stopAnimating];
        [self.activityIndicator removeFromSuperview];
        self.activityIndicator = nil;

        self.searchDisplayController.searchBar.text = self.searchDisplayController.searchBar.text;
    }
}


#pragma mark - Supporting Methods

- (void)filterContentForSearchText:(NSString*)searchText
{
    self.filteredNamesArray = [NSMutableArray array];

    for (NSString* nameIndex in self.nameIndexArray)
    {
        for (NSString* name in self.nameIndexDictionary[nameIndex])
        {
            NSRange range = [name rangeOfString:searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            if (range.location != NSNotFound)
            {
                [self.filteredNamesArray addObject:name];
            }
        }
    }
}


- (void)createIndexOfWidth:(NSUInteger)width
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

    // Now find the index path of the selected name, so we can scroll to it.
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


#pragma mark - Table View Data Source

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
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

    return isFiltered ? self.filteredNamesArray.count : [self.nameIndexDictionary[self.nameIndexArray[section]] count];
}

@end
