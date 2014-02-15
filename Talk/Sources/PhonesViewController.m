//
//  PhonesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 Cornelis van der Bent. All rights reserved.
//

#import "PhonesViewController.h"
#import "PhoneViewController.h"
#import "PhoneData.h"
#import "DataManager.h"
#import "Settings.h"
#import "Common.h"
#import "Strings.h"
#import "PhoneNumber.h"
#import "ForwardingData.h"


@interface PhonesViewController ()
{
    NSFetchedResultsController* fetchedPhonesController;
}

@property (nonatomic, strong) ForwardingData*         forwarding;
@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) NSIndexPath*            selectedIndexPath;

@end


@implementation PhonesViewController

- (instancetype)init
{
    if (self = [super initWithStyle:UITableViewStylePlain])
    {
        self.title            = [Strings phonesString];
        self.tabBarItem.image = [UIImage imageNamed:@"PhonesTab.png"];
    }

    return self;
}


- (instancetype)initWithForwarding:(ForwardingData*)forwarding
              managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    if ([self init])
    {
        self.forwarding           = forwarding;
        self.managedObjectContext = managedObjectContext;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.clearsSelectionOnViewWillAppear = YES;

    NSError* error;
    fetchedPhonesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Phone"
                                                                        withSortKeys:@[@"name"]
                                                                managedObjectContext:self.managedObjectContext
                                                                               error:&error];
    if (fetchedPhonesController != nil)
    {
        fetchedPhonesController.delegate = self;
    }
    else
    {
        NSLog(@"//### Error: %@", error.localizedDescription);
    }

    UIRefreshControl* refreshControl = [[UIRefreshControl alloc] init];
    refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:[Strings synchronizeWithServerString]];
    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    self.refreshControl = refreshControl;

    UIBarButtonItem* rightItem;
    rightItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                              target:self
                                                              action:@selector(addPhoneAction)];
    self.navigationItem.rightBarButtonItem = rightItem;
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


}


#pragma mark - Results Controller Delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView beginUpdates];
}


- (void)controller:(NSFetchedResultsController*)controller
  didChangeSection:(id<NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex
     forChangeType:(NSFetchedResultsChangeType)type
{
    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex]
                          withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (void)controller:(NSFetchedResultsController*)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath*)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath*)newIndexPath
{
    UITableView* tableView = self.tableView;

    switch (type)
    {
        case NSFetchedResultsChangeInsert:
        {
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeDelete:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
        case NSFetchedResultsChangeUpdate:
        {
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
        }
        case NSFetchedResultsChangeMove:
        {
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath]
                             withRowAnimation:UITableViewRowAnimationFade];
            break;
        }
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [self.tableView endUpdates];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[fetchedPhonesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[fetchedPhonesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhonesController sections] objectAtIndex:section];

        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    PhoneViewController* viewController;
    PhoneData*           phone = [fetchedPhonesController objectAtIndexPath:indexPath];

    if (self.forwarding == nil)
    {
        viewController = [[PhoneViewController alloc] initWithPhone:phone managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if ([self.forwarding.phones containsObject:phone] == NO)
        {
            if (self.selectedIndexPath != nil)
            {
                [self.forwarding removePhones:[NSSet setWithSet:self.forwarding.phones]];

                [self.tableView reloadRowsAtIndexPaths:@[self.selectedIndexPath]
                                      withRowAnimation:YES];
            }

            self.selectedIndexPath = indexPath;
            [self.forwarding addPhonesObject:phone];
        }

        [self.navigationController popViewControllerAnimated:YES];
    }
}


- (UITableViewCell*)tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
    UITableViewCell* cell;

    cell = [self.tableView dequeueReusableCellWithIdentifier:@"SubtitleCell"];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"SubtitleCell"];
    }

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}


#pragma mark - Actions

- (void)addPhoneAction
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        UINavigationController* modalViewController;
        PhoneViewController*    viewController;

        viewController = [[PhoneViewController alloc] initWithPhone:nil managedObjectContext:self.managedObjectContext];

        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showProvisioningViewController];
    }
}


#pragma Helpers

- (void)configureCell:(UITableViewCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    PhoneData* phone                = [fetchedPhonesController objectAtIndexPath:indexPath];
    cell.textLabel.text             = phone.name;
    PhoneNumber* phoneNumber        = [[PhoneNumber alloc] initWithNumber:phone.e164];
    cell.detailTextLabel.text       = [phoneNumber internationalFormat];
    cell.imageView.image            = [UIImage imageNamed:[phoneNumber isoCountryCode]];
    cell.imageView.highlightedImage = [Common invertImage:cell.imageView.image];

    if (self.forwarding == nil)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if ([self.forwarding.phones containsObject:phone] == YES)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;

        self.selectedIndexPath = indexPath;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}


- (void)refresh:(id)sender
{
    if ([Settings sharedSettings].haveVerifiedAccount == YES)
    {
        [[DataManager sharedManager] synchronizePhones:^(NSError* error)
        {
            [sender endRefreshing];

            if (error == nil)
            {
                //### Need some fetch data here like in NumbersVC?
            }
        }];
    }
    else
    {
        [sender endRefreshing];
    }
}

@end
