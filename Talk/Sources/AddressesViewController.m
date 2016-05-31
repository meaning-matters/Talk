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
#import "Common.h"
#import "WebClient.h"
#import "Salutation.h"
#import "CellDotView.h"
#import "AddressUpdatesHandler.h"


@interface AddressesViewController ()

@property (nonatomic, strong) NSFetchedResultsController* fetchedAddressesController;
@property (nonatomic, strong) AddressData*                selectedAddress;
@property (nonatomic, assign) BOOL                        isFiltered;

@property (nonatomic, strong) NSString*                   isoCountryCode;
@property (nonatomic, strong) NSString*                   areaCode;
@property (nonatomic, assign) NumberTypeMask              numberTypeMask;
@property (nonatomic, assign) AddressTypeMask             addressTypeMask;
@property (nonatomic, strong) NSDictionary*               proofTypes;

@property (nonatomic, copy) void (^completion)(AddressData* selectedAddress);

@property (nonatomic, strong) NSPredicate*                predicate;

@property (nonatomic, weak) id<NSObject>                  observer;

@end


@implementation AddressesViewController

- (instancetype)init
{
    return [self initWithManagedObjectContext:[DataManager sharedManager].managedObjectContext
                              selectedAddress:nil
                               isoCountryCode:nil
                                     areaCode:nil
                                   numberType:NumberTypeGeographicMask
                                  addressType:0
                                   proofTypes:nil
                                    predicate:nil
                                   completion:nil];
}


- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext*)managedObjectContext
                             selectedAddress:(AddressData*)selectedAddress
                              isoCountryCode:(NSString*)isoCountryCode
                                    areaCode:(NSString*)areaCode
                                  numberType:(NumberTypeMask)numberTypeMask
                                 addressType:(AddressTypeMask)addressTypeMask
                                  proofTypes:(NSDictionary*)proofTypes
                                   predicate:(NSPredicate*)predicate
                                  completion:(void (^)(AddressData* selectedAddress))completion
{
    if (self = [super init])
    {
        self.title                = (predicate == nil) ? [Strings addressesString] : [Strings addressString];

        self.isFiltered           = (isoCountryCode != nil);
        
        self.managedObjectContext = managedObjectContext;
        self.selectedAddress      = selectedAddress;
        self.isoCountryCode       = isoCountryCode;
        self.areaCode             = areaCode;
        self.numberTypeMask       = numberTypeMask;
        self.addressTypeMask      = addressTypeMask;
        self.proofTypes           = proofTypes;
        self.predicate            = predicate;
        self.completion           = completion;

        __weak typeof(self) weakSelf = self;
        self.observer = [[NSNotificationCenter defaultCenter] addObserverForName:AddressUpdatesNotification
                                                                          object:nil
                                                                           queue:[NSOperationQueue mainQueue]
                                                                      usingBlock:^(NSNotification* note)
        {
            [weakSelf.tableView reloadData];
        }];
    }
    
    return self;
}


- (void)dealloc
{
    [[Settings sharedSettings] removeObserver:self forKeyPath:@"sortSegment" context:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self.observer];
}


- (void)loadData
{
    if (self.predicate != nil)
    {
        self.fetchedAddressesController.fetchRequest.predicate = self.predicate;
    }

    [self.fetchedAddressesController performFetch:nil];
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.fetchedAddressesController = [[DataManager sharedManager] fetchResultsForEntityName:@"Address"
                                                                                withSortKeys:[self sortKeys]
                                                                        managedObjectContext:self.managedObjectContext];
    
    // Don't show add button
    if (self.isFiltered == NO)
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        [self loadData];
    }
    
    self.fetchedAddressesController.delegate = self;
    
    [[Settings sharedSettings] addObserver:self
                                forKeyPath:@"sortSegment"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.selectedAddress != nil)
    {
        NSUInteger index = [self.fetchedAddressesController.fetchedObjects indexOfObject:self.selectedAddress];
        
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
    [[DataManager sharedManager] setSortKeys:[self sortKeys] ofResultsController:self.fetchedAddressesController];
    [self.tableView reloadData];
}


#pragma mark - Public

+ (void)loadAddressesPredicateWithAddressType:(AddressTypeMask)addressTypeMask
                               isoCountryCode:(NSString*)isoCountryCode
                                     areaCode:(NSString*)areaCode
                                   numberType:(NumberTypeMask)numberTypeMask
                                   completion:(void (^)(NSPredicate* predicate, NSError* error))completion
{
    switch (addressTypeMask)
    {
        case AddressTypeNoneMask:      isoCountryCode = nil; areaCode = nil; numberTypeMask = 0; break;
        case AddressTypeWorldwideMask: isoCountryCode = nil; areaCode = nil; numberTypeMask = 0; break;
        case AddressTypeNationalMask:                        areaCode = nil;                     break;
        case AddressTypeLocalMask:                                           numberTypeMask = 0; break;
    }

    [[WebClient sharedClient] retrieveAddressesForIsoCountryCode:isoCountryCode
                                                        areaCode:areaCode
                                                      numberType:numberTypeMask
                                                           reply:^(NSError *error, NSArray *addressIds)
    {
        NSPredicate* predicate = (error == nil) ? [NSPredicate predicateWithFormat:@"addressId IN %@", addressIds] : nil;

        completion ? completion(predicate, error) : 0;
    }];
}


