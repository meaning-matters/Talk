//
//  PhonesViewController.m
//  Talk
//
//  Created by Cornelis van der Bent on 14/12/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import "PhonesViewController.h"
#import "PhoneViewController.h"
#import "PhoneData.h"
#import "DataManager.h"
#import "Settings.h"
#import "Common.h"
#import "Strings.h"
#import "PhoneNumber.h"
#import "Skinning.h"
#import "BlockAlertView.h"
#import "DestinationData.h"


@interface PhonesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedPhonesController;
@property (nonatomic, strong) PhoneData*                  selectedPhone;
@property (nonatomic, copy) void (^completion)(PhoneData* selectedPhone);
@property (nonatomic, strong) id<NSObject>                defaultsObserver;
@property (nonatomic, assign) BOOL                        hasAddButton;

@end


@implementation PhonesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                                selectedPhone:nil
                                 hasAddButton:YES
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                               selectedPhone:(PhoneData*)selectedPhone
                                hasAddButton:(BOOL)hasAddButton
                                  completion:(void (^)(PhoneData* selectedPhone))completion
{
    if (self = [super init])
    {
        self.title                = [Strings phonesString];
        // The tabBarItem image must be set in my own NavigationController.

        self.managedObjectContext = managedObjectContext;
        self.selectedPhone        = selectedPhone;
        self.hasAddButton         = hasAddButton;
        self.completion           = completion;

        __weak typeof(self) weakSelf = self;
        self.defaultsObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue mainQueue]
                                                                              usingBlock:^(NSNotification* note)
        {
            if ([Settings sharedSettings].haveAccount)
            {
                [weakSelf.tableView reloadData];
            }
        }];
    }

    return self;
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.defaultsObserver];

    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    if (self.hasAddButton == NO)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }

    self.fetchedPhonesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Phone"
                                                                             withSortKeys:[Common sortKeys]
                                                                     managedObjectContext:self.managedObjectContext];
    self.fetchedPhonesController.delegate = self;
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectedPhone != nil)
    {
        NSUInteger index = [self.fetchedPhonesController.fetchedObjects indexOfObject:self.selectedPhone];
        
        if (index != NSNotFound)
        {
            // Needs to run on next run loop or else does not properly scroll to bottom items.
            dispatch_async(dispatch_get_main_queue(), ^
            {
                NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
                [self.tableView scrollToRowAtIndexPath:indexPath
                                      atScrollPosition:UITableViewScrollPositionMiddle
                                              animated:YES];
            });
        }
    }
}


- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
    [[DataManager sharedManager] setSortKeys:[Common sortKeys] ofResultsController:self.fetchedPhonesController];
    [self.tableView reloadData];
}


#pragma mark - Table View Delegates

- (NSInteger)numberOfSectionsInTableView:(UITableView*)tableView
{
    return [[self.fetchedPhonesController sections] count];
}


- (NSInteger)tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([[self.fetchedPhonesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedPhonesController sections] objectAtIndex:section];

        return [sectionInfo numberOfObjects];
    }
    else
    {
        return 0;
    }
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString* title = nil;

    if ([[self.fetchedPhonesController sections] count] > 0)
    {
        if ([self tableView:tableView numberOfRowsInSection:section] > 0)
        {
            if (self.headerTitle == nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                          @"The Phones you use",
                                                          @"\n"
                                                          @"[1/4 line larger font].");
            }
            else
            {
                title = self.headerTitle;
            }
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.showFootnotes == NO)
    {
        return nil;
    }

    if (self.footerTitle == nil)
    {
        return NSLocalizedStringWithDefaultValue(@"Phone Phones List Title", nil, [NSBundle mainBundle],
                                                 @"List of your fixed or mobile phones. You can use any of them as "
                                                 @"your Caller ID, for Callback, and as Destination for receiving "
                                                 @"calls to your "
                                                 @"purchased Numbers.",
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
    PhoneData*           phone = [self.fetchedPhonesController objectAtIndexPath:indexPath];

    if (self.completion == nil)
    {
        viewController = [[PhoneViewController alloc] initWithPhone:phone managedObjectContext:self.managedObjectContext];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if (phone != self.selectedPhone)
        {
            self.completion ? self.completion(phone) : 0;
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

    [self configureCell:cell onResultsController:self.fetchedPhonesController atIndexPath:indexPath];

    return cell;
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        PhoneData* phone = [self.fetchedPhonesController objectAtIndexPath:indexPath];

        [phone deleteWithCompletion:^(BOOL succeeded)
        {
            if (succeeded)
            {
                DestinationData* destination = [[DataManager sharedManager] lookupDestinationWithName:phone.name];
                [destination deleteWithCompletion:^(BOOL succeeded)
                {
                    // TODO: Ignore for now. Similar case in PhoneViewController.
                }];

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
        [Common showGetStartedViewControllerWithAlert];
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
    
    [self addUseButtonsWithPhone:phone toCell:cell];

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


#pragma mark - Helpers

- (void)addUseButtonsWithPhone:(PhoneData*)phone toCell:(UITableViewCell*)cell
{
    BOOL      isCallback   = [phone.e164 isEqualToString:[Settings sharedSettings].callbackE164];
    BOOL      isCallerId   = [phone.e164 isEqualToString:[Settings sharedSettings].callerIdE164];
    NSString* callbackText = NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                               @"CB", @"Abbreviation for Callback");
    NSString* callerIdText = NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                               @"ID", @"Abbreviation for Caller ID");

    for (UIView* subview in cell.subviews)
    {
        if (subview.tag == CommonUseButtonTag)
        {
            [subview removeFromSuperview];
        }
    }

    if (isCallback)
    {
        UIButton* button = [Common addUseButtonWithText:callbackText toCell:cell atPosition:0];
        [button addTarget:[Common class] action:@selector(showCallbackAlert) forControlEvents:UIControlEventTouchUpInside];
    }

    if (isCallerId)
    {
        UIButton* button = [Common addUseButtonWithText:callerIdText toCell:cell atPosition:1];
        [button addTarget:[Common class] action:@selector(showCallerIdAlert) forControlEvents:UIControlEventTouchUpInside];
    }
}

@end
