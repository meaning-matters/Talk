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
#import "PhoneData.h"
#import "PurchaseManager.h"
#import "BlockActionSheet.h"


@interface NumberDestinationsViewController ()
{
    NumberData*                 number;
    NSFetchedResultsController* fetchedResultsController;
    UITableViewCell*            selectedCell;
}

@property (nonatomic, strong) NSMutableDictionary* ratesDictionary;

@end


@implementation NumberDestinationsViewController

- (instancetype)initWithNumber:(NumberData*)theNumber
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title = [Strings destinationString];

        number = theNumber;

        self.ratesDictionary = [NSMutableDictionary dictionary];
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

    // TODO: Check if there are Phones for each Destination and if not correct.

    return [sectionInfo numberOfObjects];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    DestinationData* destination = [fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = [destination defaultName];

    if (number.destination == destination)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        selectedCell       = cell;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

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


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    if ([self tableView:tableView numberOfRowsInSection:section] > 0)
    {
        title = NSLocalizedStringWithDefaultValue(@"Destinations Destinations List Title", nil, [NSBundle mainBundle],
                                                  @"Where to forward your calls",
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
                                                            @"stop receiving calls, and people calling will hear %@.",
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

        [[WebClient sharedClient] updateNumberWithUuid:number.uuid
                                                  name:nil
                                             autoRenew:number.autoRenew
                                       destinationUuid:(destination == nil) ? @"" : destination.uuid
                                           addressUuid:nil
                                                 reply:^(NSError*  error,
                                                         NSString* e164,
                                                         NSDate*   purchaseDate,
                                                         NSDate*   expiryDate,
                                                         float     monthFee,
                                                         float     renewFee)
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

                [self closeViewController];
            }
            else
            {
                [Common showSetDestinationError:error completion:^
                {
                    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

                    [self closeViewController];
                }];
            }
        }];
    }
    else
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (void)closeViewController
{
    if (self.navigationController.viewControllers.count == 1)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark - Actions

- (void)deleteAction
{
    [Common checkDisconnectionOfNumber:number completion:^(BOOL canDisconnect)
    {
        if (canDisconnect)
        {
            NSString* title = NSLocalizedString(@"Stop receiving calls on this Number. People calling will hear %@.", @"\n");
            title = [NSString stringWithFormat:title, [Strings numberDisconnectedToneOrMessageString]];

            NSString* buttonTitle = NSLocalizedStringWithDefaultValue(@"DestinationView DeleteTitle", nil,
                                                                      [NSBundle mainBundle], @"Disconnect Number",
                                                                      @"...\n"
                                                                      @"[1/3 line small font].");

            [BlockActionSheet showActionSheetWithTitle:title
                                            completion:^(BOOL cancelled, BOOL destruct, NSInteger buttonIndex)
            {
                if (destruct == YES)
                {
                    [self setDestination:nil atIndexPath:nil];

                    [[AppDelegate appDelegate] updateNumbersBadgeValue];
                }
            }
                                     cancelButtonTitle:[Strings cancelString]
                                destructiveButtonTitle:buttonTitle
                                     otherButtonTitles:nil];
        }
    }];
}


- (void)dismissAction
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
