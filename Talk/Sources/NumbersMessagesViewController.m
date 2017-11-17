//
//  NumbersMessagesViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 15-11-17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "NumbersViewController.h"
#import "NumberCountriesViewController.h"
#import "NumberViewController.h"
#import "AddressesViewController.h"
#import "AppDelegate.h"
#import "DataManager.h"
#import "Settings.h"
#import "NumberData.h"
#import "BlockAlertView.h"
#import "Common.h"
#import "WebClient.h"
#import "Strings.h"
#import "Common.h"
#import "BadgeHandler.h"
#import "CellBadgeView.h"
#import "BadgeCell.h"
#import "ConversationsViewController.h"
#import "MessageUpdatesHandler.h"


@interface NumbersMessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedNumbersController;
@property (nonatomic, weak) id<NSObject>                  defaultsObserver;
@property (nonatomic, weak) id<NSObject>                  messagesObserver;

@end


@implementation NumbersMessagesViewController

// @TODO: Only display numbers that are verified etc. (and that can send messages..)
// @TODO: Chats from numbers that no longer exist / expired should still be available.. ?

- (instancetype)init
{
    if (self = [super init])
    {
        // @TODO: Change emoji + other title (without emoji) in tabbar + emoji shouldn't appear in the back button on the next page.
        self.title = NSLocalizedString(@"Numbers 💬", @"Standard string to label numbers-overview for messaging.");
        
        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
    }
    
    __weak typeof(self) weakSelf = self;
    self.defaultsObserver        = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                                     object:nil
                                                                                      queue:[NSOperationQueue mainQueue]
                                                                                 usingBlock:^(NSNotification* note)
    {
        if ([Settings sharedSettings].haveAccount)
        {
            [[AppDelegate appDelegate] updateConversationsBadgeValue];
            [weakSelf.tableView reloadData];
        }
    }];
    
    self.messagesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MessageUpdatesNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
    {
        [[AppDelegate appDelegate] updateConversationsBadgeValue];
        [weakSelf.tableView reloadData];
    }];
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];
    [[NSNotificationCenter defaultCenter] removeObserver:self.messagesObserver];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    [[AppDelegate appDelegate] updateNumbersBadgeValue];
    
    self.fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                              withSortKeys:[Common sortKeys]
                                                                      managedObjectContext:self.managedObjectContext];
    
    self.fetchedNumbersController.delegate  = self;
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
    if (selectedIndexPath != nil)
    {
        [self configureCell:[self.tableView cellForRowAtIndexPath:selectedIndexPath]
        onResultsController:self.fetchedNumbersController
                atIndexPath:selectedIndexPath];
        
        [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
    }
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        NSDate* date = [Settings sharedSettings].messagesCheckDate;
        
        [[DataManager sharedManager] synchronizeMessagesOnlyFromDate: date reply:^(NSError* error)
        {
            dispatch_async(dispatch_get_main_queue(),^
            {
                if (sender == self.refreshControl)
                {
                    [sender endRefreshing];
                }
            });
        }];
    }
    else
    {
        if (sender == self.refreshControl)
        {
            [sender endRefreshing];
        }
    }
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [[DataManager sharedManager] setSortKeys:[Common sortKeys] ofResultsController:self.fetchedNumbersController];
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedNumbersController.sections[section] numberOfObjects];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(@"Your numbers available to use for SMS", @"Standard string to indicate these numbers can be used for SMS.");
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number = [self.fetchedNumbersController objectAtIndexPath:indexPath];
    ConversationsViewController* viewController = [[ConversationsViewController alloc] initWithNumber:number
                                                                                 managedObjectContext:self.managedObjectContext];
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    BadgeCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[BadgeCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    [self configureCell:cell onResultsController:self.fetchedNumbersController atIndexPath:indexPath];
}


#pragma mark - Override of ItemsViewController.

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (void)configureCell:(BadgeCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number        = [self.fetchedNumbersController objectAtIndexPath:indexPath];
    cell.imageView.image      = [UIImage imageNamed:number.isoCountryCode];
    cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text       = number.name;
    if (number.isPending)
    {
        cell.detailTextLabel.text = [Strings pendingString];
    }
    else
    {
        PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:number.e164];
        cell.detailTextLabel.text = [phoneNumber internationalFormat];
    }
    
    cell.badgeCount = [[MessageUpdatesHandler sharedHandler] badgeCountForNumberE164:number.e164];
}

@end

