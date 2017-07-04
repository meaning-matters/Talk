//
//  NBPeopleListViewController.m
//  NBAddressBook
//
//  Created by Jasper Siebelink on 6/1/13.
//  Copyright (c) 2013 NumberBay Ltd. All rights reserved.
//

#import <AddressBookUI/AddressBookUI.h>
#import "NBPeopleListViewController.h"
#import "Strings.h"
#import "Settings.h"

@interface NBPeopleListViewController () <ABNewPersonViewControllerDelegate>
{
    dispatch_queue_t         searchQueue;
    UIActivityIndicatorView* searchIndicator;
}
@end


@implementation NBPeopleListViewController

#pragma mark - Life Cycle

- (id)init
{
    if (self = [super initWithNibName:@"NBPeopleListView" bundle:nil])
    {
        self.title = [Strings contactsString];
        // The tabBarItem image must be set in my own NavigationController.

        self.edgesForExtendedLayout = UIRectEdgeNone;

        //The contacts datasource
        contactsDatasource = [NSMutableArray arrayWithCapacity:[SECTION_TITLES count]];

        searchQueue = dispatch_queue_create("Contact Search", DISPATCH_QUEUE_SERIAL);
    }

    return self;
}


- (void)dealloc
{
    [self setRelatedPersonDelegate:nil];
}


- (void)scrollViewDidScroll:(UIScrollView*)scrollView
{
    UITableView *tableView = self.searchDisplayController.searchResultsTableView;

    if (scrollView == tableView)
    {
        if ([tableView contentInset].bottom != 0)
        {
            [tableView setContentInset:UIEdgeInsetsZero];
            [tableView setScrollIndicatorInsets:UIEdgeInsetsZero];
        }
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];

    //Create the table header and label
    self.tableHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, SIZE_CELL_HEIGHT)];
    [self.tableHeader setBackgroundColor:[UIColor colorWithRed:226.0f/255.0f green:231.0f/255.0f blue:237.0f/255.0f alpha:1.0f]];
    self.myNumberLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 0, self.tableHeader.frame.size.width, self.tableHeader.frame.size.height)];
    [self.myNumberLabel setFont:[UIFont systemFontOfSize:17]];
    [self.myNumberLabel setBackgroundColor:[UIColor clearColor]];
    [self.tableHeader addSubview:self.myNumberLabel];
    [self.tableView setTableHeaderView:self.tableHeader];

    // Create add button
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addPressed)]];
    
    //The groups in the system
    groupsManager = [[NBGroupsManager alloc] init];
    
    //Create a footer view showing the number of contacts
    UIView * footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, SIZE_CELL_HEIGHT)];
    numContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, SIZE_CELL_HEIGHT)];
    [numContactsLabel setTextAlignment:NSTextAlignmentCenter];
    [numContactsLabel setBackgroundColor:[UIColor clearColor]];
    [numContactsLabel setTextColor:FONT_COLOR_LIGHT_GREY];
    [numContactsLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [footerView addSubview:numContactsLabel];
    [self.tableView setTableFooterView:footerView];
    
    //Add the no-contacts label (in the rare case there are no contacts.
    noContactsLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 0, 280, 150)];
    [noContactsLabel setTextAlignment:NSTextAlignmentCenter];
    [noContactsLabel setBackgroundColor:[UIColor clearColor]];
    [noContactsLabel setTextColor:FONT_COLOR_LIGHT_GREY];
    [noContactsLabel setFont:[UIFont boldSystemFontOfSize:20]];
    [noContactsLabel setText:NSLocalizedString(@"CNT_LOADING", @"")];
    [noContactsLabel setNumberOfLines:10];
    [self.tableView addSubview:noContactsLabel];

    //Listen for reloads
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doLoad) name:NF_RELOAD_CONTACTS object:nil];

    //Listen for group selection
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doLoad) name:NF_SAVE_GROUPS object:nil];

    // This will remove extra separators from tableview.
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];

    [self doLoad];
}


