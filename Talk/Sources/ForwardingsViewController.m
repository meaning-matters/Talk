//
//  ForwardingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 Cornelis van der Bent. All rights reserved.
//

#import "ForwardingsViewController.h"
#import "RecordingViewController.h"
#import "ForwardingViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"
#import "ForwardingData.h"
#import "RecordingData.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Strings.h"


typedef enum
{
    SelectionForwardings,
    SelectionRecordings,
} Selection;


@interface ForwardingsViewController ()
{
    UISegmentedControl*         selectionSegmentedControl;

    DataManager*                dataManager;
    NSManagedObjectContext*     managedObjectContext;

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

        dataManager          = [DataManager sharedManager];
        managedObjectContext = dataManager.managedObjectContext;
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

    selectionSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[forwardingsTitle, recordingsTitle]];
    selectionSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [selectionSegmentedControl addTarget:self
                                  action:@selector(selectionUpdateAction)
                        forControlEvents:UIControlEventValueChanged];
    NSInteger   index = [Settings sharedSettings].forwardingsSelection;
    [selectionSegmentedControl setSelectedSegmentIndex:index];
#if FULL_FORWARDINGS
    self.navigationItem.titleView = selectionSegmentedControl;
#endif

    fetchedForwardingsController = [self fetchResultsForEntityName:@"Forwarding" withSortKey:@"name"];
#if FULL_FORWARDINGS
    fetchedRecordingsController  = [self fetchResultsForEntityName:@"Recording"  withSortKey:@"name"];
#endif

    UIRefreshControl* refreshControl;

    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings refreshFromServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.forwardingsTableView  addSubview:refreshControl];

    refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings refreshFromServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.recordingsTableView addSubview:refreshControl];
}


- (void)refresh:(id)sender
{
    // Add delays to allow uninterrupted animations of UIRefreshControl
    [Common dispatchAfterInterval:0.5 onMain:^
    {
        [self downloadForwardings:^(BOOL success)
        {
            //###Copied from NumbersVC [self fetchData];

            [Common dispatchAfterInterval:0.1 onMain:^
            {
                [sender endRefreshing];
            }];
        }];
    }];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (selection == SelectionForwardings)
    {
        [self.forwardingsTableView deselectRowAtIndexPath:self.forwardingsTableView.indexPathForSelectedRow animated:YES];
    }
    else
    {
        [self.recordingsTableView deselectRowAtIndexPath:self.recordingsTableView.indexPathForSelectedRow animated:YES];
    }
    
    [self selectionUpdateAction];
}


- (NSFetchedResultsController*)fetchResultsForEntityName:(NSString*)entityName withSortKey:(NSString*)key
{
    NSFetchedResultsController* resultsController;
    NSFetchRequest*             fetchRequest;
    NSSortDescriptor*           nameDescriptor;
    NSArray*                    sortDescriptors;

    fetchRequest    = [NSFetchRequest fetchRequestWithEntityName:entityName];
    nameDescriptor  = [[NSSortDescriptor alloc] initWithKey:key ascending:YES];
    sortDescriptors = [[NSArray alloc] initWithObjects:nameDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

    resultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                            managedObjectContext:dataManager.managedObjectContext
                                                              sectionNameKeyPath:nil
                                                                       cacheName:nil];
    resultsController.delegate = self;

    NSError*    error = nil;
    if ([resultsController performFetch:&error] == NO)
    {
        [self handleError:error];
    }

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


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.forwardingsTableView)
    {
        ForwardingViewController*   viewController;
        ForwardingData*             forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

        viewController = [[ForwardingViewController alloc] initWithFetchedResultsController:fetchedForwardingsController
                                                                                 forwarding:forwarding];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        RecordingViewController*    viewController;
        RecordingData*              recording = [fetchedRecordingsController objectAtIndexPath:indexPath];
        
        viewController = [[RecordingViewController alloc] initWithFetchedResultsController:fetchedRecordingsController
                                                                                 recording:recording];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
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

    ForwardingData* forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];
    cell.textLabel.text = forwarding.name;
    cell.imageView.image = [UIImage imageNamed:@"List"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

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

    RecordingData*  recording = [fetchedRecordingsController objectAtIndexPath:indexPath];
    cell.textLabel.text = recording.name;
    cell.imageView.image = [UIImage imageNamed:@"Microphone"];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.forwardingsTableView)
    {
        ForwardingData* forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

        return (forwarding.numbers.count == 0);
    }
    else
    {
        
    }
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (tableView == self.forwardingsTableView)
        {
            NSManagedObjectContext* context = [fetchedForwardingsController managedObjectContext];
            ForwardingData*         forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

            [forwarding deleteFromManagedObjectContext:context completion:^(BOOL succeeded)
            {
                NSError* error;
                if (succeeded == YES && ![context save:&error])
                {
                    [self handleError:error];
                }
            }];
        }
        else
        {
            NSManagedObjectContext* context = [fetchedRecordingsController managedObjectContext];
            RecordingData*          recording = [fetchedRecordingsController objectAtIndexPath:indexPath];
            NSError*                error;

            if (recording.forwardings.count > 0)
            {

            }
            else
            {
                [context deleteObject:recording];
            }

            if (![context save:&error])
            {
                [self handleError:error];
            }

            if (fetchedRecordingsController.fetchedObjects.count == 0)
            {
                [self doneRecordingsAction];
            }
        }
    }
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
    UITableView*        tableView = [self tableViewForResultsController:controller];
    UITableViewCell*    cell;
    RecordingData*      recording;
    ForwardingData*     forwarding;

    switch (type)
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
            cell = [tableView cellForRowAtIndexPath:indexPath];
            if (tableView == self.forwardingsTableView)
            {
                forwarding = [controller objectAtIndexPath:indexPath];
                cell.textLabel.text = forwarding.name;
            }
            else
            {
                recording = [controller objectAtIndexPath:indexPath];
                cell.textLabel.text = recording.name;
            }
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

