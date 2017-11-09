//
//  ConversationsViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "ConversationsViewController.h"
#import "DataManager.h"
#import "Settings.h"
#import "MessageData.h"
#import "Strings.h"
#import "ConversationCell.h"
#import "AppDelegate.h"
#import "Common.h"
#import "CellDotView.h"
#import "MessageUpdatesHandler.h"
#import "ConversationViewController.h"
#import "PhoneNumber.h"


// @TODO:
// - Change the icon of this tab.


@interface ConversationsViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) UIRefreshControl*           refreshControl;
@property (nonatomic, strong) NSArray*                    conversations;
@property (nonatomic, strong) UILabel*                    noConversationsLabel;
@property (nonatomic, strong) ConversationCell*           conversationCell;
@property (nonatomic, weak) id<NSObject>                  defaultsObserver;
@property (nonatomic, weak) id<NSObject>                  messagesObserver;

@end


@implementation ConversationsViewController

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
    
    __weak typeof(self) weakSelf = self;

    self.defaultsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
    {
        [[AppDelegate appDelegate] updateConversationsBadgeValue];
        [weakSelf.tableView reloadData];
    }];
    
    self.messagesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MessageUpdatesNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
    {
        [[AppDelegate appDelegate] updateConversationsBadgeValue];
        NSIndexPath* selectedIndexPath = self.tableView.indexPathForSelectedRow;
        [weakSelf.tableView reloadData];
        [self.tableView selectRowAtIndexPath:selectedIndexPath
                                    animated:NO
                              scrollPosition:UITableViewScrollPositionNone];
        [[self.tableView cellForRowAtIndexPath:selectedIndexPath] layoutIfNeeded];
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
    
    [[AppDelegate appDelegate] updateConversationsBadgeValue];
    
    self.fetchedMessagesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Message"
                                                                               withSortKeys:nil
                                                                       managedObjectContext:self.managedObjectContext];
    self.fetchedMessagesController.delegate = self;
    
    self.objectsArray = [self.fetchedMessagesController fetchedObjects];
    [self orderByConversation];
    [self createIndexOfWidth:0];
    
    self.refreshControl                 = [[UIRefreshControl alloc] init];
    self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [self.refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    [self.tableView sendSubviewToBack:self.refreshControl];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ConversationCell" bundle:nil]
         forCellReuseIdentifier:@"ConversationCell"];
    self.conversationCell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    CellDotView* dotView  = [[CellDotView alloc] init];
    dotView.hidden        = YES;
    [dotView addToCell:self.conversationCell];
    
    // Label that is shown when there are no conversations.
    self.noConversationsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                          self.tableView.bounds.size.width,
                                                                          self.tableView.bounds.size.height)];
    
    NSString* noConversationsLabelString = NSLocalizedStringWithDefaultValue(@"General:CommonStrings NoConversations",
                                                                             nil,
                                                                             [NSBundle mainBundle],
                                                                             @"There are no conversations yet.",
                                                                             @"Standard label to tell the user there are no conversations....\n"
                                                                             @"[No size constraint].");
    
    self.noConversationsLabel.text          = noConversationsLabelString;
    self.noConversationsLabel.textAlignment = NSTextAlignmentCenter;
    self.noConversationsLabel.font          = [UIFont fontWithName:@"SF UI Text-Regular"
                                                              size:15];
    self.noConversationsLabel.textColor     = [UIColor colorWithRed:0.427451 green:0.427451 blue:0.447059 alpha:1];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
        
        [self updateConversationsLabel];
    });
    
    // Synchronize messages every 30 seconds.
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
}


// The page needed to be pulled down almost halfway for the refreshcontrol to activate.
// This is now fixed using https://stackoverflow.com/a/40461168/2399348
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.refreshControl didMoveToSuperview];
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        NSDate* date = [Settings sharedSettings].messagesCheckDate;
        
        [[DataManager sharedManager] synchronizeMessagesOnlyFromDate: date reply:^(NSError* error)
        {
            self.objectsArray = [self.fetchedMessagesController fetchedObjects];
            
            [self orderByConversation];
            [self createIndexOfWidth:0];
            
            dispatch_async(dispatch_get_main_queue(),^
            {
                if (sender == self.refreshControl)
                {
                    [sender endRefreshing];
                }
                
                [self updateConversationsLabel];
                [self.tableView reloadData];
            });
        }];
    }
    else
    {
        if (sender == self.refreshControl)
        {
            [sender endRefreshing];
        }
        
        [self updateConversationsLabel];
        [self.tableView reloadData];
    }
}


