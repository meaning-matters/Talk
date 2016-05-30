//
//  NumberDestinationsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberDestinationsViewController.h"
#import "DataManager.h"
#import "Strings.h"
#import "DestinationData.h"
#import "WebClient.h"
#import "BlockAlertView.h"


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
                                                         target:self action:@selector(deleteAction)];
    self.navigationItem.rightBarButtonItem = item;
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


#pragma mark - TableView Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    DestinationData* selectedDestination = [fetchedResultsController objectAtIndexPath:indexPath];
    [self setDestination:selectedDestination atIndexPath:indexPath];
}


- (void)setDestination:(DestinationData*)destination atIndexPath:(NSIndexPath*)indexPath
{
    if (number.destination != destination)
    {
        UITableViewCell* cell = [self.tableView cellForRowAtIndexPath:indexPath];    // Get here because indexPath is overwritten.

        [[WebClient sharedClient] setIvrOfE164:number.e164
                                          uuid:(destination == nil) ? @"" : destination.uuid
                                         reply:^(NSError* error)
        {
            if (error == nil)
            {
                number.destination = destination;
                [[DataManager sharedManager] saveManagedObjectContext:nil];

                selectedCell.accessoryType = UITableViewCellAccessoryNone;
                cell.accessoryType         = UITableViewCellAccessoryCheckmark;

                [self.tableView deselectRowAtIndexPath:self.tableView.indexPathForSelectedRow animated:YES];

                [self.navigationController popViewControllerAnimated:YES];
            }
            else
            {
                NSString* title;
                NSString* message;

                title   = NSLocalizedStringWithDefaultValue(@"NumberDestinations SetDestinationFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Setting Destination Failed",
                                                            @"Alert title: ....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyCredit SetDestinationFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while setting the Destination: "
                                                            @"%@\n\nPlease try again later.",
                                                            @"Message telling that ... failed\n"
                                                            @"[iOS alert message size]");
                message = [NSString stringWithFormat:message, error.localizedDescription];
                [BlockAlertView showAlertViewWithTitle:title
                                               message:message
                                            completion:^(BOOL cancelled, NSInteger buttonIndex)
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
                }
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    }
}


#pragma mark - Actions

- (void)deleteAction
{
    [self setDestination:nil atIndexPath:nil];
}

@end
