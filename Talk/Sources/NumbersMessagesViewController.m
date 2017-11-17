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


@interface NumbersMessagesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedNumbersController;
@property (nonatomic, weak) id<NSObject>                  defaultsObserver;

@end


@implementation NumbersMessagesViewController

// @TODO: Refreshing here should only get messages
// @TODO: Check how messages should be passed to next VC, and refreshing etc...
// @TODO: Only display numbers that are verified etc. (and that can send messages..)

- (instancetype)init
{
    if (self = [super init])
    {
        self.title                = @"Messages"; // @TODO: Change + localizedString + emoji
        
        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
        
        __weak typeof(self) weakSelf = self;
        self.defaultsObserver        = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
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
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.clearsSelectionOnViewWillAppear = YES;
    
    [[AppDelegate appDelegate] updateNumbersBadgeValue];
    
    self.fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                              withSortKeys:[Common sortKeys]
                                                                      managedObjectContext:self.managedObjectContext];
    self.fetchedNumbersController.delegate = self;
    
    self.navigationItem.rightBarButtonItem = nil;
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
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
    return @"Numbers you can send SMS with"; // @TODO: Change + localizedstring
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
    UITableViewCell* cell;

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
    
    cell.badgeCount  = (number.destination == nil) ? 1 : 0;
    cell.badgeCount += [number isExpiryCritical]   ? 1 : 0;
    cell.badgeCount += [AddressStatus isVerifiedAddressStatusMask:number.address.addressStatus] ? 0 : 1;
    
    [self addUseButtonWithNumber:number toCell:cell];
}


#pragma mark - Helpers

- (void)addUseButtonWithNumber:(NumberData*)number toCell:(BadgeCell*)cell
{
    BOOL      isCallerId   = [number.e164 isEqualToString:[Settings sharedSettings].callerIdE164];
    NSString* callerIdText = NSLocalizedStringWithDefaultValue(@"Numbers ...", nil, [NSBundle mainBundle],
                                                               @"ID", @"Abbreviation for Caller ID");
    
    for (UIView* subview in cell.subviews)
    {
        if (subview.tag == CommonUseButton0Tag || subview.tag == CommonUseButton1Tag)
        {
            [subview removeFromSuperview];
        }
    }
    
    if (isCallerId)
    {
        UIButton* button   = [Common addUseButtonWithText:callerIdText toCell:cell atPosition:1];
        [button addTarget:[Common class] action:@selector(showCallerIdAlert) forControlEvents:UIControlEventTouchUpInside];
    }
}

@end

