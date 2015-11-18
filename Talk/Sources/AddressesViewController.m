//
//  AddressesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 16/11/15.
//  Copyright © 2015 NumberBay Ltd. All rights reserved.
//

#import "AddressesViewController.h"
#import "AddressViewController.h"
#import "DataManager.h"
#import "Strings.h"
#import "Settings.h"
#import "AppDelegate.h"
#import "Common.h"


@interface AddressesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedAddressesController;
@property (nonatomic, strong) AddressData*                selectedAddress;
@property (nonatomic, copy) void (^completion)(AddressData* selectedAddress);

@end


@implementation AddressesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                              selectedAddress:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedAddress:(AddressData*)selectedAddress
                                  completion:(void (^)(AddressData* selectedAddress))completion;
{
    if (self = [super init])
    {
        self.title                = [Strings addressesString];
        // The tabBarItem image must be set in my own NavigationController.
        
        self.managedObjectContext = managedObjectContext;
        self.selectedAddress      = selectedAddress;
        self.completion           = completion;
    }
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Don't show add button
    if (self.selectedAddress != nil)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    
    self.fetchedAddressesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Address"
                                                                                withSortKeys:@[@"isoCountryCode",
                                                                                               @"salutation"]
                                                                        managedObjectContext:self.managedObjectContext];
    self.fetchedAddressesController.delegate = self;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedAddressesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedAddressesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedAddressesController sections] objectAtIndex:section];
        
        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[self.fetchedAddressesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedAddressesController sections] objectAtIndex:section];
        
        if ([sectionInfo numberOfObjects] > 0)
        {
            if (self.headerTitle == nil)
            {
                return NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                         @"Addresses to registers your Numbers",
                                                         @"\n"
                                                         @"[1/4 line larger font].");
            }
            else
            {
                return self.headerTitle;
            }
        }
        else
        {
            return nil;
        }
    }
    else
    {
        return nil;
    }
}


- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.footerTitle == nil)
    {
        return NSLocalizedStringWithDefaultValue(@"Addresses List Title", nil, [NSBundle mainBundle],
                                                 @"List of addresses ....",
                                                 @"\n"
                                                 @"[ ].");
    }
    else
    {
        return self.footerTitle;
    }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    AddressViewController* viewController;
    AddressData*           address = [self.fetchedAddressesController objectAtIndexPath:indexPath];
    
    if (self.completion == nil)
    {
        viewController = [[AddressViewController alloc] initWithAddress:address managedObjectContext:self.managedObjectContext];
        
        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if (address != self.selectedAddress)
        {
            self.completion(address);
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
    
    [self configureCell:cell onResultsController:self.fetchedAddressesController atIndexPath:indexPath];
    
    return cell;
}


- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddressData* address = [self.fetchedAddressesController objectAtIndexPath:indexPath];
    
    return NO;//######
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        AddressData* address = [self.fetchedAddressesController objectAtIndexPath:indexPath];
        
        [address deleteFromManagedObjectContext:self.managedObjectContext completion:^(BOOL succeeded)
        {
            [[DataManager sharedManager] saveManagedObjectContext:self.managedObjectContext];
        }];
    }
}


#pragma mark - Actions

// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
    {
        UINavigationController* modalViewController;
        AddressViewController*  viewController;
        
        viewController = [[AddressViewController alloc] initWithAddress:nil managedObjectContext:self.managedObjectContext];
        
        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [AppDelegate.appDelegate.tabBarController presentViewController:modalViewController
                                                               animated:YES
                                                             completion:nil];
    }
    else
    {
        [Common showGetStartedViewController];
    }
}


#pragma mark - Override of ItemsViewController.

- (UITableView*)tableViewForResultsController:(NSFetchedResultsController*)controller
{
    return self.tableView;
}


- (void)configureCell:(UITableViewCell*)cell
  onResultsController:(NSFetchedResultsController*)controller
          atIndexPath:(NSIndexPath*)indexPath
{
    AddressData* address      = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text       = address.isoCountryCode;
    cell.detailTextLabel.text = address.salutation;
    cell.imageView.image      = [UIImage imageNamed:address.isoCountryCode];
    
    if (self.completion == nil)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (address == self.selectedAddress)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