- (void)doLoad
{
    dispatch_async(searchQueue, ^
    {
        // Added to prevent clashes -> crashes with loading and findContactsHavingNumber by different threads.
        @synchronized (self)
        {
            [self loadContacts];

            self.contactsAreLoaded = YES;
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            [self.tableView reloadData];
        });
    });
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //Deanimate the row if we have one
    if (selectedIndexPath != nil)
    {
        //Call this delayed to fix the deselecting animation glitch of that it deselects two in a row.
        //Caused because not all the cells are rendered at this point yet; might be reused.
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.05f * NSEC_PER_SEC), dispatch_get_main_queue(), ^(void)
        {
            //Deselect the row
            [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
               selectedIndexPath = nil;
        });

    }

#warning - Set the 'own number' here
    //Update your own number
    [self setOwnPhoneNumber:nil];
    
    //Scroll to the top the first time
    int scrollToSectionIndex = -1;
    if ([allContacts count] > 0 && !scrolledToTop)
    {
        scrolledToTop = YES;
        
        //Find the first index with contacts
        for (NSArray * section in contactsDatasource)
        {
            if ([section count] > 0)
            {
                scrollToSectionIndex = (int)[contactsDatasource indexOfObject:section];
                break;
            }
        }
    }

    if (scrollToSectionIndex != - 1)
    {
        // Needs to run on next run loop or else does not properly scroll to bottom items.
        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:0 inSection:scrollToSectionIndex];
            [self.tableView scrollToRowAtIndexPath:indexPath
                                  atScrollPosition:UITableViewScrollPositionTop
                                          animated:NO];
        });
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    //Clean up the previous entry
    if (personViewController != nil)
    {
        [personViewController.view removeFromSuperview];
        [personViewController setContact:nil];
        [personViewController setContactToMergeWith:nil];
        personViewController = nil;
    }

    //Position the no=contacts
    noContactsLabel.center = CGPointMake( self.view.bounds.size.width / 2, (self.view.bounds.size.height / 2) - 53);
}


#pragma mark - Adding Contact

- (void)addPressed
{
    ABNewPersonViewController* viewController = [[ABNewPersonViewController alloc] init];
    viewController.newPersonViewDelegate = self;

    UINavigationController* navigationController;
    navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];

    [self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - ABNewPersonViewControllerDelegate

- (void)newPersonViewController:(ABNewPersonViewController*)newPersonViewController
       didCompleteWithNewPerson:(ABRecordRef)person
{
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - My phone number management
- (void)setOwnPhoneNumber:(NSString*)number
{
    if (number == nil || [number length] == 0)
    {
        //Hide the tableview if there is no number, else show it
        [self.tableView setTableHeaderView:nil];
    }
    //Else set the number
    else
    {
        //Set the text in the label
        NSString * localizedString = NSLocalizedString(@"LBL_OWN_NUMBER", @"");
        NSString * ownNumberString = [NSString stringWithFormat:@"%@ %@", localizedString, number];
        
        //Set the attributed string (my number: <NUMBER> where my number is regular and the number itself is bold)
        NSDictionary * regularAttributes        = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [UIFont systemFontOfSize:18], NSFontAttributeName,
                                                   FONT_COLOR_MY_NUMBER, NSForegroundColorAttributeName, nil];
        NSDictionary * boldAttributes           = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [UIFont boldSystemFontOfSize:18], NSFontAttributeName,
                                                   FONT_COLOR_MY_NUMBER, NSForegroundColorAttributeName,nil];    
        NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:ownNumberString attributes:regularAttributes];
        [attributedText setAttributes:boldAttributes range:NSMakeRange( [localizedString length], [ownNumberString length] - [localizedString length])];
        [self.myNumberLabel setAttributedText:attributedText];
    }    
}


#pragma mark - Loading contacts

