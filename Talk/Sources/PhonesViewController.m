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


@interface PhonesViewController ()
{
    NSFetchedResultsController* fetchedPhonesController;
}

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) PhoneData*              selectedPhone;
@property (nonatomic, copy) void (^completion)(PhoneData* selectedPhone);

@end


@implementation PhonesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                                selectedPhone:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                               selectedPhone:(PhoneData*)selectedPhone
                                  completion:(void (^)(PhoneData* selectedPhone))completion
{
    if (self = [super init])
    {
        self.title                = [Strings phonesString];
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = managedObjectContext;
        self.selectedPhone        = selectedPhone;
        self.completion           = completion;
    }

    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    fetchedPhonesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Phone"
                                                                        withSortKeys:@[@"name"]
                                                                managedObjectContext:self.managedObjectContext];
    fetchedPhonesController.delegate = self;
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


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    if ([[fetchedPhonesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhonesController sections] objectAtIndex:section];

        if ([sectionInfo numberOfObjects] > 0)
        {
            if (self.headerTitle == nil)
            {
                return NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                         @"Use as Caller ID & Callback number",
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
        return NSLocalizedStringWithDefaultValue(@"Phone Phones List Title", nil, [NSBundle mainBundle],
                                                 @"List of phone numbers from which you select (on the Settings tab) "
                                                 @"your caller ID, and the number you'll be called back on.\n\n"
                                                 @"Add as many as you like. It can be handy to have an extensive "
                                                 @"list of caller IDs available.",
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
    PhoneViewController* viewController;
    PhoneData*           phone = [fetchedPhonesController objectAtIndexPath:indexPath];

    if (self.completion == nil)
    {
        viewController = [[PhoneViewController alloc] initWithPhone:phone managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if (phone != self.selectedPhone)
        {
            self.completion(phone);
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

    [self configureCell:cell onResultsController:fetchedPhonesController atIndexPath:indexPath];

    return cell;
}


#pragma mark - Actions

// Is called from ItemsViewController (the baseclass).
- (void)addAction
{
    if ([Settings sharedSettings].haveAccount == YES)
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
    PhoneData* phone          = [controller objectAtIndexPath:indexPath];
    cell.textLabel.text       = phone.name;
    PhoneNumber* phoneNumber  = [[PhoneNumber alloc] initWithNumber:phone.e164];
    cell.detailTextLabel.text = [phoneNumber internationalFormat];
    cell.imageView.image      = [UIImage imageNamed:[phoneNumber isoCountryCode]];

    if (self.completion == nil)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (phone == self.selectedPhone)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
