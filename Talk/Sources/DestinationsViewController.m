//
//  DestinationsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 06/11/12.
//  Copyright (c) 2012 NumberBay Ltd. All rights reserved.
//

#import "DestinationsViewController.h"
#import "DestinationViewController.h"
#import "RecordingsViewController.h"
#import "DataManager.h"
#import "Common.h"
#import "Settings.h"
#import "DestinationData.h"
#import "Strings.h"
#import "PhoneData.h"
#import "WebClient.h"
#import "PurchaseManager.h"


typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionDestinations = 1UL << 0,
    TableSectionRecordings   = 1UL << 1,
};


@interface DestinationsViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedDestinationsController;
@property (nonatomic, assign) TableSections               sections;

@property (nonatomic, strong) NSMutableDictionary*        ratesDictionary;

@end


@implementation DestinationsViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if (self = [super init])
    {
        self.title                = [Strings destinationsString];
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = managedObjectContext;

        self.sections |= TableSectionDestinations;
        //### self.sections |= TableSectionRecordings;

        self.ratesDictionary = [NSMutableDictionary dictionary];
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.fetchedDestinationsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Destination"
                                                                              withSortKeys:@[@"name"]
                                                                      managedObjectContext:self.managedObjectContext];
    self.fetchedDestinationsController.delegate = self;

    // Hide ItemsViewController + button.
    self.navigationItem.rightBarButtonItem = nil;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return self.fetchedDestinationsController.sections.count +  ([Common bitsSetCount:self.sections] - 1);
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 0;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionDestinations: numberOfRows = [self.fetchedDestinationsController.sections[section] numberOfObjects]; break;
        case TableSectionRecordings:   numberOfRows = 1;                                                                      break;
    }

    return numberOfRows;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    switch ([Common nthBitSet:section inValue:self.sections])
    {
        case TableSectionDestinations:
        {
            title = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Title", nil, [NSBundle mainBundle],
                                                      @"Incoming Calls Can Go To",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
            break;
        }
        case TableSectionRecordings:
        {
            title = NSLocalizedStringWithDefaultValue(@"Destinations Recordings Title", nil, [NSBundle mainBundle],
                                                      @"Your Voice Recordings",
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
        case TableSectionDestinations:
        {
            title = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Footer", nil, [NSBundle mainBundle],
                                                      @"List of Destinations where you can receive calls to your "
                                                      @"purchased Numbers. To receive calls, you must assign a "
                                                      @"Destination to your Number.\n\n"
                                                      @"(Currently a Destination simply forwards calls to one of "
                                                      @"your Phones. You can expect more capabilities in coming app "
                                                      @"versions.)",
                                                      @"\n"
                                                      @"[1/4 line larger font].");
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
        case TableSectionDestinations:
        {
            DestinationData* destination = [self.fetchedDestinationsController objectAtIndexPath:indexPath];
            viewController = [[DestinationViewController alloc] initWithDestination:destination
                                                               managedObjectContext:self.managedObjectContext];
            break;
        }
        case TableSectionRecordings:
        {
            viewController = [[RecordingsViewController alloc] init];
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
        case TableSectionDestinations: cell = [self destinationCellForIndexPath:indexPath]; break;
        case TableSectionRecordings:   cell = [self recordingsCellForIndexPath:indexPath];  break;
    }

    return cell;
}


- (UITableViewCell*)destinationCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    DestinationData* destination = [self.fetchedDestinationsController objectAtIndexPath:indexPath];
    cell.textLabel.text          = [destination defaultName];
    cell.accessoryType           = UITableViewCellAccessoryDisclosureIndicator;

    NSNumber* rate = self.ratesDictionary[destination.objectID];
    if (rate == nil)
    {
        UIActivityIndicatorView* spinner = [Common addSpinnerAtDetailTextOfCell:cell];

        __weak typeof(cell) weakCell = cell;
        __weak typeof(self) weakSelf = self;
        NSDictionary* action = [Common objectWithJsonString:destination.action];
        [[WebClient sharedClient] retrieveCallRateForE164:action[@"call"][@"e164s"][0] reply:^(NSError* error, float ratePerMinute)
        {
            [spinner removeFromSuperview];

            if (error == nil)
            {
                NSString* costString = [[PurchaseManager sharedManager] localizedFormattedPrice1ExtraDigit:ratePerMinute];
                costString = [costString stringByAppendingFormat:@"/%@", [Strings shortMinuteString]];

                weakCell.detailTextLabel.textColor = [Skinning priceColor];
                weakCell.detailTextLabel.text      = costString;

                weakSelf.ratesDictionary[destination.objectID] = @(ratePerMinute);
            }
            else
            {
                weakCell.detailTextLabel.text = nil;
            }
        }];
    }
    else
    {
        NSString* costString = [[PurchaseManager sharedManager] localizedFormattedPrice1ExtraDigit:[rate floatValue]];
        costString = [costString stringByAppendingFormat:@"/%@", [Strings shortMinuteString]];

        cell.detailTextLabel.textColor = [Skinning priceColor];
        cell.detailTextLabel.text      = costString;
    }

    return cell;
}


- (UITableViewCell*)recordingsCellForIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:@"RecordingsCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"RecordingsCell"];
    }

    cell.accessoryType  = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [Strings recordingsString];

    [Common setImageNamed:@"RecordingsTab" ofCell:cell];

    return cell;
}


- (void)tableView:(UITableView*)tableView willDisplayCell:(UITableViewCell*)cell forRowAtIndexPath:(NSIndexPath*)indexPath
{
    switch ([Common nthBitSet:indexPath.section inValue:self.sections])
    {
        case TableSectionDestinations:
        {
            [self configureCell:cell onResultsController:self.fetchedDestinationsController atIndexPath:indexPath];
            break;
        }
        case TableSectionRecordings:
        {
            break;
        }
    }
}


// We currently don't allow deleting the Phone based default Destinations. Remove this method to enable editing again.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return NO;
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        DestinationData* destination = [self.fetchedDestinationsController objectAtIndexPath:indexPath];

        [destination deleteWithCompletion:^(BOOL succeeded)
        {
            if (succeeded)
            {
                [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
            }
            else
            {
                [self.tableView setEditing:NO animated:YES];
            }
        }];
    }
}


#pragma mark - Actions

// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController*    modalViewController;
        DestinationViewController* viewController;

        viewController = [[DestinationViewController alloc] initWithDestination:nil
                                                           managedObjectContext:self.managedObjectContext];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
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


#pragma mark - ItemsViewController Overrides/Implementations

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    DestinationData* destination;

    destination = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text = [destination defaultName];
}

@end