- (void)loadContacts
{
    //Get a list of all contacts that are in the selected groups
    ABAddressBookRef addressBook = [[NBAddressBookManager sharedManager] getAddressBook];
    if (addressBook != nil)
    {
        //Display all contacts
        NSMutableArray * contactsInSelectedSources = [NSMutableArray array];
        
        //Update the title to show some or all contacts were selected
        BOOL allGroupsSelected = YES;
        for (NBGroup * group in groupsManager.userGroups)
        {
            if (![group groupSelected])
            {
                allGroupsSelected = NO;
                break;
            }
        }
        
        self.navigationItem.title = NSLocalizedString( allGroupsSelected ? @"CNT_TITLE_ALL" : @"CNT_TITLE", @"");
        
        //Determine the contact selection
        if (allGroupsSelected)
        {
            //All contacts were selected
            [contactsInSelectedSources addObjectsFromArray:(__bridge NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook)];
        }
        else //Load the contacts that are members of the selected groups
        {
            //Collect all the selected ID's
            NSMutableArray * selectedIDs = [NSMutableArray array];
            for (NBGroup * group in groupsManager.userGroups)
            {
                if (group.groupSelected)
                {
                    [selectedIDs addObjectsFromArray:group.memberContacts];
                }
            }
            
            //Convert the IDs to usable ABRecordRefs
            for (NSString * contactRepresentation in selectedIDs)
            {
                ABRecordID recordID = [contactRepresentation intValue];
                ABRecordRef contact = ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], recordID);
                if (contact != nil)
                {
                    if (![contactsInSelectedSources containsObject:(__bridge id)contact])
                    {
                        [contactsInSelectedSources addObject:(__bridge id)contact];
                    }
                }
            }
        }
        
        //Sort the contacts
        CFMutableArrayRef selectedContactsRef = (__bridge CFMutableArrayRef)contactsInSelectedSources;
        CFArraySortValues(selectedContactsRef,
                          CFRangeMake(0, CFArrayGetCount(selectedContactsRef)),
                          (CFComparatorFunction)ABPersonComparePeopleByName,
                          (void*)((intptr_t)ABPersonGetSortOrdering()));
        allContacts = (__bridge NSMutableArray*)selectedContactsRef;

        //Check to see if we are showing section headers
        hasEnoughContactsForSectionTitles = [allContacts count] > 5;

        //Build up a clean datasource
        [contactsDatasource removeAllObjects];
        for (int n = 0; n < SECTION_TITLES.count; n++)
        {
            [contactsDatasource addObject:[NSMutableArray array]];
        }

        // When iterating over `allContacts` crashes the app right after adding a
        // contact with a number that's already in another contact.  Here's a link
        // to why this happens: http://stackoverflow.com/a/9426722/1971013 `allContacts`
        // has more items than ABAddressBookGetPersonCount() returns.
        // To fix this, we iterate differently using ABAddressBookGetPersonCount().
        CFIndex personCount = ABAddressBookGetPersonCount(addressBook);
        for (int i = 0; i < personCount; i++)
        {
            id contactRef = allContacts[i];

            //Get the first character of the contact
            NSString* sortingProperty = [NBContact getSortingProperty:(ABRecordRef)contactRef mustFormatNumber:NO];
            NSString* firstChar = (sortingProperty == nil) ? @"#" : [[sortingProperty substringToIndex:1] uppercaseString];
            
            //Get the array this contact belongs to
            NSUInteger index = [SECTION_TITLES indexOfObject:firstChar];
            if (index == NSNotFound)
            {
                //If we can't place this item, place it in the hash section
                index = [SECTION_TITLES indexOfObject:@"#"];
            }
            
            //Get and store the contact
            [[contactsDatasource objectAtIndex:index] addObject:contactRef];
        }
    }

    dispatch_async(dispatch_get_main_queue(), ^
    {
        if ([allContacts count] > 0)
        {
            [noContactsLabel setHidden:YES];
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
        {
            [noContactsLabel setText:NSLocalizedString(@"CNT_DENIED", @"")];
        }
        else
        {
            [noContactsLabel setText:NSLocalizedString(@"CNT_NO_CONTACTS", @"")];
        }

        //Set the number of contacts in the label
        [numContactsLabel setText:[NSString stringWithFormat:@"%d %@", (int)[allContacts count], NSLocalizedString(@"CNT_TITLE", @"")]];
        [numContactsLabel setHidden:[allContacts count] < 2];
    });
}


