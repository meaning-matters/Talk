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

const NSInteger kUseButtonTag = 123;


@interface PhonesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedPhonesController;
@property (nonatomic, strong) PhoneData*                  selectedPhone;
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
        
        [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                          object:nil
                                                           queue:[NSOperationQueue mainQueue]
                                                      usingBlock:^(NSNotification* note)
        {
            if ([Settings sharedSettings].haveAccount)
            {
                [self.tableView reloadData];
            }
        }];
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

    // Don't show add button
    if (self.selectedPhone != nil)
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


#pragma mark - Table view data source

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
    if ([[self.fetchedPhonesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedPhonesController sections] objectAtIndex:section];

        if ([sectionInfo numberOfObjects] > 0)
        {
            if (self.headerTitle == nil)
            {
                return NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                         @"The phones you use",
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
                                                 @"List of phone numbers you can use as your Caller ID and/or "
                                                 @"Callback number. Add as many numbers as you wish, as it "
                                                 @"can be useful to maintain a healthy list from which to choose.",
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

    [self configureCell:cell onResultsController:self.fetchedPhonesController atIndexPath:indexPath];

    return cell;
}


- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    PhoneData*    phone    = [self.fetchedPhonesController objectAtIndexPath:indexPath];
    CallableData* callable = phone;
    
    return [phone.e164 isEqualToString:[Settings sharedSettings].callbackE164] == NO &&
           [phone.e164 isEqualToString:[Settings sharedSettings].callerIdE164] == NO &&
           phone.destinations.count == 0 &&
           callable.callerIds.count == 0;
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        PhoneData* phone = [self.fetchedPhonesController objectAtIndexPath:indexPath];

        [phone deleteFromManagedObjectContext:self.managedObjectContext completion:^(BOOL succeeded)
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
    
    if (self.selectedPhone == nil)
    {
        [self addUseButtonsWithPhone:phone toCell:cell];
    }

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
    CGFloat   fontSize     = cell.detailTextLabel.font.pointSize;
    
    for (UIView* subview in cell.subviews)
    {
        if (subview.tag == kUseButtonTag)
        {
            [subview removeFromSuperview];
        }
    }

    int position = 0;
    
    if (isCallerId)
    {
        UIButton* button = [self addUseButtonWithText:callerIdText fontSize:fontSize toCell:cell atPosition:position++];
        [button addTarget:self action:@selector(showCallerIdAlert) forControlEvents:UIControlEventTouchUpInside];
    }

    if (isCallback)
    {
        UIButton* button = [self addUseButtonWithText:callbackText fontSize:fontSize toCell:cell atPosition:position++];
        [button addTarget:self action:@selector(showCallbackAlert) forControlEvents:UIControlEventTouchUpInside];
    }
}


- (UIButton*)addUseButtonWithText:(NSString*)text
                         fontSize:(CGFloat)fontSize
                           toCell:(UITableViewCell*)cell
                       atPosition:(int)position
{
    CGFloat width    = 27.0f;
    CGFloat height   = 17.0f;
    CGFloat gap      =  6.0f;   // Horizontal gap between buttons.
    CGFloat trailing = 38.0f;   // Space between right most button and right side of cell.
    CGFloat x;
    CGFloat y        = 25.0f;
    
    // Assumes there are at most 2 buttons.
    if (position == 0)
    {
        x = cell.frame.size.width - trailing - width;
    }
    else
    {
        x = cell.frame.size.width - trailing - width - gap - width;
    }
    
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    button.frame           = CGRectMake(x, y, width, height);
    button.tag             = kUseButtonTag;
    button.titleLabel.font = [UIFont systemFontOfSize:fontSize];
    [button setTitle:text forState:UIControlStateNormal];
    [Common styleButton:button];
    
    [cell addSubview:button];
    
    return button;
}


- (void)showCallbackAlert
{
    NSString* title   = NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                          @"Callback Phone", @"...");
    NSString* message = NSLocalizedStringWithDefaultValue(@"Phone ...", nil, [NSBundle mainBundle],
                                                          @"When making a call, you're first being called back on this phone.",
                                                          @"...");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}


- (void)showCallerIdAlert
{
    NSString* title   = NSLocalizedStringWithDefaultValue(@"Phones ...", nil, [NSBundle mainBundle],
                                                          @"Default Caller ID", @"...");
    NSString* message = NSLocalizedStringWithDefaultValue(@"Phone ...", nil, [NSBundle mainBundle],
                                                          @"This caller ID will be used when you did not select "
                                                          @"one for the contact you're calling, or "
                                                          @"when you call using the Keypad.",
                                                          @"...");
    [BlockAlertView showAlertViewWithTitle:title
                                   message:message
                                completion:nil
                         cancelButtonTitle:[Strings closeString]
                         otherButtonTitles:nil];
}

@end
