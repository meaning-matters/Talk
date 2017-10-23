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
//        cell = [[ConversationCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"ConversationCell"];
    }
    
    MessageData* message = [self.fetchedMessagesController objectAtIndexPath:indexPath];
    
    cell.nameNumberLabel.text = message.extern_e164;
    cell.textPreviewLabel.text = [message.text stringByAppendingString:@"\nfgdfds gfds gfdas"];
    cell.timestampLabel.text = @"Yesterday";
    
    return cell;
}

@end



/*
 @TODO: Use this for displaying the date / time of a conversation:
 (from NSRecentsListViewController.m -> cellForRowAtIndexPath)
 
// Set the time and (yesterday/day name in case of less than a week ago/date)
NSString*         dayOrDate;
NSCalendar*       cal         = [NSCalendar currentCalendar];
NSDateComponents* components  = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
                                                 NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                       fromDate:latestEntry.date];
NSDate*           entryDate   = [cal dateFromComponents:components];
components                    = [cal components:(NSCalendarUnitYear       | NSCalendarUnitMonth |
                                                 NSCalendarUnitWeekOfYear | NSCalendarUnitDay)
                                       fromDate:[NSDate date]];
NSDate*           currentDate = [cal dateFromComponents:components];
int               timeDelta   = [currentDate timeIntervalSinceDate:entryDate];

if (timeDelta < 60 * 60 * 24 * 7)
{
    if (timeDelta == 0)
    {
        dayOrDate = NSLocalizedString(@"CNT_TODAY", @"");
    }
    else if (timeDelta == 60 * 60 * 24)
    {
        dayOrDate = NSLocalizedString(@"CNT_YESTERDAY", @"");
    }
    else
    {
        //Determine the day in the week
        NSCalendar*       calendar = [NSCalendar currentCalendar];
        NSDateComponents* comps    = [calendar components:NSWeekdayCalendarUnit fromDate:latestEntry.date];
        int               weekday  = (int)[comps weekday] - 1;
        
        NSDateFormatter* df = [[NSDateFormatter alloc] init];
        [df setLocale: [NSLocale currentLocale]];
        NSArray* weekdays = [df weekdaySymbols];
        dayOrDate = [weekdays objectAtIndex:weekday];
    }
}
else
{
    dayOrDate = [NSString formatToSlashSeparatedDate:latestEntry.date];
}

//Set the attributed text (bold time and regular day)
NSString*                  detailText;;
NSMutableAttributedString* attributedText;

detailText     = [NSString stringWithFormat:@"%@\n%@", [NSString formatToTime:latestEntry.date], dayOrDate];
attributedText = [[NSMutableAttributedString alloc] initWithString:detailText
                                                        attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:14]}];

[attributedText setAttributes:@{NSFontAttributeName            : [UIFont boldSystemFontOfSize:14],
                                NSForegroundColorAttributeName : FONT_COLOR_MY_NUMBER}
                        range:NSMakeRange(0, [detailText rangeOfString:@"\n"].location)];

[cell.detailTextLabel setAttributedText:attributedText];
[cell.detailTextLabel setTextAlignment:NSTextAlignmentRight];
[cell.detailTextLabel setNumberOfLines:2];
[cell.detailTextLabel setTextColor:[[NBAddressBookManager sharedManager].delegate valueColor]];
*/