- (void)selectionUpdateAction
{
    if (selection != selectionSegmentedControl.selectedSegmentIndex)
    {
        selection = selectionSegmentedControl.selectedSegmentIndex;
        [Settings sharedSettings].forwardingsSelection = selection;
    }

    UIBarButtonItem*    leftItem;
    UIBarButtonItem*    rightItem;
    switch (selection)
    {
        case SelectionForwardings:
            rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(addForwardingAction)];

            self.forwardingsTableView.hidden = NO;
            self.recordingsTableView.hidden  = YES;
            break;

        case SelectionRecordings:
            if (self.recordingsTableView.isEditing == YES)
            {
                leftItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                         target:self
                                                                         action:@selector(doneRecordingsAction)];
                rightItem = nil;
            }
            else
            {
                if (fetchedRecordingsController.fetchedObjects.count > 0)
                {
                    leftItem  = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                              target:self
                                                                              action:@selector(editRecordingsAction)];
                }
                else
                {
                    rightItem = nil;
                }

                rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                          target:self
                                                                          action:@selector(addRecordingAction)];
            }

            self.forwardingsTableView.hidden = YES;
            self.recordingsTableView.hidden  = NO;
            break;
    }

    self.navigationItem.leftBarButtonItem  = leftItem;
    self.navigationItem.rightBarButtonItem = rightItem;
}


- (void)editRecordingsAction
{
    [self.recordingsTableView setEditing:YES animated:YES];

    [self selectionUpdateAction];
}


- (void)doneRecordingsAction
{
    [self.recordingsTableView setEditing:NO animated:YES];

    [self selectionUpdateAction];
}


- (void)addForwardingAction
{
    if ([Settings sharedSettings].hasAccount == YES)
    {
        UINavigationController*   modalViewController;
        ForwardingViewController* viewController;

        viewController = [[ForwardingViewController alloc] initWithFetchedResultsController:fetchedForwardingsController
                                                                                 forwarding:nil];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
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


- (void)addRecordingAction
{
    RecordingViewController*    viewController;
    viewController = [[RecordingViewController alloc] initWithFetchedResultsController:fetchedRecordingsController
                                                                             recording:nil];
    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - Server Connections

- (void)downloadForwardings:(void (^)(BOOL success))completion
{
    [[WebClient sharedClient] retrieveIvrList:^(WebClientStatus status, NSArray* array)
    {
        if (status == WebClientStatusOk)
        {
            // Delete IVRs that are no longer on the server.
            NSError*        error;
            NSFetchRequest* request      = [NSFetchRequest fetchRequestWithEntityName:@"Forwarding"];
            [request setPredicate:[NSPredicate predicateWithFormat:@"NOT (uuid IN %@)", array]];
            NSArray*        deleteArray  = [managedObjectContext executeFetchRequest:request error:&error];
            if (error == nil)
            {
                for (NSManagedObject* object in deleteArray)
                {
                    [managedObjectContext deleteObject:object];
                }

                [managedObjectContext save:&error];//### needed this early
                                                    //### Error handling.
            }
            else
            {
                //### Error handling.
            }

            __block int  count   = array.count;
            __block BOOL success = YES;
            for (NSString* uuid in array)
            {
                [[WebClient sharedClient] retrieveIvrForUuid:uuid
                                                        reply:^(WebClientStatus status, NSString* name, NSArray* statements)
                {
                    NSError* error;
                    if (status == WebClientStatusOk)
                    {
                        NSFetchRequest* request = [NSFetchRequest fetchRequestWithEntityName:@"Forwarding"];
                        [request setPredicate:[NSPredicate predicateWithFormat:@"uuid == %@", uuid]];

                        ForwardingData* forwarding;
                        forwarding = [[managedObjectContext executeFetchRequest:request error:&error] lastObject];
                        //### Handle error.
                        if (forwarding == nil)
                        {
                            forwarding = (ForwardingData*)[NSEntityDescription insertNewObjectForEntityForName:@"Forwarding"
                                                                                        inManagedObjectContext:managedObjectContext];
                        }

                        forwarding.uuid = uuid;
                        forwarding.name = name;
                        forwarding.statements = [Common jsonStringWithObject:statements];
                    }
                    else
                    {
                        success = NO;
                    }

                    if (--count == 0)
                    {
                        if (success == YES)
                        {
                            error = nil;
                            [managedObjectContext save:&error];
                            //### Handle error.
                        }
                        else
                        {
                            [managedObjectContext rollback];
                        }
                          
                        completion(success);
                    }
                }];
            }
        }
        else
        {
            completion(NO);
        }
    }];
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


- (void)handleError:(NSError*)error
{
    NSLog(@"Fetch from CoreData error %@, %@", error, [error userInfo]);

#warning //### Replace with code to fix this and/or inform user!!!
    abort();
}

@end