// Shows or hides the noConversationsLabel depending on if there are conversations.
- (void)updateConversationsLabel
{
    self.tableView.backgroundView = (self.conversations.count == 0) ? self.noConversationsLabel : nil;
}


// Groups messages by conversation:
// - A group contains all messages with the same externE164.
// - Within this group, the messages are sorted by timestamp.
// - All groups are sorted by the timestamp of the last message of that group.
- (void)orderByConversation
{
    NSMutableDictionary* conversationGroups = [NSMutableDictionary dictionary];
    
    // Group messages by externE164.
    [self.objectsArray enumerateObjectsUsingBlock:^(MessageData* message, NSUInteger index, BOOL* stop)
    {
        // Check if this externE164 already exists in the dictionary.
        NSMutableArray* messages = [conversationGroups objectForKey:message.externE164];
        
        // If not, create this entry.
        if (messages == nil || (id)messages == [NSNull null])
        {
            messages = [NSMutableArray arrayWithCapacity:1];
            [conversationGroups setObject:messages forKey:message.externE164];
        }
        
        [messages addObject:message];
    }];
    
    // Order the messages in the groups by timestamp.
    [conversationGroups enumerateKeysAndObjectsUsingBlock:^(NSString* externE164, NSMutableArray* messages, BOOL* stop)
    {
        NSArray* sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
        {
            NSDate* first  = [(MessageData*)a timestamp];
            NSDate* second = [(MessageData*)b timestamp];
            
            return [first compare:second];
        }];
        
        [conversationGroups setValue:sortedMessages forKey:externE164];
    }];
    
    // Order the groups by the most current timestamp of the contained messages.
    self.conversations = [[NSArray arrayWithArray:[conversationGroups allValues]] sortedArrayUsingComparator:^(id a, id b)
    {
        NSDate* first  = [(MessageData*)[(NSMutableArray*)a lastObject] timestamp];
        NSDate* second = [(MessageData*)[(NSMutableArray*)b lastObject] timestamp];
        
        return [first compare:second];
    }];
    
    // Reverse the array -> groups with newest messages should come first.
    self.conversations = [[self.conversations reverseObjectEnumerator] allObjects];
    
    [self.tableView reloadData];
}


// @TODO: Do we need this? (What is it for exactly? the search function?) (other user-story)
- (NSString*)nameForObject:(id)object
{
    return [(MessageData*)object text];
}


// This needs to be overriden. If not, it will crash most of the time when there are changes to the content.
- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    // Nothing to do ...
}


- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return self.conversationCell.bounds.size.height;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedMessagesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversations count];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message = [self.conversations[indexPath.row] lastObject];
 
    ConversationViewController* viewController = [ConversationViewController messagesViewController];
    
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:message.externE164];
    viewController.externE164 = phoneNumber.e164Format;
    
    [phoneNumber setNumber:message.numberE164];
    viewController.numberE164 = phoneNumber.e164Format;
    viewController.contactId  = message.contactId;
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationCell* cell;
    
    if (cell == nil)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"ConversationCell" forIndexPath:indexPath];
        
        CellDotView* dotView = [[CellDotView alloc] init];
        [dotView addToCell:cell];
        dotView.hidden = YES;
    }
    
    // Last message of the conversation.
    MessageData* message = [self.conversations[indexPath.row] lastObject];
    
    // The dot on the left of the cell is shown if this conversation has an unread message.
    CellDotView* dotView = [CellDotView getFromCell:cell];
    dotView.hidden       = YES;
    
    for (MessageData* message in self.conversations[indexPath.row])
    {
        if ([[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid] != nil)
        {
            dotView.hidden = NO;
            break;
        }
    }
    
    cell.nameNumberLabel.text  = message.contactId ? [[AppDelegate appDelegate] contactNameForId:message.contactId] : message.externE164;
    cell.textPreviewLabel.text = message.text;
    cell.timestampLabel.text   = [Common historyStringForDate:message.timestamp showTimeForToday:YES];
    
    return cell;
}


// Indicates that the tabBar should hide when pushed to the next viewController.
- (BOOL)hidesBottomBarWhenPushed
{
    return self.navigationController.visibleViewController != self;
}

@end