#pragma mark - Tableview Delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //Get the ref of the selected person
    ABRecordRef selectedContactRef;
    if (filterEnabled)
    {
        selectedContactRef = (__bridge ABRecordRef)[filteredContacts objectAtIndex:indexPath.row];
    }
    else
    {
        selectedContactRef = (__bridge ABRecordRef)([[contactsDatasource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]);
    }
    
    //If we are only selecting a name, do so
    if (self.amSelectingName)
    {
        [_relatedPersonDelegate relatedPersonSelected:[[NBContact getListRepresentation:selectedContactRef] string]];
        [self setRelatedPersonDelegate:nil];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        //Remember the selected index to change later
        selectedIndexPath = indexPath;
        
        //Load the person view controller
        personViewController = [[NBPersonViewController alloc] init];
        
        //Load the person view controller
        [personViewController setDisplayedPerson:selectedContactRef];
        [personViewController setAllowsActions:NO];

#warning - Set the cell action-delegate
        [personViewController setPersonViewDelegate:nil];

        [self.navigationController pushViewController:personViewController animated:YES];
    }
}


#pragma mark - Table View Data Source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //If we're filtering, just show the contacts
    if (filterEnabled)
    {
        return 1;
    }
    else
    {
        return [SECTION_TITLES count];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //If we're filtering, just show the filtered contacts
    if (filterEnabled)
    {
        return [filteredContacts count];
    }
    else
    {
        //Only return rows if the datasource was loaded
        return [contactsDatasource count] > 0 ? [[contactsDatasource objectAtIndex:section] count] : 0;
    }
}


- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString*       CellIdentifier = @"ContactCell";
    NBPeopleTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[NBPeopleTableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }

    //Set the person's name on the cell
    ABRecordRef contact = nil;
    if (filterEnabled)
    {
        if (indexPath.row < filteredContacts.count) //### Patches crash from out-of-sync/empty `filteredContacts`.
        {
            contact = (__bridge ABRecordRef)[filteredContacts objectAtIndex:indexPath.row];
        }
    }
    else
    {
        if (indexPath.row < [[contactsDatasource objectAtIndex:indexPath.section] count]) //### Patches crash from out-of-sync/empty `contactsDatasource`.
        {
            contact = (__bridge ABRecordRef)([[contactsDatasource objectAtIndex:indexPath.section] objectAtIndex:indexPath.row]);
        }
    }
    
    //Get a representation for this contact in the list
    [cell.textLabel setAttributedText:[NBContact getListRepresentation:contact]];
    
    return cell;
}


#pragma mark - Search Delegate
- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller
{
    filteredContacts = nil;
    searchString = @"";
    filterEnabled = YES;
}


- (void)searchDisplayControllerDidBeginSearch:(UISearchDisplayController*)controller
{
    if (searchIndicator == nil)
    {
        for (UIView* subview in controller.searchBar.subviews)
        {
            for (UITextField* field in subview.subviews)
            {
                if ([field isKindOfClass:[UITextField class]])
                {
                    searchIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                    searchIndicator.center = CGPointMake(field.leftView.bounds.origin.x + field.leftView.bounds.size.width  / 2,
                                                         field.leftView.bounds.origin.y + field.leftView.bounds.size.height / 2);
                    [field.leftView addSubview:searchIndicator];
                }
            }
        }
    }
}


- (void) searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller
{
    searchString = nil;
    filterEnabled = NO;
    [self.tableView reloadData];
}


