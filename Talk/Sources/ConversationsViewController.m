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
#import "NewConversationViewController.h"

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionNormal   = 1UL << 0, // No search.
    TableSectionContacts = 1UL << 1, // Contacts search results.
    TableSectionMessages = 1UL << 2, // Messages search results.
};

@interface ConversationsViewController ()

@property (nonatomic, strong) dispatch_queue_t            searchQueue;
@property (nonatomic, assign) TableSections               sections;
@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) NSString*                   numberE164;
@property (nonatomic, strong) NSString*                   numberName;
@property (nonatomic, strong) UIRefreshControl*           refreshControl;
@property (nonatomic, strong) NSArray*                    conversations;
@property (nonatomic, strong) UILabel*                    noConversationsLabel;
@property (nonatomic, strong) ConversationCell*           conversationCell;
@property (nonatomic, weak)   id<NSObject>                defaultsObserver;
@property (nonatomic, weak)   id<NSObject>                messagesObserver;
@property (nonatomic, strong) UIBarButtonItem*            composeButtonItem;
@property (nonatomic, strong) NSMutableArray*             contactsSearchResults;
@property (nonatomic, strong) NSMutableArray*             messagesSearchResults;

@end


@implementation ConversationsViewController

- (instancetype)initWithNumber:(NumberData*)number managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
{
    if (self = [super init])
    {
        self.managedObjectContext = managedObjectContext;
        self.numberE164           = number.e164;
        self.numberName           = number.name;
        self.title                = self.numberName;
    }
    
    self.searchQueue = dispatch_queue_create("MessageContacts Search", DISPATCH_QUEUE_SERIAL);
    
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
        [weakSelf.tableView reloadData];
    }];
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    [self.tableView registerNib:[UINib nibWithNibName:@"ConversationCell" bundle:nil] forCellReuseIdentifier:@"ConversationCell"];
    self.conversationCell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    
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
    self.noConversationsLabel.font          = [UIFont fontWithName:@"SF UI Text-Regular" size:15];
    self.noConversationsLabel.textColor     = [Skinning noContentTextColor];
    
    self.composeButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                                           target:self
                                                                           action:@selector(newConversationAction:)];
    self.navigationItem.rightBarButtonItem = self.composeButtonItem;
    
    // Synchronize messages every 30 seconds.
    [NSTimer scheduledTimerWithTimeInterval:30 target:self selector:@selector(refresh:) userInfo:nil repeats:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findContactsForAnonymousMessages) name:NF_RELOAD_CONTACTS object:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^
    {
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
        
        [self orderByConversation];
        [self updateConversationsLabel];
    });
}


// The page needed to be pulled down almost halfway for the refreshcontrol to activate.
// This is now fixed using https://stackoverflow.com/a/40461168/2399348
- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.refreshControl didMoveToSuperview];
}