#pragma mark - Table View Delegates

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
    NSString* title = nil;

    if ([[self.fetchedAddressesController sections] count] > 0)
    {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedAddressesController sections] objectAtIndex:section];
        
        if ([sectionInfo numberOfObjects] > 0)
        {
            if (self.predicate == nil)
            {
                title = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                          @"Your Registered Addresses",
                                                          @"\n"
                                                          @"[1/4 line larger font].");
            }
            else
            {
                title = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                          @"Select Address",
                                                          @"[1/4 line larger font].");
            }
        }
    }

    return title;
}


- (NSString*)tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
    if (self.predicate == nil)
    {
        return NSLocalizedStringWithDefaultValue(@"Addresses List Title", nil, [NSBundle mainBundle],
                                                 @"In some countries an address is required for "
                                                 @"using (certain types of) Numbers.",
                                                 @"\n"
                                                 @"[ ].");
    }
    else
    {
        NSString* title;
        NSString* text;

        if ([self isAddressRequired])
        {
            title = NSLocalizedStringWithDefaultValue(@"Addresses List ...", nil, [NSBundle mainBundle],
                                                      @"For %@ Numbers in this country, supplying "
                                                      @"a name plus address is legally required.",
                                                      @"....");
        }
        else
        {
            title = NSLocalizedStringWithDefaultValue(@"Addresses List ...", nil, [NSBundle mainBundle],
                                                      @"For %@ Numbers in this country, supplying "
                                                      @"a name plus address is optional.",
                                                      @"....");
        }

        switch (self.addressTypeMask)
        {
            case AddressTypeNoneMask:
            {
                // Address is optional.
                text  = NSLocalizedStringWithDefaultValue(@"Addresses List TitleWorldwide", nil, [NSBundle mainBundle],
                                                          @"The address can be anywhere in the world.",
                                                          @"....");
                break;
            }
            case AddressTypeWorldwideMask:
            {
                text  = NSLocalizedStringWithDefaultValue(@"Addresses List TitleWorldwide", nil, [NSBundle mainBundle],
                                                          @"The address can be anywhere in the world.",
                                                          @"....");
                break;
            }
            case AddressTypeNationalMask:
            {
                text  = NSLocalizedStringWithDefaultValue(@"Addresses List TitleNational", nil, [NSBundle mainBundle],
                                                          @"The address must be in the same country.",
                                                          @"....");
                break;
            }
            case AddressTypeLocalMask:
            {
                text  = NSLocalizedStringWithDefaultValue(@"Addresses List TitleLocal", nil, [NSBundle mainBundle],
                                                          @"The address must be in the same area.",
                                                          @"....");
                break;
            }
        }

        NSString* numberType = [[NumberType stringForNumberTypeMask:self.numberTypeMask] lowercaseString];
        title = [title stringByAppendingFormat:@" %@", text];
        title = [NSString stringWithFormat:title, numberType];
        title = [title stringByAppendingString:@"\n\n"];

        NSArray* addresses    = [[DataManager sharedManager] fetchEntitiesWithName:@"Address"
                                                                          sortKeys:nil
                                                                         predicate:nil
                                                              managedObjectContext:self.managedObjectContext];
        NSUInteger totalCount = addresses.count;
        NSUInteger matchCount = [self tableView:self.tableView numberOfRowsInSection:0];

        if (totalCount == 0)
        {
            // The user has no addresses.
            text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                      @"You don't have an address available yet. Tap + to "
                                                      @"add an address.",
                                                      @"[1/4 line larger font].");
            title = [title stringByAppendingString:text];
        }
        else
        {
            if (matchCount == 0)
            {
                // The user has addresses, but none of them match.
                if (totalCount == 1)
                {
                    text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                              @"Your address does not match the requirements for "
                                                              @"this Number. Tap + to add a new address.",
                                                              @"[1/4 line larger font].");
                    title = [title stringByAppendingString:text];
                }
                else
                {
                    text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                              @"None of your %d addresses match the requirements for "
                                                              @"this Number. Tap + to add a new address.",
                                                              @"[1/4 line larger font].");
                    title = [title stringByAppendingFormat:text, totalCount];
                }
            }
            else
            {
                if (matchCount == totalCount)
                {
                    // The user has addresses and all of them match.
                    if (totalCount == 1)
                    {
                        text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                                  @"Your address matches the requirements for this "
                                                                  @"Number. Select it, or tap + to add a new address.",
                                                                  @"[1/4 line larger font].");
                        title = [title stringByAppendingString:text];
                    }
                    else
                    {
                        text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                                  @"All your %d addresses match the requirements for "
                                                                  @"this Number. Select one of them, or tap + to "
                                                                  @"add a new address.",
                                                                  @"[1/4 line larger font].");
                        title = [title stringByAppendingFormat:text, totalCount];
                    }
                }
                else
                {
                    // The user has addresses but only a few match.
                    if (matchCount == 1)
                    {
                        text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                                  @"One of your %d addresses matches the requirements "
                                                                  @"for this Number. Select it, or tap + to "
                                                                  @"add a new address.",
                                                                  @"[1/4 line larger font].");
                        title = [title stringByAppendingFormat:text, totalCount];
                    }
                    else
                    {
                        text  = NSLocalizedStringWithDefaultValue(@"Addresses ...", nil, [NSBundle mainBundle],
                                                                  @"%d of your %d addresses match the requirements "
                                                                  @"for this Number. Select it, or tap + to "
                                                                  @"add a new address.",
                                                                  @"[1/4 line larger font].");
                        title = [title stringByAppendingFormat:text, matchCount, totalCount];
                    }
                }
            }
        }

        return title;
    }
}


