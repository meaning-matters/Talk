//
//  DestinationsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "DestinationsViewController.h"
#import "RecordingViewController.h"
#import "DestinationViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"
#import "DestinationData.h"
#import "RecordingData.h"
#import "WebClient.h"
#import "Strings.h"


typedef enum
{
    SelectionDestinations,
    SelectionRecordings,
} Selection;


@interface DestinationsViewController ()
{
    UISegmentedControl*         selectionSegmentedControl;

    NSFetchedResultsController* fetchedDestinationsController;
    NSFetchedResultsController* fetchedRecordingsController;

    Selection                   selection;
}

@end


@implementation DestinationsViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super init])
    {
        self.title                = [Strings destinationsString];
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = managedObjectContext;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    NSString* destinationsTitle;
    NSString* recordingsTitle;

    destinationsTitle = NSLocalizedStringWithDefaultValue(@"DestinationsView DestinationsButtonTitle", nil,
                                                          [NSBundle mainBundle], @"Logic",
                                                          @"Title of button selecting call destinations logic.\n"
                                                          @"[1/2 line larger font].");

    recordingsTitle = NSLocalizedStringWithDefaultValue(@"DestinationsView RecordingsButtonTitle", nil,
                                                        [NSBundle mainBundle], @"Audio",
                                                        @"Title of button selecting recordings.\n"
                                                        @"[1/2 line larger font].");

    selectionSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[destinationsTitle, recordingsTitle]];
    [selectionSegmentedControl addTarget:self
                                  action:@selector(selectionUpdateAction)
                        forControlEvents:UIControlEventValueChanged];
    NSInteger index = [Settings sharedSettings].destinationsSelection;
    [selectionSegmentedControl setSelectedSegmentIndex:index];
#if HAS_FULL_DESTINATIONS
    self.navigationItem.titleView = selectionSegmentedControl;
#endif

    fetchedDestinationsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Destination"
                                                                              withSortKeys:@[@"name"]
                                                                      managedObjectContext:self.managedObjectContext];
    fetchedDestinationsController.delegate = self;

#if HAS_FULL_DESTINATIONS
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
    return NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Title", nil, [NSBundle mainBundle],
                                             @"Incoming calls go to",
                                             @"\n"
                                             @"[1/4 line larger font].");
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (tableView == self.tableView)
    {
        DestinationViewController* viewController;
        DestinationData*           destination = [fetchedDestinationsController objectAtIndexPath:indexPath];

        viewController = [[DestinationViewController alloc] initWithDestination:destination
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
        cell = [self distinationCellForIndexPath:indexPath];
    }
    else
    {
        cell = [self recordingCellForIndexPath:indexPath];
    }

    return cell;
}


- (UITableViewCell*)distinationCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    DestinationData* destination    = [fetchedDestinationsController objectAtIndexPath:indexPath];
    cell.textLabel.text             = destination.name;
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


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        if (tableView == self.tableView)
        {
            DestinationData* destination = [fetchedDestinationsController objectAtIndexPath:indexPath];

            [destination deleteWithCompletion:^(BOOL succeeded)
            {
                if (succeeded)
                {
                    [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
                }
                else
                {
                    [self.tableView setEditing:NO animated:YES];
                }
            }];
        }
        else
        {
            RecordingData* recording = [fetchedRecordingsController objectAtIndexPath:indexPath];

            if (recording.destinations.count > 0)
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


#pragma mark - Actions

- (void)selectionUpdateAction
{
    if (selection != selectionSegmentedControl.selectedSegmentIndex)
    {
        selection = (Selection)selectionSegmentedControl.selectedSegmentIndex;
        [Settings sharedSettings].destinationsSelection = selection;
    }

    UIBarButtonItem* leftItem;
    UIBarButtonItem* rightItem;
    switch (selection)
    {
        case SelectionDestinations:
        {
            // This overrides button placement of ItemsViewController (the baseclass).
            rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(addDestinationAction)];

            self.tableView.hidden           = NO;
            self.recordingsTableView.hidden = YES;
            break;
        }
        case SelectionRecordings:
        {
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


- (void)addDestinationAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*    modalViewController;
        DestinationViewController* viewController;

        viewController = [[DestinationViewController alloc] initWithDestination:nil
                                                           managedObjectContext:self.managedObjectContext];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showGetStartedViewController];
    }
}


- (void)addRecordingAction
{
    RecordingViewController*    viewController;
    viewController = [[RecordingViewController alloc] initWithRecording:nil
                                                   managedObjectContext:self.managedObjectContext];

    [self.navigationController pushViewController:viewController animated:YES];
}


#pragma mark - ItemsViewController Overrides/Implementations

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    if (controller == fetchedDestinationsController)
    {
        return self.tableView;
    }
    else
    {
        return self.recordingsTableView;
    }
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    UITableView*     tableView = [self tableViewForResultsController:controller];
    RecordingData*   recording;
    DestinationData* destination;

    if (tableView == self.tableView)
    {
        destination = [controller objectAtIndexPath:indexPath];
        cell.textLabel.text = destination.name;
    }
    else
    {
        recording = [controller objectAtIndexPath:indexPath];
        cell.textLabel.text = recording.name;
    }
}


#pragma mark - Helper Methods

- (NSFetchedResultsController*)resultsControllerForTableView:(UITableView*)tableView
{
    if (tableView == self.tableView)
    {
        return fetchedDestinationsController;
    }
    else
    {
        return fetchedRecordingsController;
    }
}

@end
