//
//  PhonesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "PhonesViewController.h"
#import "PhoneData.h"
#import "WebClient.h"
#import "DataManager.h"
#import "Settings.h"
#import "Common.h"
#import "Strings.h"
#import "PhoneNumber.h"


@interface PhonesViewController ()
{
    NSFetchedResultsController* fetchedPhonesController;
}

@end


@implementation PhonesViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.title = [Strings phonesString];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSError* error;
    fetchedPhonesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Phone"
                                                                          withSortKey:@"name"
                                                                                error:&error];
    if (fetchedPhonesController != nil)
    {
        fetchedPhonesController.delegate = self;
    }
    else
    {
        NSLog(@"//### Error: %@", error.localizedDescription);
    }

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:refreshControl];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
 
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


#pragma mark - Results Controller Delegate

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
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
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


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[fetchedPhonesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[fetchedPhonesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhonesController sections] objectAtIndex:section];

        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}


#pragma Helpers

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    PhoneData* phone          = [fetchedPhonesController objectAtIndexPath:indexPath];
    cell.textLabel.text       = phone.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:phone.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.imageView.image      = [UIImage imageNamed:@"Phone"];
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        [[DataManager sharedManager] synchronizePhones:^(NSError* error)
        {
            [Common dispatchAfterInterval:0.1 onMain:^
            {
                [sender endRefreshing];
            }];

            if (error == nil)
            {
                //### Need some fetch data here like in NumbersVC?
            }
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}

@end