- (void)findContactsForAnonymousMessages
{
    for (NSArray* conversation in self.conversations)
    {
        MessageData* lastMessage = [conversation lastObject];
        
        // If one message of a conversation has no contactId, none do, because they are all with the same contact.
        if (lastMessage.contactId == nil)
        {
            PhoneNumber* phoneNumber = [[PhoneNumber alloc] initWithNumber:lastMessage.externE164];
            [[AppDelegate appDelegate] findContactsHavingNumber:[phoneNumber e164Format]
                                                     completion:^(NSArray* contactIds)
            {
                if (contactIds.count > 0)
                {
                    // Give all those messages the same contactId.
                    for (MessageData* message in conversation)
                    {
                        message.contactId = [contactIds firstObject];
                    }
                }
            }];
        }
    }
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        NSDate* date = [Settings sharedSettings].messagesCheckDate;
        
        [[DataManager sharedManager] synchronizeMessagesOnlyFromDate:date reply:^(NSError* error)
        {
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
    // Filter to keep only the messages with the correct numberE164.
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"numberE164 = %@", self.numberE164];
    self.objectsArray = [[self.fetchedMessagesController fetchedObjects] filteredArrayUsingPredicate:predicate];
    
    NSMutableDictionary* conversationGroups = [NSMutableDictionary dictionary];
    
    // Group messages by externE164.
    [self.objectsArray enumerateObjectsUsingBlock:^(MessageData* message, NSUInteger index, BOOL* stop)
    {
        // Check if this externE164 already exists in the dictionary.
        NSMutableArray* messages = conversationGroups[message.externE164];
        
        // If not, create this entry.
        if (messages == nil)
        {
            messages = [NSMutableArray array];
            conversationGroups[message.externE164] = messages;
        }
        
        [messages addObject:message];
    }];
    
    // Order the messages in the groups by timestamp.
    [conversationGroups enumerateKeysAndObjectsUsingBlock:^(NSString* externE164, NSMutableArray* messages, BOOL* stop)
    {
        NSArray* sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
        {
            NSDate* first  = ((MessageData*)a).timestamp;
            NSDate* second = ((MessageData*)b).timestamp;
            
            return [first compare:second];
        }];
        
        conversationGroups[externE164] = sortedMessages;
    }];
    
    // Order the groups by the most current timestamp of the contained messages.
    self.conversations = [[NSArray arrayWithArray:[conversationGroups allValues]] sortedArrayUsingComparator:^(id a, id b)
    {
        NSDate* first  = ((MessageData*)[(NSMutableArray*)a lastObject]).timestamp;
        NSDate* second = ((MessageData*)[(NSMutableArray*)b lastObject]).timestamp;
        
        return [second compare:first];
    }];
    
    [self.tableView reloadData];
}


- (void)scrollToChatWithExternE164:(NSString*)externE164
{
    for (int i = 0; i < self.conversations.count; i++)
    {
        if ([((MessageData*)[self.conversations[i] lastObject]).externE164 isEqualToString:externE164])
        {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]
                                  atScrollPosition:UITableViewScrollPositionMiddle
                                          animated:YES];
            break;
        }
    }
}


- (void)newConversationAction:(id)sender
{
    NewConversationViewController* viewController = [[NewConversationViewController alloc] initWithManagedObjectContact:self.managedObjectContext
                                                                                              fetchedMessagesController:self.fetchedMessagesController];
    
    self.createConversationNavigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    
    [viewController.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                      target:self
                                                                                                      action:@selector(cancelAction:)]];
    
    viewController.conversationsViewcontroller = self;
    [self.navigationController presentViewController:self.createConversationNavigationController animated:YES completion:nil];
}


- (void)cancelAction:(id)sender
{
    [self.createConversationNavigationController dismissViewControllerAnimated:YES completion:nil];
}


