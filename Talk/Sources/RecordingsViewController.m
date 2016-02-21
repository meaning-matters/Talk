//
//  RecordingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/02/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "RecordingsViewController.h"
#import "RecordingViewController.h"
#import "RecordingData.h"
#import "DataManager.h"
#import "Strings.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "Common.h"


@interface RecordingsViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedRecordingsController;
@property (nonatomic, strong) RecordingData*              selectedRecording;

@property (nonatomic, copy) void (^completion)(RecordingData* selectedRecording);

@end


@implementation RecordingsViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                            selectedRecording:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                           selectedRecording:(RecordingData*)selectedRecording
                                  completion:(void (^)(RecordingData* selectedRecording))completion
{
    if (self = [super init])
    {
        self.title = [Strings recordingsString];

        self.managedObjectContext = managedObjectContext;
        self.selectedRecording    = selectedRecording;
        self.completion           = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Don't show add button
    if (self.selectedRecording != nil)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }

    self.fetchedRecordingsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Recording"
                                                                             withSortKeys:@[@"name"]
                                                                     managedObjectContext:self.managedObjectContext];
    self.fetchedRecordingsController.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.selectedRecording != nil)
    {
        NSUInteger index = [self.fetchedRecordingsController.fetchedObjects indexOfObject:self.selectedRecording];

        if (index != NSNotFound)
        {
            // Needs to run on next run loop or else does not properly scroll to bottom items.
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:YES];
            });
        }
    }
}


#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedRecordingsController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedRecordingsController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedRecordingsController sections] objectAtIndex:section];

        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedRecordingsController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedRecordingsController sections] objectAtIndex:section];

        if ([sectionInfo numberOfObjects] > 0)
        {
            if (self.headerTitle == nil)
            {
                return NSLocalizedStringWithDefaultValue(@"Recordings ...", nil, [NSBundle mainBundle],
                                                         @"Your Voice Recordings",
                                                         @"\n"
                                                         @"[1/4 line larger font].");
            }
            else
            {
                return self.headerTitle;
            }
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}


- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.footerTitle == nil)
    {
        return NSLocalizedStringWithDefaultValue(@"Recordings List Title", nil, [NSBundle mainBundle],
                                                 @"List of voice Recordings you can chose to play in your "
                                                 @"Destination actions.",
                                                 @"\n"
                                                 @"[ ].");
    }
    else
    {
        return self.footerTitle;
    }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    RecordingViewController* viewController;
    RecordingData*           recording = [self.fetchedRecordingsController objectAtIndexPath:indexPath];

    if (self.completion == nil)
    {
        viewController = [[RecordingViewController alloc] initWithRecording:recording
                                                       managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if (recording != self.selectedRecording)
        {
            self.completion(recording);
        }

        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;


    /*- (UITableViewCell*)recordingCellForIndexPath:(NSIndexPath*)indexPath
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
    }*/


    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    [self configureCell:cell onResultsController:self.fetchedRecordingsController atIndexPath:indexPath];

    return cell;
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        RecordingData* recording = [self.fetchedRecordingsController objectAtIndexPath:indexPath];

        [recording deleteWithCompletion:^(BOOL succeeded)
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
}


#pragma mark - Actions

// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*  modalViewController;
        RecordingViewController* viewController;

        viewController = [[RecordingViewController alloc] initWithRecording:nil
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


#pragma mark - Override of ItemsViewController.

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    RecordingData* recording  = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text       = recording.name;

    if (self.completion == nil)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (recording == self.selectedRecording)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
