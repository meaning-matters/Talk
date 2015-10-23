//
//  NumberForwardingsViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 15/09/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "NumberForwardingsViewController.h"
#import "DataManager.h"
#import "Strings.h"
#import "ForwardingData.h"
#import "WebClient.h"
#import "BlockAlertView.h"


@interface NumberForwardingsViewController ()
{
    NumberData*                 number;
    NSFetchedResultsController* fetchedResultsController;
    UITableViewCell*            selectedCell;
}

@end


@implementation NumberForwardingsViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.title = [Strings forwardingsString];

        number = theNumber;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    fetchedResultsController = [[DataManager sharedManager] fetchResultsForEntityName:@"Forwarding"
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

        if (number.forwarding == nil)
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
        ForwardingData* forwarding = [fetchedResultsController objectAtIndexPath:indexPath];
        cell.textLabel.text  = forwarding.name;
        cell.imageView.image = [UIImage imageNamed:@"List"];

        if (number.forwarding == forwarding)
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
    ForwardingData*  selectedForwarding;
    UITableViewCell* cell = [tableView cellForRowAtIndexPath:indexPath];    // Get here because indexPath is overwritten.

    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row == 0)
    {
        selectedForwarding = nil;
    }
    else
    {
        indexPath = [NSIndexPath indexPathForRow:(indexPath.row - 1) inSection:indexPath.section];
        selectedForwarding = [fetchedResultsController objectAtIndexPath:indexPath];
    }

    if (number.forwarding != selectedForwarding)
    {
        [[WebClient sharedClient] setIvrOfE164:number.e164
                                          uuid:(selectedForwarding == nil) ? @"" : selectedForwarding.uuid
                                         reply:^(NSError* error)
        {
            if (error == nil)
            {
                number.forwarding = selectedForwarding;
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

                title   = NSLocalizedStringWithDefaultValue(@"NumberForwardings SetForwardingFailedTitle", nil,
                                                            [NSBundle mainBundle], @"Setting Forwarding Failed",
                                                            @"Alert title: ....\n"
                                                            @"[iOS alert title size].");
                message = NSLocalizedStringWithDefaultValue(@"BuyCredit SetForwardingFailedMessage", nil,
                                                            [NSBundle mainBundle],
                                                            @"Something went wrong while setting the Forwarding: "
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
