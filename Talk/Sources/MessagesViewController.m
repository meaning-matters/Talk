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


// @TODO:
// - Tell the user when there are no messages yet.
// - Make the search function work.
// - Change the icon of this tab.


@interface MessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) UIBarButtonItem*            addButton;
@property (nonatomic, strong) NSManagedObjectContext*     managedObjectContext;
@property (nonatomic, strong) UIRefreshControl*           refreshControl;
@property (nonatomic, strong) NSArray*                    conversations;
@property (nonatomic, strong) UILabel*                    noConversationsLabel;

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
                                                                               withSortKeys:@[@"extern_e164"]
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
    self.noConversationsLabel               = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, self.tableView.bounds.size.height)];
    self.noConversationsLabel.text          = @"There are no messages."; // @TODO: Use NSLocalizedString.
    self.noConversationsLabel.textColor     = [UIColor blackColor];
    self.noConversationsLabel.textAlignment = NSTextAlignmentCenter;
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
        [self.refreshControl beginRefreshing];
        [self.refreshControl endRefreshing];
        
        [self showOrHideNoConversationsLabel];
    });
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
             
            dispatch_async(dispatch_get_main_queue(), ^{
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
// - A group contains all messages with the same extern_e164.
// - Within this group, the messages are sorted by its timestamp.
// - All groups are sorted by the timestamp of the last message of that group.
- (void)orderByConversation
{
    NSMutableDictionary* conversationGroups = [NSMutableDictionary dictionary];
    
    // Group messages by extern_e164.
    [self.objectsArray enumerateObjectsUsingBlock:^(MessageData* message, NSUInteger index, BOOL* stop)
    {
        // Check if this extern_e164 already exists in the dictionary.
        NSMutableArray *messages = [conversationGroups objectForKey:message.extern_e164];
        
        // If not, create this entry.
        if (messages == nil || (id)messages == [NSNull null])
        {
            messages = [NSMutableArray arrayWithCapacity:1];
            [conversationGroups setObject:messages forKey:message.extern_e164];
        }
        
        // Add the message to the array.
        [messages addObject:message];
    }];
    
    // Order the messages in the groups by timestamp.
    [conversationGroups enumerateKeysAndObjectsUsingBlock:^(NSString* extern_e164, NSMutableArray* messages, BOOL* stop)
    {
        NSArray* sortedMessages = [messages sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                                  {
                                      NSDate *first  = [(MessageData*)a timestamp];
                                      NSDate *second = [(MessageData*)b timestamp];
                                      return [first compare:second];
                                  }];
        
        [conversationGroups setValue:sortedMessages forKey:extern_e164];
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    // @TODO: Leave it like this? (We probably have only 1 section, but maybe when the table is still empty ... ?)
    return [[self.fetchedMessagesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.conversations count];
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    // @TODO: Go to the conversation of the clicked cell.
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    ConversationCell* cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"ConversationCell"];
    
    if (cell == nil)
    {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ConversationCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    // Last message of the conversation.
    MessageData* message = [self.conversations[indexPath.row] lastObject];
    
    cell.nameNumberLabel.text  = message.contactId ? [[AppDelegate appDelegate] contactNameForId:message.contactId] : message.extern_e164;
    cell.textPreviewLabel.text = [message.text stringByAppendingString:@"\nsecond line of text will be here"]; // @TODO: Remove this.
    cell.timestampLabel.text   = [self timestampOrDayForDate:message.timestamp];
    
    return cell;
}


- (NSString*)timestampOrDayForDate:(NSDate*)date
{
    NSString*         dayOrDate;
    NSCalendar*       cal         = [NSCalendar currentCalendar];
    NSDateComponents* components  = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
                                                     NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                           fromDate:date];
    NSDate*           entryDate   = [cal dateFromComponents:components];
    components                    = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
                                                     NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                           fromDate:[NSDate date]];
    NSDate*           currentDate = [cal dateFromComponents:components];
    int               timeDelta   = [currentDate timeIntervalSinceDate:entryDate];

    // @TODO: When to display --only time-- OR --time with day/date-- OR --only day/date--
    if (timeDelta < 60 * 60 * 24 * 7)
    {
        if (timeDelta == 0)
        {
//            dayOrDate = NSLocalizedString(@"CNT_TODAY", @"");
//            [NSString stringWithFormat:@"%@\n%@", [NSString formatToTime:latestEntry.date], dayOrDate]
            dayOrDate = [NSString formatToTime:date];
        }
        else if (timeDelta == 60 * 60 * 24)
        {
            dayOrDate = NSLocalizedString(@"CNT_YESTERDAY", @"");
        }
        else
        {
            //Determine the day in the week
            NSCalendar*       calendar = [NSCalendar currentCalendar];
            NSDateComponents* comps    = [calendar components:NSWeekdayCalendarUnit fromDate:date];
            int               weekday  = (int)[comps weekday] - 1;
            
            NSDateFormatter* df = [[NSDateFormatter alloc] init];
            [df setLocale: [NSLocale currentLocale]];
            NSArray* weekdays = [df weekdaySymbols];
            dayOrDate = [weekdays objectAtIndex:weekday];
        }
    }
    else
    {
        dayOrDate = [NSString formatToSlashSeparatedDate:date];
    }
    
    return dayOrDate;
}

@end
