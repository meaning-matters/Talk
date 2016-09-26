//
//  NumberDestinationsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberDestinationsViewController.h"
#import "UIViewController+Common.h"
#import "DataManager.h"
#import "Strings.h"
#import "DestinationData.h"
#import "WebClient.h"
#import "BlockAlertView.h"
#import "Settings.h"
#import "Common.h"


@interface NumberDestinationsViewController ()
{
    NumberData*                 number;
    NSFetchedResultsController* fetchedResultsController;
    UITableViewCell*            selectedCell;
}

@end


@implementation NumberDestinationsViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = [Strings destinationsString];

        number = theNumber;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    fetchedResultsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Destination"
                                                                         withSortKeys:@[@"name"]
                                                                 managedObjectContext:nil];

    UIBarButtonItem* item;
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
                                                         target:self
                                                         action:@selector(deleteAction)];
    item.enabled = (number.destination != nil);
    self.navigationItem.rightBarButtonItem = item;

    if (self.navigationController.viewControllers.count == 1)
    {
        UIBarButtonItem* item;
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                             target:self
                                                             action:@selector(dismissAction)];
        self.navigationItem.leftBarButtonItem = item;
    }

    [self setupFootnotesHandlingOnTableView:self.tableView];
}


#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];

    return [sectionInfo numberOfObjects];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    DestinationData* destination = [fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text  = destination.name;

    if (number.destination == destination)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedCell       = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    if ([self tableView:tableView numberOfRowsInSection:section] > 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Title", nil, [NSBundle mainBundle],
                                                  @"Select where calls must go",
                                                  @"\n"
                                                  @"[1/4 line larger font].");
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    NSString* titleTop    = nil;
    NSString* titleBottom = nil;

    if (self.showFootnotes == NO)
    {
        return nil;
    }

    titleTop = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Footer A", nil, [NSBundle mainBundle],
                                                 @"List of Destinations to receive calls to this Number.",
                                                 @"\n"
                                                 @"[1/4 line larger font].");

    if ([self tableView:tableView numberOfRowsInSection:section] == 0)
    {
        titleBottom = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Footer A", nil, [NSBundle mainBundle],
                                                        @"You can create them from the Destinations tab.",
                                                        @"\n"
                                                        @"[1/4 line larger font].");
    }
    else
    {
        if (number.destination != nil)
        {
            titleBottom = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Footer A", nil, [NSBundle mainBundle],
                                                            @"Tap the delete button to disconnect this Number; you will "
                                                            @"then stop receiving calls, and people calling will hear %@.",
                                                            @"\n"
                                                            @"[1/4 line larger font].");
            titleBottom = [NSString stringWithFormat:titleBottom, [Strings numberDisconnectedToneOrMessageString]];
        }
        else
        {
            titleBottom = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Footer B", nil, [NSBundle mainBundle],
                                                            @"No Destination is selected, which means that this Number "
                                                            @"is disconnected. You won't receive calls, and people "
                                                            @"calling will hear %@.",
                                                            @"\n"
                                                            @"[1/4 line larger font].");
            titleBottom = [NSString stringWithFormat:titleBottom, [Strings numberDisconnectedToneOrMessageString]];
        }
    }

    return [NSString stringWithFormat:@"%@\n\n%@", titleTop, titleBottom];
}


#pragma mark - TableView Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    DestinationData* selectedDestination = [fetchedResultsController objectAtIndexPath:indexPath];
    [self setDestination:selectedDestination atIndexPath:indexPath];
}


- (void)setDestination:(DestinationData*)destination atIndexPath:(NSIndexPath*)indexPath
{
    if (number.destination != destination)
    {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];    // Get here because indexPath is overwritten.

        [[WebClient sharedClient] setDestinationOfE164:number.e164
                                                  uuid:(destination == nil) ? @"" : destination.uuid
                                                 reply:^(NSError* error)
        {
            if (error == nil)
            {
                [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                number.destination = destination;
                [[DataManager sharedManager] saveManagedObjectContext:nil];

                [[AppDelegate appDelegate] updateNumbersBadgeValue];

                selectedCell.accessoryType = UITableViewCellAccessoryNone;
                cell.accessoryType         = UITableViewCellAccessoryCheckmark;

                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

                if (self.navigationController.viewControllers.count == 1)
                {
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
                else
                {
                    [self.navigationController popViewControllerAnimated:YES];
                }
            }
            else
            {
                [Common showSetDestinationError:error completion:^
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }];
            }
        }];
    }
}


#pragma mark - Actions

- (void)deleteAction
{
    [Common checkDisconnectionOfNumber:number completion:^(BOOL canDisconnect)
    {
        if (canDisconnect)
        {
            [self setDestination:nil atIndexPath:nil];

            [[AppDelegate appDelegate] updateNumbersBadgeValue];
        }
    }];
}


- (void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
