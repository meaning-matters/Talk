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
    if (self = [super initWithStyle:UITableViewStylePlain])
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
}


#pragma mark - TableView Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedResultsController sections] objectAtIndex:section];

    return [sectionInfo numberOfObjects] + 1;
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DefaultCell"];
    }

    if (indexPath.row == 0)
    {
        cell.textLabel.text  = [Strings defaultString];
        cell.imageView.image = [UIImage imageNamed:@"Target"];

        if (number.destination == nil)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            selectedCell       = cell;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    else
    {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
        DestinationData* destination = [fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text  = destination.name;
        cell.imageView.image = [UIImage imageNamed:@"List"];

        if (number.destination == destination)
        {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            selectedCell       = cell;
        }
        else
        {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }

    return cell;
}


#pragma mark - TableView Delegate

- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    DestinationData*  selectedDestination;
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];    // Get here because indexPath is overwritten.

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0)
    {
        selectedDestination = nil;
    }
    else
    {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
        selectedDestination = [fetchedResultsController objectAtIndexPath:indexPath];
    }

    if (number.destination != selectedDestination)
    {
        [[WebClient sharedClient] setIvrOfE164:number.e164
                                          uuid:(selectedDestination == nil) ? @"" : selectedDestination.uuid
                                         reply:^(NSError* error)
        {
            if (error == nil)
            {
                number.destination = selectedDestination;
                [[DataManager sharedManager] saveManagedObjectContext:nil];

                selectedCell.accessoryType = UITableViewCellAccessoryNone;
                cell.accessoryType         = UITableViewCellAccessoryCheckmark;

                [tableView deselectRowAtIndexPath:indexPath animated:YES];

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
                                            completion:nil
                                     cancelButtonTitle:[Strings closeString]
                                     otherButtonTitles:nil];
            }
        }];
    }
}

@end