- (BOOL)searchDisplayController:(UISearchDisplayController*)controller shouldReloadTableForSearchString:(NSString*)searchStringParam
{
    // Show activity indicator, and remove magnifying glass.
    [searchIndicator startAnimating];
    [controller.searchBar setImage:[UIImage new] forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];

    dispatch_async(searchQueue, ^
    {
        if (searchStringParam.length > 0)
        {
            // If we can build on last search' results, use that subset
            if ([searchString length] > 0 &&
                [searchString length] < [searchStringParam length] &&
                [searchString rangeOfString:searchStringParam options:NSCaseInsensitiveSearch].location != 0)
            {
                [self filterArrayUsingKeyword:searchStringParam];
            }
            else
            {
                // We're doing a fresh search, start from the full set of contacts
                filteredContacts = [NSMutableArray arrayWithArray:allContacts];
                [self filterArrayUsingKeyword:searchStringParam];
            }
        }

        // Remember the string for future search-optimalisation
        searchString = searchStringParam;

        dispatch_sync(dispatch_get_main_queue(), ^
        {
            // When searching is slow, the user may have already cancelled when we get here;
            // then the search results table is gone, a reload will crash.
            if (filteredContacts != nil)
            {
                [self.searchDisplayController.searchResultsTableView reloadData];
            }

            // Hide activity indicator, and restore the magnifying glass icon.
            [searchIndicator stopAnimating];
            [controller.searchBar setImage:nil forSearchBarIcon:UISearchBarIconSearch state:UIControlStateNormal];
        });
    });

    return NO;
}


- (void)filterArrayUsingKeyword:(NSString*)keyword
{
    NSCharacterSet* stripSet = [NSCharacterSet characterSetWithCharactersInString:@"()-. \u00a0"];

    [filteredContacts filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings)
    {
        ABRecordRef contact      = (__bridge ABRecordRef)evaluatedObject;
        int32_t     properties[] =
        {
            kABPersonFirstNameProperty,
            kABPersonLastNameProperty,
            kABPersonMiddleNameProperty,
            kABPersonPrefixProperty,
            kABPersonSuffixProperty,
            kABPersonNicknameProperty,
            kABPersonFirstNamePhoneticProperty,
            kABPersonLastNamePhoneticProperty,
            kABPersonMiddleNamePhoneticProperty,
            kABPersonOrganizationProperty,
            kABPersonJobTitleProperty,
            kABPersonDepartmentProperty
        };

        for (int i = 0; i < (sizeof(properties) / sizeof(int32_t)); i++)
        {
            NSString* property = (__bridge NSString*)(ABRecordCopyValue(contact, properties[i]));
            
            if (property != nil && [property rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return YES;
            }
        }
        
        ABMultiValueRef numbers = ABRecordCopyValue(contact, kABPersonPhoneProperty);
        CFIndex count = ABMultiValueGetCount(numbers);
        for (CFIndex i = 0; i < count; i++)
        {
            NSString* number = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(numbers, i));
            number = [[number componentsSeparatedByCharactersInSet:stripSet] componentsJoinedByString:@""];
            if ([number rangeOfString:keyword].location != NSNotFound)
            {
                return YES;
            }
        }

        ABMultiValueRef emails = ABRecordCopyValue(contact, kABPersonEmailProperty);
        count = ABMultiValueGetCount(emails);
        for (int i = 0; i < count; i++)
        {
            NSString* email = (__bridge NSString *)(ABMultiValueCopyValueAtIndex(emails, 0));
            if ([email rangeOfString:keyword options:NSCaseInsensitiveSearch].location != NSNotFound)
            {
                return YES;
            }
        }

        return NO;
    }]];
}


