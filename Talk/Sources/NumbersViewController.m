//
//  NumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
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
#import "AddressUpdatesHandler.h"
#import "CellBadgeView.h"
#import "BadgeCell.h"

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionNumbers      = 1UL << 0,
    TableSectionAddresses    = 1UL << 1,
    TableSectionDestinations = 1UL << 2,
};


@interface NumbersViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedNumbersController;
@property (nonatomic, assign) TableSections               sections;
@property (nonatomic, weak) id<NSObject>                  addressesObserver;
@property (nonatomic, weak) id<NSObject>                  defaultsObserver;
@property (nonatomic, strong) NumberData*                 shownNumber;

@end


@implementation NumbersViewController

- (instancetype)init
{
    if (self = [super init])
    {
        self.title                = [Strings numbersString]; // Not visible, because of segmented control.
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = [DataManager sharedManager].managedObjectContext;
        
        self.sections |= TableSectionNumbers;
        self.sections |= TableSectionAddresses;
        self.sections |= TableSectionDestinations;

        __weak typeof(self) weakSelf = self;
        self.addressesObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AddressUpdatesNotification
                                                                                   object:nil
                                                                                    queue:[NSOperationQueue mainQueue]
                                                                               usingBlock:^(NSNotification* note)
        {
            [[AppDelegate appDelegate] updateNumbersBadgeValue];
            [Common reloadSections:TableSectionAddresses allSections:weakSelf.sections tableView:weakSelf.tableView];
        }];

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
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self.addressesObserver];
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
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    self.shownNumber = nil;

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


// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*        modalViewController;
        NumberCountriesViewController* numberCountriesViewController;

        numberCountriesViewController = [[NumberCountriesViewController alloc] init];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:numberCountriesViewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showGetStartedViewControllerWithAlert];
    }
}


#pragma mark - Public API

- (void)presentNumber:(NumberData*)number
{
    void (^showBlock)(void) = ^
    {
        // Show the Number.
        UIViewController* viewController = [[NumberViewController alloc] initWithNumber:number
                                                                   managedObjectContext:self.managedObjectContext];
        [self.navigationController pushViewController:viewController animated:YES];
        self.shownNumber = number;
    };

    void (^popBlock)(void) = ^
    {
        // Pop display of other (or possibly the same, but we ignore that for now) Number.
        if (self.navigationController.viewControllers.count > 1)
        {
            [self.navigationController popToViewController:self animated:YES];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.333 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
            {
                showBlock();
            });
        }
        else
        {
            showBlock();
        }
    };
    
    // Dismiss Number buying or any other modal (e.g. adding Phone).
    if (self.presentedViewController != nil)
    {
        [self dismissViewControllerAnimated:self.presentedViewController completion:^
        {
            popBlock();
        }];
    }
    else
    {
        popBlock();
    }
}


