//
//  MessagesViewController.m
//  Talk
//
//  Created by Jeroen Kooiker on 11/9/17.
//  Copyright © 2017 NumberBay Ltd. All rights reserved.
//

#import "MessagesViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"
#import "MessageData.h"
#import "WebClient.h"
#import "Settings.h"


@interface MessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedMessagesController;
@property (nonatomic, strong) MessageData*                selectedMessage;
@property (nonatomic, copy) void (^completion)(MessageData* selectedMessage);
@property (nonatomic, strong) id<NSObject> defaultsObserver;
@property (nonatomic, strong) UIBarButtonItem*            addButton;

@end


@implementation MessagesViewController


- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                              selectedMessage:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedMessage:(MessageData*)selectedMessage
                                  completion:(void (^)(MessageData* selectedMessage))completion
{
    if (self = [super init])
    {
        self.title = NSLocalizedString(@"SMS", @"SMS tab title");

        self.managedObjectContext = managedObjectContext;
        self.selectedMessage = selectedMessage;
        self.completion = completion;
        
        __weak typeof(self) weakSelf = self;
        self.defaultsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue mainQueue]
                                                                              usingBlock:^(NSNotification* note)
        {
            if ([Settings sharedSettings].haveAccount)
            {
                [weakSelf.tableView reloadData];
            }
        }];
    }
    
    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.fetchedMessagesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Message"
                                                                               withSortKeys:@[@"uuid"]
                                                                       managedObjectContext:self.managedObjectContext];
    
    self.fetchedMessagesController.delegate = self;
    
    [[Settings sharedSettings] addObserver:self forKeyPath:@"sortSegment" options:NSKeyValueObservingOptionNew context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectedMessage != nil)
    {
        NSUInteger index = [self.fetchedMessagesController.fetchedObjects indexOfObject:self.selectedMessage];
        
        if (index != NSNotFound)
        {
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            });
        }
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey,id> *)change
                       context:(void *)context
{
    [[DataManager sharedManager] setSortKeys:[Common sortKeys] ofResultsController:self.fetchedMessagesController];
    [self.tableView reloadData];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedMessagesController sections] count];
}


- (UITableView*)tableViewForResultsController:(NSFetchedResultsController *)controller
{
    return self.tableView;
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


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"Selected row %ld section %ld", (long)indexPath.row, (long)indexPath.section);
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;
    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }
    
    [self configureCell:cell
    onResultsController:self.fetchedMessagesController
            atIndexPath:indexPath];
    
    return cell;
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    MessageData* message;
    
    message = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text = [message text];
}


@end