- (void)findContactsHavingNumber:(NSString*)number completion:(void(^)(NSArray* contactIds))completion
{
    if (!self.contactsAreLoaded)
    {
        NBLog(@"### findContactsHavingNumber called before contacts were loaded!");
    }

    // Force viewDidLoad to be called, as this fills the allContacts array.
    self.view.hidden = NO;

    NSCharacterSet* stripSet = [NSCharacterSet characterSetWithCharactersInString:@"+()-. \u00a0"];

    number = [[number componentsSeparatedByCharactersInSet:stripSet] componentsJoinedByString:@""];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^
    {
        NSMutableArray* contacts = [NSMutableArray arrayWithArray:allContacts];

        // The method is sometimes run concurrently, and then gives a EXC_BAD_ACCESS here.
        // By synchronizing it went away.  Apparently ABRecordCopyValue is not re-entrant.
        // http://stackoverflow.com/questions/23118802/exc-bad-access-in-abrecordcopyvalue
        @synchronized(self)
        {
            [contacts filterUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary* bindings)
            {
                ABRecordRef contact = (__bridge ABRecordRef)evaluatedObject;
                
                ABMultiValueRef numberArray;

                numberArray = ABRecordCopyValue(contact, kABPersonPhoneProperty);
                
                CFIndex count = ABMultiValueGetCount(numberArray);
                for (CFIndex i = 0; i < count; i++)
                {
                    NSString* contactNumber = (__bridge NSString*)(ABMultiValueCopyValueAtIndex(numberArray, i));
                    contactNumber = [[contactNumber componentsSeparatedByCharactersInSet:stripSet] componentsJoinedByString:@""];
                    
                    if ([contactNumber hasSuffix:number])
                    {
                        return YES;
                    }
                }
                
                return NO;
            }]];
        }

        dispatch_async(dispatch_get_main_queue(), ^
        {
            NSMutableArray* contactIds = [NSMutableArray array];
            for (id object in contacts)
            {
                ABRecordRef contact   = (__bridge ABRecordRef)object;
                NSString*   contactId = [NSString stringWithFormat:@"%d", ABRecordGetRecordID(contact)];
                [contactIds addObject:contactId];
            }

            completion(contactIds);
        });
    });
}


- (NSString*)contactNameForId:(NSString*)contactId
{
    ABRecordID  recordId = [contactId intValue];
    ABRecordRef contact  = ABAddressBookGetPersonWithRecordID([[NBAddressBookManager sharedManager] getAddressBook], recordId);

    if (contact == NULL)
    {
        return nil;
    }
    else
    {
        return [[NBContact getListRepresentation:contact] string];
    }
}


