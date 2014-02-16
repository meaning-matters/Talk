//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "NumbersViewController.h"
#import "NumberCountriesViewController.h"
#import "NumberViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "Settings.h"
#import "NumberData.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "WebClient.h"
#import "Base64.h"
#import "Strings.h"


@interface NumbersViewController ()
{
    NSFetchedResultsController* fetchedNumbersController;
    UISegmentedControl*         sortSegmentedControl;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@end


@implementation NumbersViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.title                = [Strings numbersString]; // Not used, because we're having a segmented control.
        self.tabBarItem.image     = [UIImage imageNamed:@"NumbersTab.png"];
        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    NSError* error;
    fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                         withSortKeys:[self sortKeys]
                                                                 managedObjectContext:self.managedObjectContext
                                                                                error:&error];
    if (fetchedNumbersController != nil)
    {
        fetchedNumbersController.delegate = self;
    }
    else
    {
        NSLog(@"//### Error: %@", error.localizedDescription);
    }

    NSString* byCountries = NSLocalizedStringWithDefaultValue(@"Numbers SortByCountries", nil,
                                                              [NSBundle mainBundle], @"Countries",
                                                              @"\n"
                                                              @"[1/4 line larger font].");
    NSString* byNames     = NSLocalizedStringWithDefaultValue(@"Numbers SortByNames", nil,
                                                              [NSBundle mainBundle], @"Names",
                                                              @"\n"
                                                              @"[1/4 line larger font].");
    sortSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[byCountries, byNames]];
    sortSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    sortSegmentedControl.selectedSegmentIndex  = [Settings sharedSettings].numbersSortSegment;
    [sortSegmentedControl addTarget:self
                             action:@selector(sortOrderChangedAction)
                   forControlEvents:UIControlEventValueChanged];

    self.navigationItem.titleView = sortSegmentedControl;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                           target:self
                                                                                           action:@selector(addAction)];

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
        {
            [sender endRefreshing];
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self updateCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath] atIndexPath:selectedIndexPath];

        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    }
}


- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Utility Methods

- (void)sortOrderChangedAction
{
    [Settings sharedSettings].numbersSortSegment = sortSegmentedControl.selectedSegmentIndex;

    NSError* error;
    if ([[DataManager sharedManager] setSortKeys:[self sortKeys]
                             ofResultsController:fetchedNumbersController
                                           error:&error] == YES)
    {
        [self.tableView reloadData];
    }
}


- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*         modalViewController;
        NumberCountriesViewController*  numberCountriesViewController;

        numberCountriesViewController = [[NumberCountriesViewController alloc] init];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:numberCountriesViewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showProvisioningViewController];
    }
}


- (void)updateCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number        = [fetchedNumbersController objectAtIndexPath:indexPath];
    cell.imageView.image      = [UIImage imageNamed:number.numberCountry];
    cell.textLabel.text       = number.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:number.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return fetchedNumbersController.sections.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [fetchedNumbersController.sections[section] numberOfObjects];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberData*           number         = [fetchedNumbersController objectAtIndexPath:indexPath];
    NumberViewController* viewController = [[NumberViewController alloc] initWithNumber:number];

    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self updateCell:cell atIndexPath:indexPath];
}


/* Create floating header (with sort segment for example)
- (UIView*)tableView:(UITableView*)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}
*/


#pragma mark - Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (void)controller:(NSFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView* tableView = self.tableView;

    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            [self updateCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}


#pragma mark - Helpers

- (NSArray*)sortKeys
{
    if ([Settings sharedSettings].numbersSortSegment == 0)
    {
        return @[@"numberCountry", @"name"];
    }
    else
    {
        return @[@"name", @"numberCountry"];
    }
}

@end
