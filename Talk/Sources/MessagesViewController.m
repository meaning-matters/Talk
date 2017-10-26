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
#import "ConversationCell.h"
#import "AppDelegate.h"
#import "Common.h"
#import "CellDotView.h"
#import "MessageUpdatesHandler.h"
#import "ConversationViewController.h"
#import "PhoneNumber.h"


// @TODO:
// - Make the search function work.
// - Change the icon of this tab.


@interface MessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) UIRefreshControl*           refreshControl;
@property (nonatomic, strong) NSArray*                    conversations;
@property (nonatomic, strong) UILabel*                    noConversationsLabel;
@property (nonatomic, weak) id<NSObject>                  observer;
@property (nonatomic, weak) id<NSObject>                  messagesObserver;

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
    
    __weak typeof(self) weakSelf = self;
    self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                      object:nil
                                                                       queue:[NSOperationQueue mainQueue]
                                                                  usingBlock:^(NSNotification* note)
                    {
                        [[AppDelegate appDelegate] updateMessagesBadgeValue];
                        [weakSelf.tableView reloadData];
                    }];
    
    self.messagesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:MessageUpdatesNotification
                                                                              object:nil
                                                                               queue:[NSOperationQueue mainQueue]
                                                                          usingBlock:^(NSNotification* note)
                            {
                                [[AppDelegate appDelegate] updateMessagesBadgeValue];
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
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[AppDelegate appDelegate] updateMessagesBadgeValue];
    
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
    
    // Label that is shown when there are no conversations.
    self.noConversationsLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0, 0,
                                                                                        self.tableView.bounds.size.width,
                                                                                        self.tableView.bounds.size.height)];
    self.noConversationsLabel.text          = [Strings noConversationsString];
    self.noConversationsLabel.textColor     = [UIColor blackColor];
    self.noConversationsLabel.textAlignment = NSTextAlignmentCenter;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
        
        [self showOrHideNoConversationsLabel];
    });
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
        [[DataManager sharedManager] synchronizeWithServer:^(NSError* error)
        {
            self.objectsArray = [self.fetchedMessagesController fetchedObjects];
            
            [self orderByConversation];
            [self createIndexOfWidth:0];
             
            dispatch_async(dispatch_get_main_queue(),^
            {
                [sender endRefreshing];
                [self showOrHideNoConversationsLabel];
            });
        }];
    }
    else
    {
        [sender endRefreshing];
        [self showOrHideNoConversationsLabel];
    }
}


// Shows or hides the noConversationsLabel depending on if there are conversations.
- (void)showOrHideNoConversationsLabel
{
    if ([self.conversations count] == 0)
    {
        self.tableView.backgroundView = self.noConversationsLabel;
    }
    else
    {
        self.tableView.backgroundView = nil;
    }
}


// Groups messages by conversation:
// - A group contains all messages with the same externE164.
// - Within this group, the messages are sorted by its timestamp.
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
        
        // Add the message to the array.
        [messages addObject:message];
    }];
    
    // Order the messages in the groups by timestamp.
    [conversationGroups enumerateKeysAndObjectsUsingBlock:^(NSString* externE164, NSMutableArray* messages, BOOL* stop)
    {
        NSArray* sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                {
                                    NSDate *first  = [(MessageData*)a timestamp];
                                    NSDate *second = [(MessageData*)b timestamp];
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
-(void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    // Nothing to do ...
}


- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (CGFloat)tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
    return 70;
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
    MessageData* message = self.objectsArray[indexPath.row];
 
    ConversationViewController* viewController = [ConversationViewController messagesViewController];
    viewController.managedObjectContext        = self.managedObjectContext;
    viewController.fetchedMessagesController   = self.fetchedMessagesController;
    
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:message.externE164];
    viewController.externE164 = [phoneNumber e164Format];
    
    [phoneNumber setNumber:message.numberE164];
    viewController.numberE164 = [phoneNumber e164Format];
    
    viewController.contactId  = message.contactId;
    
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationCell* cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    
    if (cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ConversationCell" owner:nil options:nil] objectAtIndex:0];
        
        CellDotView* dotView = [[CellDotView alloc] init];
        [dotView addToCell:cell];
    }
    
    // Last message of the conversation.
    MessageData* message = [self.conversations[indexPath.row] lastObject];
    
    // The dot on the left of the cell is shown if the last message of this conversation (the one used as preview)
    // has an update on the property uuid (so if it's new, since uuid doesn't change).
    CellDotView* dotView = [CellDotView getFromCell:cell];
    dotView.hidden       = [[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid] == nil;
    
    cell.nameNumberLabel.text  = message.contactId ? [[AppDelegate appDelegate] contactNameForId:message.contactId] : message.externE164;
    cell.textPreviewLabel.text = message.text;
    cell.timestampLabel.text   = [Common timestampOrDayOrDateForDate:message.timestamp];
    
    return cell;
}


// Indicate that the tabBar should hide when pushed to the next viewController.
- (BOOL)hidesBottomBarWhenPushed
{
    return self.navigationController.visibleViewController != self;
}

@end
