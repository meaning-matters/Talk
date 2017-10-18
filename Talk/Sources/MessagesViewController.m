//
//  MessagesViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessagesViewController.h"
#import "DataManager.h"
#import "Settings.h"
#import "MessageData.h"
#import "Strings.h"
#import "ConversationViewController.h"


// @TODO:
// - Display a message when there are no messages yet.
// - Make the search function work.
// - Change the icon of this tab.


@interface MessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) UIBarButtonItem*            addButton;
@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) UIRefreshControl*           refreshControl;

@end


@implementation MessagesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super init])
    {
        self.title                = [Strings messagesString];
        self.managedObjectContext = managedObjectContext;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchedMessagesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Message"
                                                                               withSortKeys:@[@"uuid"]
                                                                       managedObjectContext:self.managedObjectContext];
    
    self.fetchedMessagesController.delegate = self;
    
    self.objectsArray = [self.fetchedMessagesController fetchedObjects];
    [self createIndexOfWidth:0];
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView sendSubviewToBack:self.refreshControl];
}


// @TODO: Find a better solution for this.
// The page needed to be pulled down almost halfway for the refreshcontrol to activate.
// This is now fixed using https://stackoverflow.com/a/40461168/2399348
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.refreshControl didMoveToSuperview];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        // @TODO: Is this a good way for the initial synchronize, or just put the actual synchronize-code here?
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
    });
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
        {
            self.objectsArray = [self.fetchedMessagesController fetchedObjects];
            [self createIndexOfWidth:0];
             
            dispatch_async(dispatch_get_main_queue(), ^{
                // @TODO: Fix this
                // RefreshControl doesn't hide (table stays down) when outside of this block.
                [sender endRefreshing];
            });
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}


// @TODO: Do we need this? (What is it for exactly? the search function?)
- (NSString*)nameForObject:(id)object
{
    return [(MessageData*)object text];
}


// This needs to be overriden. If not, it will crash most of the time when there are changes to the content.
// @TODO: Find out why and fix this.
-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    // Nothing to do ...
}


- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // @TODO: Leave it like this? (We probably have only 1 section, but maybe when the table is still empty ... ?)
    return [[self.fetchedMessagesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedMessagesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedMessagesController sections] objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


// This hides the tabBar when pushed to next ViewController (Conversation)
- (BOOL)hidesBottomBarWhenPushed
{
    return ![self.navigationController.visibleViewController isEqual:self];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationViewController* viewController = [ConversationViewController messagesViewController];
    
    viewController.managedObjectContext = self.managedObjectContext;
    viewController.fetchedMessagesController = self.fetchedMessagesController;
    
    viewController.number_e164 = @"34668690178"; // @TODO: Remove.
    viewController.extern_e164 = @"31683378285"; // @TODO: Remove.
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    // @TODO: Rebuild this function. Maybe use another cell, etc...
    UITableViewCell* cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }
    
    [self configureCell:cell onResultsController:self.fetchedMessagesController atIndexPath:indexPath];
    
    return cell;
}


- (void)configureCell:(UITableViewCell*)cell onResultsController:(NSFetchedResultsController*)controller atIndexPath:(NSIndexPath*)indexPath
{
    // @TODO: Rebuild this function. Currently this is just to show _something_.
    MessageData* message = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text = [message text];
}

@end
