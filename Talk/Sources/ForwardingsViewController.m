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
#import "Strings.h"


typedef enum
{
    SelectionForwardings,
    SelectionRecordings,
} Selection;


@interface ForwardingsViewController ()
{
    UISegmentedControl*         selectionSegmentedControl;

    NSFetchedResultsController* fetchedForwardingsController;
    NSFetchedResultsController* fetchedRecordingsController;

    Selection                   selection;

    BOOL                        isUpdatingForwardings;
    BOOL                        isUpdatingRecordings;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;

@end


@implementation ForwardingsViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super init])
    {
        self.title                = [Strings forwardingsString];
        self.tabBarItem.image     = [UIImage imageNamed:@"ForwardingsTab.png"];
        self.managedObjectContext = managedObjectContext;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* forwardingsTitle;
    NSString* recordingsTitle;

    forwardingsTitle = NSLocalizedStringWithDefaultValue(@"ForwardingsView ForwardingsButtonTitle", nil,
                                                         [NSBundle mainBundle], @"Logic",
                                                         @"Title of button selecting call forwardings logic.\n"
                                                         @"[1/2 line larger font].");

    recordingsTitle = NSLocalizedStringWithDefaultValue(@"ForwardingsView RecordingsButtonTitle", nil,
                                                        [NSBundle mainBundle], @"Audio",
                                                        @"Title of button selecting recordings.\n"
                                                        @"[1/2 line larger font].");

    selectionSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[forwardingsTitle, recordingsTitle]];
    [selectionSegmentedControl addTarget:self
                                  action:@selector(selectionUpdateAction)
                        forControlEvents:UIControlEventValueChanged];
    NSInteger   index = [Settings sharedSettings].forwardingsSelection;
    [selectionSegmentedControl setSelectedSegmentIndex:index];
#if FULL_FORWARDINGS
    self.navigationItem.titleView = selectionSegmentedControl;
#endif

    fetchedForwardingsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Forwarding"
                                                                             withSortKeys:@[@"name"]
                                                                     managedObjectContext:self.managedObjectContext];
    fetchedForwardingsController.delegate = self;

#if FULL_FORWARDINGS
    fetchedRecordingsController  = [[DataManager sharedManager] fetchResultsForEntityName:@"Recording"
                                                                             withSortKeys:@[@"name"]
                                                                                    error:&error];
    fetchedRecordingsController.delegate = self;
#endif
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self selectionUpdateAction];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    NSFetchedResultsController* controller = [self resultsControllerForTableView:tableView];

    return controller.sections.count;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSFetchedResultsController* controller  = [self resultsControllerForTableView:tableView];

    return [controller.sections[section] numberOfObjects];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedStringWithDefaultValue(@"Forwardings Forwardings List Title", nil, [NSBundle mainBundle],
                                             @"Incoming calls go to",
                                             @"\n"
                                             @"[1/4 line larger font].");
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.tableView)
    {
        ForwardingViewController* viewController;
        ForwardingData*           forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

        viewController = [[ForwardingViewController alloc] initWithForwarding:forwarding
                                                         managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        RecordingViewController* viewController;
        RecordingData*           recording = [fetchedRecordingsController objectAtIndexPath:indexPath];
        
        viewController = [[RecordingViewController alloc] initWithRecording:recording
                                                       managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    if (tableView == self.tableView)
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
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    ForwardingData* forwarding      = [fetchedForwardingsController objectAtIndexPath:indexPath];
    cell.textLabel.text             = forwarding.name;
    cell.imageView.image            = [UIImage imageNamed:@"List"];
    cell.imageView.highlightedImage = [Common invertImage:cell.imageView.image];
    cell.accessoryType              = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (UITableViewCell*)recordingCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.recordingsTableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    RecordingData* recording        = [fetchedRecordingsController objectAtIndexPath:indexPath];
    cell.textLabel.text             = recording.name;
    cell.imageView.image            = [UIImage imageNamed:@"Microphone"];
    cell.imageView.highlightedImage = [Common invertImage:cell.imageView.image];
    cell.accessoryType              = UITableViewCellAccessoryDisclosureIndicator;

    return cell;
}


- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        ForwardingData* forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

        return (forwarding.numbers.count == 0);
    }
    else
    {
        //###
        return NO;
    }
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (tableView == self.tableView)
        {
            ForwardingData* forwarding = [fetchedForwardingsController objectAtIndexPath:indexPath];

            [forwarding deleteFromManagedObjectContext:self.managedObjectContext completion:^(BOOL succeeded)
            {
                [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
            }];
        }
        else
        {
            RecordingData* recording = [fetchedRecordingsController objectAtIndexPath:indexPath];

            if (recording.forwardings.count > 0)
            {

            }
            else
            {
                [self.managedObjectContext deleteObject:recording];
            }

            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];

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
    UITableView* tableView = [self tableViewForResultsController:controller];

    [tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    UITableView* tableView = [self tableViewForResultsController:controller];

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
    UITableView*     tableView = [self tableViewForResultsController:controller];
    UITableViewCell* cell;
    RecordingData*   recording;
    ForwardingData*  forwarding;

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
            if (tableView == self.tableView)
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
    UITableView* tableView = [self tableViewForResultsController:controller];

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

    UIBarButtonItem* leftItem;
    UIBarButtonItem* rightItem;
    switch (selection)
    {
        case SelectionForwardings:
            // This overrides button placement of ItemsViewController (the baseclass).
            rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(addForwardingAction)];

            self.tableView.hidden           = NO;
            self.recordingsTableView.hidden = YES;
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

            self.tableView.hidden           = YES;
            self.recordingsTableView.hidden = NO;
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
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*   modalViewController;
        ForwardingViewController* viewController;

        viewController = [[ForwardingViewController alloc] initWithForwarding:nil
                                                         managedObjectContext:self.managedObjectContext];

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
    viewController = [[RecordingViewController alloc] initWithRecording:nil
                                                   managedObjectContext:self.managedObjectContext];

    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - Helper Methods

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    if (controller == fetchedForwardingsController)
    {
        return self.tableView;
    }
    else
    {
        return self.recordingsTableView;
    }
}


- (NSFetchedResultsController*)resultsControllerForTableView:(UITableView*)tableView
{
    if (tableView == self.tableView)
    {
        return fetchedForwardingsController;
    }
    else
    {
        return fetchedRecordingsController;
    }
}

@end
