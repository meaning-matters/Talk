//
//  ForwardingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingsViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"


typedef enum
{
    SelectionForwardings,
    SelectionRecordings,
} Selection;


@interface ForwardingsViewController ()
{
    DataManager*                dataManager;
    NSFetchedResultsController* fetchedForwardingsController;
    NSFetchedResultsController* fetchedRecordingsController;
    Selection                   selection;
    BOOL                        isUpdatingForwardings;
    BOOL                        isUpdatingRecordings;
}

@end


@implementation ForwardingsViewController

- (id)init
{
    if (self = [super initWithNibName:@"ForwardingsView" bundle:nil])
    {
        self.title = NSLocalizedString(@"Forwardings", @"Forwardings tab title");
        self.tabBarItem.image = [UIImage imageNamed:@"ForwardingsTab.png"];


        dataManager = [DataManager sharedManager];

        fetchedForwardingsController = [self fetchResultsForEntityName:@"Forwarding" withSortKey:@"name"];
        fetchedRecordingsController  = [self fetchResultsForEntityName:@"Recording"  withSortKey:@"name"];
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString*   forwardingsTitle;
    NSString*   recordingsTitle;

    forwardingsTitle = NSLocalizedStringWithDefaultValue(@"ForwardingsView ForwardingsButtonTitle", nil,
                                                         [NSBundle mainBundle], @"Logic",
                                                         @"Title of button selecting call forwardings logic.\n"
                                                         @"[1/2 line larger font].");

    recordingsTitle = NSLocalizedStringWithDefaultValue(@"ForwardingsView RecordingsButtonTitle", nil,
                                                        [NSBundle mainBundle], @"Audio",
                                                        @"Title of button selecting recordings.\n"
                                                        @"[1/2 line larger font].");

    self.selectionSegmentedControl.segmentedControlStyle = UndocumentedSearchScopeBarSegmentedControlStyle;
    [self.selectionSegmentedControl setTitle:forwardingsTitle forSegmentAtIndex:0];
    [self.selectionSegmentedControl setTitle:recordingsTitle  forSegmentAtIndex:1];
    NSInteger   index = [Settings sharedSettings].forwardingsSelection;
    [self.selectionSegmentedControl setSelectedSegmentIndex:index];
}


- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName withSortKey:(NSString*)key
{
    NSFetchedResultsController* resultsController;
    NSFetchRequest*             fetchRequest;
    NSEntityDescription*        entity;
    NSSortDescriptor*           nameDescriptor;
    NSArray*                    sortDescriptors;

    fetchRequest = [[NSFetchRequest alloc] init];
    entity = [NSEntityDescription entityForName:entityName
                         inManagedObjectContext:dataManager.managedObjectContext];
    [fetchRequest setEntity:entity];

    nameDescriptor = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
    sortDescriptors = [[NSArray alloc] initWithObjects:nameDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                            managedObjectContext:dataManager.managedObjectContext
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    resultsController.delegate = self;

    return resultsController;
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[[self resultsControllerForTableView:tableView] sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSFetchedResultsController*         controller = [self resultsControllerForTableView:tableView];
    id <NSFetchedResultsSectionInfo>    sectionInfo = [[controller sections] objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    if (tableView == self.forwardingsTableView)
    {
        cell = [self forwardingCellForIndexPath:indexPath];
    }
    else
    {
        cell = [self recordingCellForIndexPath:indexPath];
    }


    return cell;
}


- (UITableViewCell*)forwardingCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.forwardingsTableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    ///#### configure

    return cell;
}


- (UITableViewCell*)recordingCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell*    cell;

    cell = [self.recordingsTableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    ///#### configure

    return cell;
}


#pragma mark - Fetched Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    UITableView*    tableView = [self tableViewForResultsController:controller];

    [tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView*    tableView = [self tableViewForResultsController:controller];

    switch (type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                     withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView*    tableView = [self tableViewForResultsController:controller];

    switch(type)
    {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [tableView cellForRowAtIndexPath:indexPath];    //### Needed?
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    UITableView*    tableView = [self tableViewForResultsController:controller];

    [tableView endUpdates];
}


#pragma mark - Actions

- (IBAction)selectionChangedAction:(id)sender
{
    selection = self.selectionSegmentedControl.selectedSegmentIndex;
    [Settings sharedSettings].forwardingsSelection = selection;

    switch (selection)
    {
        case SelectionForwardings:
            self.forwardingsTableView.hidden = NO;
            self.recordingsTableView.hidden  = YES;
            break;

        case SelectionRecordings:
            self.forwardingsTableView.hidden = YES;
            self.recordingsTableView.hidden  = NO;
            break;
    }
}


#pragma mark - Helper Methods

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    if (controller == fetchedForwardingsController)
    {
        return self.forwardingsTableView;
    }
    else
    {
        return self.recordingsTableView;
    }

}


- (NSFetchedResultsController*)resultsControllerForTableView:(UITableView*)tableView
{
    if (tableView == self.forwardingsTableView)
    {
        return fetchedForwardingsController;
    }
    else
    {
        return fetchedRecordingsController;
    }
}

@end