- (void)addCompanyToAddressBook:(ABAddressBookRef)addressBook
{
    dispatch_async(searchQueue, ^
    {
        @synchronized(self)
        {
            // This method is called as a result of [NBAddressBookManager sharedManager].delegate = self in AppDelegate.m.
            // Just above that, the contacts have been triggered to load. To make sure `findContactsHavingNumber` returns
            // results (which requires contacts to be loaded), we need to call this within a synchronized block; because
            // loading contacts, which was called earlier, is also in a synchronized block.
            [self findContactsHavingNumber:[Settings sharedSettings].companyPhone completion:^(NSArray* contactIds)
            {
                if (contactIds.count > 0)
                {
                    return;
                }

                ABRecordRef person = ABPersonCreate();

                NSString* venueName     = [Settings sharedSettings].companyName;
                NSString* venueUrl      = [Settings sharedSettings].companyWebsite;
                NSString* venueEmail    = [Settings sharedSettings].companyEmail;
                NSString* venuePhone    = [Settings sharedSettings].companyPhone;
                NSString* venueAddress1 = [Settings sharedSettings].companyAddress1;
                NSString* venueAddress2 = [Settings sharedSettings].companyAddress2;
                NSString* venueCity     = [Settings sharedSettings].companyCity;
                NSString* venueState    = nil;
                NSString* venueZip      = [Settings sharedSettings].companyPostcode;
                NSString* venueCountry  = [Settings sharedSettings].companyCountry;
                UIImage*  venueImage    = [UIImage imageNamed:@"Icon-152.png"];

                ABRecordSetValue(person, kABPersonOrganizationProperty, (__bridge CFStringRef)venueName, NULL);

                if (venueUrl)
                {
                    ABMutableMultiValueRef urlMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                    ABMultiValueAddValueAndLabel(urlMultiValue, (__bridge CFStringRef) venueUrl, kABPersonHomePageLabel, NULL);
                    ABRecordSetValue(person, kABPersonURLProperty, urlMultiValue, nil);
                    CFRelease(urlMultiValue);
                }

                if (venueEmail)
                {
                    ABMutableMultiValueRef emailMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                    ABMultiValueAddValueAndLabel(emailMultiValue, (__bridge CFStringRef) venueEmail, kABWorkLabel, NULL);
                    ABRecordSetValue(person, kABPersonEmailProperty, emailMultiValue, nil);
                    CFRelease(emailMultiValue);
                }

                if (venuePhone)
                {
                    ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
                    NSArray*               venuePhoneNumbers     = [venuePhone componentsSeparatedByString:@" or "];

                    for (NSString *venuePhoneNumberString in venuePhoneNumbers)
                    {
                        ABMultiValueAddValueAndLabel(phoneNumberMultiValue, (__bridge CFStringRef) venuePhoneNumberString, kABPersonPhoneMainLabel, NULL);
                    }

                    ABRecordSetValue(person, kABPersonPhoneProperty, phoneNumberMultiValue, nil);
                    CFRelease(phoneNumberMultiValue);
                }

                ABMutableMultiValueRef multiAddress      = ABMultiValueCreateMutable(kABMultiDictionaryPropertyType);
                NSMutableDictionary*   addressDictionary = [[NSMutableDictionary alloc] init];

                if (venueAddress1)
                {
                    if (venueAddress2)
                    {
                        addressDictionary[(NSString *) kABPersonAddressStreetKey] = [NSString stringWithFormat:@"%@\n%@", venueAddress1, venueAddress2];
                    }
                    else
                    {
                        addressDictionary[(NSString *) kABPersonAddressStreetKey] = venueAddress1;
                    }
                }

                if (venueCity)
                {
                    addressDictionary[(NSString *)kABPersonAddressCityKey] = venueCity;
                }

                if (venueState)
                {
                    addressDictionary[(NSString *)kABPersonAddressStateKey] = venueState;
                }

                if (venueZip)
                {
                    addressDictionary[(NSString *)kABPersonAddressZIPKey] = venueZip;
                }

                if (venueCountry)
                {
                    addressDictionary[(NSString *)kABPersonAddressCountryKey] = venueCountry;
                }

                if (venueImage)
                {
                    ABPersonSetImageData(person, (__bridge CFDataRef)UIImagePNGRepresentation(venueImage), nil);
                }

                ABMultiValueAddValueAndLabel(multiAddress, (__bridge CFDictionaryRef) addressDictionary, kABWorkLabel, NULL);
                ABRecordSetValue(person, kABPersonAddressProperty, multiAddress, NULL);
                CFRelease(multiAddress);

                CFErrorRef error = NULL;
                ABAddressBookAddRecord(addressBook, person, &error);
                if (error == NULL)
                {
                    ABAddressBookSave(addressBook, &error);
                }

                CFRelease(person);

                dispatch_async(dispatch_get_main_queue(), ^
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:NF_RELOAD_CONTACTS object:nil];
                });
            }];
        }
    });
}


#pragma mark - Section & alphabet jumping
- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
    //Hide the section titles if there are less than 6 contacts or the filter is enabled
    if (([contactsDatasource count] > 0 && [[contactsDatasource objectAtIndex:section] count] == 0) ||
        !hasEnoughContactsForSectionTitles ||
        filterEnabled)
    {
        return nil;
    }
    else
    {
        return [SECTION_TITLES objectAtIndex:section];
    }
}


- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView
{
    if (hasEnoughContactsForSectionTitles && !filterEnabled)
    {
        return SECTION_TITLES;
    }
    else
    {
        return @[];
    }
}


- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString*)title atIndex:(NSInteger)index
{
    return index;
}


-(void)grayViewTapped
{
    [self.searchDisplayController setActive:NO animated:YES];
}


#pragma mark - Cancel button

- (void)cancelPressed
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