- (NSString*)nameForObject:(id)object
{
    return ((MessageData*)object).text;
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
    self.sections = 0;
    
    if (self.contactsSearchResults.count == 0 && self.messagesSearchResults.count == 0)
    {
        self.sections |= TableSectionNormal;
    }
    
    if (self.contactsSearchResults.count > 0)
    {
        self.sections |= TableSectionContacts;
    }
    
    if (self.messagesSearchResults.count > 0)
    {
        self.sections |= TableSectionMessages;
    }
    
    return [Common bitsSetCount:self.sections];
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNormal:
        {
            return nil;
            
            break;
        }
        case TableSectionContacts:
        {
            return [Strings contactsString];
            
            break;
        }
        case TableSectionMessages:
        {
            return [Strings messagesString];
            
            break;
        }
        default:
        {
            return nil;
        }
    }
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNormal:
        {
            return self.conversations.count;
            
            break;
        }
        case TableSectionContacts:
        {
            return self.contactsSearchResults.count;
            
            break;
        }
        case TableSectionMessages:
        {
            return self.messagesSearchResults.count;
            
            break;
        }
        default:
        {
            return 0;
        }
    }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message;
    PhoneNumber* localPhoneNumber;
    PhoneNumber* externPhoneNumber;
    NSString*    scrollToMessageUUID = @"";
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNormal:
        {
            message = [self.conversations[indexPath.row] lastObject];
            
            break;
        }
        case TableSectionContacts:
        {
            message = self.contactsSearchResults[indexPath.row];
            
            break;
        }
        case TableSectionMessages:
        {
            message             = self.messagesSearchResults[indexPath.row];
            scrollToMessageUUID = message.uuid;
            
            break;
        }
    }
    
    localPhoneNumber  = [[PhoneNumber alloc] initWithNumber:message.numberE164];
    externPhoneNumber = [[PhoneNumber alloc] initWithNumber:message.externE164];
    
    ConversationViewController* viewController = [[ConversationViewController alloc] initWithManagedObjectContext:self.managedObjectContext
                                                                                        fetchedMessagesController:self.fetchedMessagesController
                                                                                                 localPhoneNumber:localPhoneNumber
                                                                                                externPhoneNumber:externPhoneNumber
                                                                                                        contactId:message.contactId
                                                                                              scrollToMessageUuid:scrollToMessageUUID];
    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    
    if (cell == nil)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    }
    
    MessageData* message;
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNormal:
        {
            // Last message of the conversation.
            MessageData* lastMessage = [self.conversations[indexPath.row] lastObject];
            
            // The dot on the left of the cell is shown if this conversation has an unread message.
            CellDotView* dotView = [CellDotView getFromCell:cell];
            if (dotView == nil)
            {
                dotView = [[CellDotView alloc] init];
                [dotView addToCell:cell];
            }
            
            dotView.hidden = YES;
            
            for (message in self.conversations[indexPath.row])
            {
                if ([[MessageUpdatesHandler sharedHandler] messageUpdateWithUuid:message.uuid] != nil)
                {
                    dotView.hidden = NO;
                    
                    break;
                }
            }
            
            message = lastMessage;
            
            break;
        }
        case TableSectionContacts:
        {
            message = [self.contactsSearchResults[indexPath.row] lastObject];
            
            break;
        }
        case TableSectionMessages:
        {
            message = self.messagesSearchResults[indexPath.row];
            
            break;
        }
    }
    
    PhoneNumber* number        = [[PhoneNumber alloc] initWithNumber:message.externE164];
    cell.nameNumberLabel.text  = message.contactId ? [[AppDelegate appDelegate] contactNameForId:message.contactId]
                                                                                                : [number internationalFormat];
    cell.textPreviewLabel.text = message.text;
    cell.timestampLabel.text   = [Common historyStringForDate:message.timestamp showTimeForToday:YES];
    
    return cell;
}


// Indicates that the tabBar should hide when pushed to the next viewController.
- (BOOL)hidesBottomBarWhenPushed
{
    return self.navigationController.visibleViewController != self;
}


// @TODO: Searching not on main thread, but in background
// @TODO: Abort searching and start over when text changed
- (void)searchBar:(UISearchBar*)searchBar textDidChange:(NSString*)searchText
{
        self.contactsSearchResults = [NSMutableArray array];
        self.messagesSearchResults = [NSMutableArray array];
        
        [self.conversations enumerateObjectsUsingBlock:^(NSArray* conversation, NSUInteger index, BOOL* stop)
        {
            MessageData* lastMessage = [conversation lastObject];
            
            NSRange range = NSMakeRange(0, 0);
            if (lastMessage.contactId != nil)
            {
                NSString* contactName = [[AppDelegate appDelegate] contactNameForId:lastMessage.contactId];
                range = [contactName rangeOfString:searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
            }
            
            if (range.location != NSNotFound)
            {
                [self.contactsSearchResults addObject:conversation];
            }
            else
            {
                range = [lastMessage.externE164 rangeOfString:searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
                if (range.location != NSNotFound)
                {
                    [self.contactsSearchResults addObject:conversation];
                }
            }
            
            [conversation enumerateObjectsUsingBlock:^(MessageData* message, NSUInteger index, BOOL* stop)
             {
                NSRange range = [message.text  rangeOfString:searchText options:NSCaseInsensitiveSearch | NSDiacriticInsensitiveSearch];
                if (range.location != NSNotFound)
                {
                    [self.messagesSearchResults addObject:message];
                }
             }];
        }];
            
        [self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar*)searchBar
{
    self.contactsSearchResults = [NSMutableArray array];
    self.messagesSearchResults = [NSMutableArray array];
    
    [self.tableView reloadData];
}


- (BOOL)searchBarIsEmpty
{
    return self.searchBar.text.length == 0;
}

@end
