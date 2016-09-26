//
//  DestinationNumbersViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 08/04/16.
//  Copyright © 2016 NumberBay Ltd. All rights reserved.
//

#import "DestinationNumbersViewController.h"
#import "NumberData.h"
#import "DataManager.h"
#import "Strings.h"
#import "Settings.h"
#import "Common.h"
#import "DestinationData.h"
#import "WebClient.h"
#import "BlockAlertView.h"


@interface DestinationNumbersViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedNumbersController;
@property (nonatomic, weak) id<NSObject>                  addressesObserver;
@property (nonatomic, weak) id<NSObject>                  defaultsObserver;
@property (nonatomic, strong) DestinationData*            destination;

@end


@implementation DestinationNumbersViewController

- (instancetype)initWithDestination:(DestinationData*)destination;
{
    if (self = [super initWithStyle:UITableViewStyleGrouped])
    {
        self.title       = [Strings numbersString];
        self.destination = destination;
    }

    return self;
}


- (void)dealloc
{
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.fetchedNumbersController = [[DataManager sharedManager] fetchResultsForEntityName:@"Number"
                                                                              withSortKeys:[Common sortKeys]
                                                                      managedObjectContext:nil];

    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [[DataManager sharedManager] setSortKeys:[Common sortKeys] ofResultsController:self.fetchedNumbersController];
    [self.tableView reloadData];
}


#pragma mark - Table Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.fetchedNumbersController.sections[section] numberOfObjects];
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"DefaultCell"];
    }

    NumberData* number        = [self.fetchedNumbersController objectAtIndexPath:indexPath];
    cell.imageView.image      = [UIImage imageNamed:number.isoCountryCode];
    cell.textLabel.text       = number.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:number.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];

    if ([self.destination.numbers containsObject:number])
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    NumberData* number = [self.fetchedNumbersController objectAtIndexPath:indexPath];
    NSString*   uuid   = [self.destination.numbers containsObject:number] ? @"" : self.destination.uuid;

    [[WebClient sharedClient] setDestinationOfE164:number.e164
                                              uuid:uuid
                                             reply:^(NSError* error)
    {
        if (error == nil)
        {
            number.destination = (uuid.length == 0) ? nil : self.destination;
            [[DataManager sharedManager] saveManagedObjectContext:nil];

            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                                  withRowAnimation:UITableViewRowAnimationFade];

            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            [[AppDelegate appDelegate] updateNumbersBadgeValue];
        }
        else
        {
            [Common showSetDestinationError:error completion:^
            {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
        }
    }];
}

@end