- (void)tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
    AddressViewController* viewController;
    AddressData*           address = [self.fetchedAddressesController objectAtIndexPath:indexPath];
    
    if (self.completion == nil)
    {
        viewController = [[AddressViewController alloc] initWithAddress:address
                                                   managedObjectContext:self.managedObjectContext
                                                            addressType:0
                                                         isoCountryCode:nil
                                                               areaCode:nil
                                                             numberType:NumberTypeGeographicMask
                                                             proofTypes:nil
                                                             completion:nil];
        
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
        CellDotView* dotView = [[CellDotView alloc] init];
        [dotView addToCell:cell];
    }
    
    [self configureCell:cell onResultsController:self.fetchedAddressesController atIndexPath:indexPath];
    
    return cell;
}


- (BOOL)tableView:(UITableView*)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    AddressData* address = [self.fetchedAddressesController objectAtIndexPath:indexPath];

    return address.numbers.count == 0;
}


- (void)tableView:(UITableView*)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        AddressData* address = [self.fetchedAddressesController objectAtIndexPath:indexPath];
        
        [address deleteWithCompletion:^(BOOL succeeded)
        {
            if (succeeded)
            {
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
        AddressViewController*  viewController;
        
        viewController = [[AddressViewController alloc] initWithAddress:nil
                                                   managedObjectContext:self.managedObjectContext
                                                            addressType:self.addressTypeMask
                                                         isoCountryCode:self.isoCountryCode
                                                               areaCode:self.areaCode
                                                             numberType:self.numberTypeMask
                                                             proofTypes:self.proofTypes
                                                             completion:^(AddressData *address)
        {
            if (address != nil)
            {
                self.isLoading = YES;
                [AddressesViewController loadAddressesPredicateWithAddressType:self.addressTypeMask
                                                                isoCountryCode:self.isoCountryCode
                                                                      areaCode:self.areaCode
                                                                    numberType:self.numberTypeMask
                                                                    completion:^(NSPredicate *predicate, NSError *error)
                {
                    self.isLoading = NO;
                    if (error == nil)
                    {
                        self.predicate = predicate;
                        self.fetchedAddressesController.fetchRequest.predicate = self.predicate;
                        [self.fetchedAddressesController performFetch:nil];

                        NSRange     range    = NSMakeRange(0, [self numberOfSectionsInTableView:self.tableView]);
                        NSIndexSet* sections = [NSIndexSet indexSetWithIndexesInRange:range];
                        [self.tableView reloadSections:sections withRowAnimation:UITableViewRowAnimationAutomatic];
                    }
                }];
            }
        }];
        
        modalViewController = [[UINavigationController alloc] initWithRootViewController:viewController];
        modalViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        
        [self presentViewController:modalViewController
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
    cell.textLabel.text       = address.name;
    cell.detailTextLabel.text = [self detailTextForAddress:address];
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

    CellDotView* dotView = [CellDotView getFromCell:cell];
    dotView.hidden = ([[AddressUpdatesHandler sharedHandler] addressUpdateWithId:address.addressId] == nil);
}


#pragma mark - Helpers

- (BOOL)isAddressRequired
{
    return (self.addressTypeMask != AddressTypeNoneMask);
}


- (NSString*)detailTextForAddress:(AddressData*)address
{
    NSString* detailText   = nil;
    Salutation* salutation = [[Salutation alloc] initWithString:address.salutation];

    switch (salutation.value)
    {
        case SalutationValueMs:
        case SalutationValueMr:
        {
            //### The order of the name elements needs to properly localized.
            detailText = [NSString stringWithFormat:@"%@ %@ %@",
                                                    salutation.localizedString,
                                                    address.firstName,
                                                    address.lastName];
            break;
        }
        case SalutationValueCompany:
        {
            detailText = address.companyName;
            break;
        }
    }

    return detailText;
}


- (NSArray*)sortKeys
{
    if ([Settings sharedSettings].sortSegment == 0)
    {
        return @[@"isoCountryCode", @"name"];
    }
    else
    {
        return @[@"name", @"isoCountryCode"];
    }
}

@end