- (void)hideNumber:(NumberData*)number
{
    if (number == self.shownNumber)
    {
        [self.navigationController popToViewController:self animated:YES];
    }
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedNumbersController.sections.count + 2;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumbers:      numberOfRows = [self.fetchedNumbersController.sections[section] numberOfObjects]; break;
        case TableSectionAddresses:    numberOfRows = 1;                                                                 break;
        case TableSectionDestinations: numberOfRows = 1;                                                                 break;
    }
    
    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;
    
    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            if ([self tableView:tableView numberOfRowsInSection:section] > 0)
            {
                title = NSLocalizedStringWithDefaultValue(@"Numbers Number List Title", nil, [NSBundle mainBundle],
                                                          @"You Can Be Reached At",
                                                          @"\n"
                                                          @"[1/4 line larger font].");
            }
            break;
        }
        case TableSectionAddresses:
        {
            title = NSLocalizedStringWithDefaultValue(@"Numbers Addresses Title", nil, [NSBundle mainBundle],
                                                      @"Your Registered Addresses",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
            break;
        }
        case TableSectionDestinations:
        {
            title = NSLocalizedStringWithDefaultValue(@"Numbers Destinations Title", nil, [NSBundle mainBundle],
                                                      @"Where Incoming Calls Go",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
            break;
        }
    }
    
    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* title = nil;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            if ([self tableView:tableView numberOfRowsInSection:section] == 0)
            {
                title = NSLocalizedStringWithDefaultValue(@"Numbers Number List Footer", nil, [NSBundle mainBundle],
                                                          @"Tap + to buy a Number and become reachable in thousands of "
                                                          @"cities and many countries.\n\n"
                                                          @"You can forward the calls received on a Number to one of "
                                                          @"your Phones (using a Destination). Also, when making calls, "
                                                          @"you can use a Number as your Caller ID.",
                                                          @"\n"
                                                          @"[1/4 line larger font].");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"Numbers Number List Footer", nil, [NSBundle mainBundle],
                                                          @"List of your purchased Numbers, allowing you to be reachable "
                                                          @"in thousands of cities and many countries.\n\n"
                                                          @"You can forward the calls received on a Number to one of "
                                                          @"your Phones (using a Destination). Also, when making calls, "
                                                          @"you can use a Number as your Caller ID.",
                                                          @"\n"
                                                          @"[1/4 line larger font].");
            }
            break;
        }
    }

    return title;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    UIViewController* viewController;
    
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            NumberData* number = [self.fetchedNumbersController objectAtIndexPath:indexPath];
            viewController     = [[NumberViewController alloc] initWithNumber:number
                                                         managedObjectContext:self.managedObjectContext];
            self.shownNumber   = number;
            break;
        }
        case TableSectionAddresses:
        {
            viewController = [[AddressesViewController alloc] init];
            break;
        }
        case TableSectionDestinations:
        {
            viewController = [[DestinationsViewController alloc] init];
            break;
        }
    }

    [self.navigationController pushViewController:viewController animated:YES];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
            if (cell == nil)
            {
                cell = [[BadgeCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
            }

            break;
        }
        case TableSectionAddresses:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"AddressesCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"AddressesCell"];
            }

            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [Strings addressesString];
            [CellBadgeView addToCell:cell count:[AddressUpdatesHandler sharedHandler].addressUpdatesCount];

            [Common setImageNamed:@"AddressesTab" ofCell:cell];
            break;
        }
        case TableSectionDestinations:
        {
            cell = [self.tableView dequeueReusableCellWithIdentifier:@"DestinationsCell"];
            if (cell == nil)
            {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"DestinationsCell"];
            }

            cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
            cell.textLabel.text = [Strings destinationsString];

            [Common setImageNamed:@"DestinationsTab" ofCell:cell];
            break;
        }
     }

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionNumbers:
        {
            [self configureCell:cell onResultsController:self.fetchedNumbersController atIndexPath:indexPath];
            break;
        }
        case TableSectionAddresses:
        {
            break;
        }
        case TableSectionDestinations:
        {
            break;
        }
    }
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
    if ([Common nthBitSet:indexPath.section inValue:self.sections] == TableSectionNumbers)
    {
        NumberData* number        = [self.fetchedNumbersController objectAtIndexPath:indexPath];
        cell.imageView.image      = [UIImage imageNamed:number.isoCountryCode];
        cell.accessoryType        = UITableViewCellAccessoryDisclosureIndicator;
        cell.textLabel.text       = number.name;
        if ([number isPending])
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

        [self addUseButtonWithNumber:number toCell:cell];
    }
}


#pragma mark - Helpers

- (void)addUseButtonWithNumber:(NumberData*)number toCell:(BadgeCell*)cell
{
    BOOL      isCallerId   = [number.e164 isEqualToString:[Settings sharedSettings].callerIdE164];
    NSString* callerIdText = NSLocalizedStringWithDefaultValue(@"Numbers ...", nil, [NSBundle mainBundle],
                                                               @"ID", @"Abbreviation for Caller ID");

    for (UIView* subview in cell.subviews)
    {
        if (subview.tag == CommonUseButtonTag)
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
